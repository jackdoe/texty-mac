#import "m_exec.h"
#import "PseudoTTY.h"
@implementation m_exec
@synthesize delegate = _delegate,task,_rc,_command,_terminated,_startTime,_timeout,pty,serial;
- (m_exec *) init {
	self = [super init];
	if (self) {
		self.serial = [[NSLock alloc] init];
	}
	return self;
}
- (void) sendString:(NSString *) s {
	if ([self.delegate respondsToSelector:@selector(taskAddExecuteText:)]) 
		[self.delegate taskAddExecuteText:s];
	
}
- (void) send:(NSData *) data {
	NSString *dataValue = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
	[self sendString:dataValue];
}
- (void) readWhatIsLeft:(NSFileHandle *)fh {
	NSData *data;
	while ((data = [fh availableData]) && [data length]) {
		[self send:data];	
	}
}
- (void)readPipe:(NSNotification *)notification {
	NSFileHandle *fh = [notification object];
	NSData *data;
	data = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
	if ([data length]){
		[self send:data];
		[fh readInBackgroundAndNotify];
	} else {
		[self sendTerminate];
	}
}

- (BOOL) diff:(NSURL *) a against:(NSURL *) b {
	return [self execute:[NSString stringWithFormat:@"diff -rupN %@ %@",[a path],[b path]] withTimeout:0];
}
- (void) sendStart {
	if ([self.delegate respondsToSelector:@selector(taskDidStart)])
		[self.delegate taskDidStart];
}
- (void) sendTerminate {
	if ([self.delegate respondsToSelector:@selector(taskDidTerminate)])
		[self.delegate taskDidTerminate];

}
- (void) terminate {
	[task terminate];
	[task waitUntilExit];
	if (![task isRunning])
		_rc = [task terminationStatus];
}
- (void) restart {
	[self terminate];
	[self execute:_command withTimeout:_timeout];
}
- (void) timeoutWatcher {
	if (_timeout > 0) {
		dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		dispatch_async(queue, ^{
			sleep(_timeout);
			if (self.task && [self.task isRunning]) {
				self._terminated = YES;
				[self.task terminate];
			}
		});
	}
}

- (void) run {
	[task setLaunchPath: @"/bin/sh"];
	NSArray *arguments = [NSArray arrayWithObjects: @"-c", _command,nil];
	[task setArguments: arguments];
    [task setCurrentDirectoryPath:[@"~" stringByExpandingTildeInPath]];
	[task setStandardInput: pty.slave];
	[task setStandardOutput: pty.slave];
	[task setStandardError: [task standardOutput]];
    NSMutableDictionary *environment = [[NSMutableDictionary alloc] initWithDictionary:[[NSProcessInfo processInfo] environment]];
	[environment setValue:@"xterm" forKey:@"TERM"];
	[task setEnvironment:[NSDictionary dictionaryWithDictionary:environment]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(readPipe:) name:NSFileHandleReadCompletionNotification object:pty.master];
    [pty.master readInBackgroundAndNotify];
	[task launch];	
	[self timeoutWatcher];
}


- (BOOL) execute:(NSString *) command withTimeout:(int)timeout {
	if ([self.task isRunning])
		return NO;
	self.pty = [[PseudoTTY alloc] init];
	if (self.pty == nil) 
		return NO;
	
	self.task = [[NSTask alloc] init];
	self._command = [command copy];
	self._rc = 0;
	self._timeout = timeout;
	self._startTime = [NSDate date];
	[self sendStart];
	[self run];
	return YES;
}
- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void) write:(NSString *)value {	
	if ([task isRunning]) 
		[pty.master writeData:[value dataUsingEncoding:NSUTF8StringEncoding]];
	
}
@end
