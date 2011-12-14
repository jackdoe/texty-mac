#import "m_exec.h"
#import "PseudoTTY.h"
#include <signal.h>
@implementation m_exec
@synthesize delegate = _delegate,task,_rc,_command,_terminated,_startTime,_timeout,pty,serial;
- (m_exec *) init {
	self = [super init];
	if (self) {
		self.serial = [[NSLock alloc] init];
	}
	return self;
}

- (void) send:(NSData *) data {
	NSString *dataValue = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
	[self.delegate taskAddExecuteText:dataValue];
}
- (void) sendSignal:(int)signal {
	[serial lock];
	if ([task isRunning]) {
		kill([task processIdentifier], signal);
	}
	[serial unlock];
}
- (void)readPipe:(NSNotification *)notification {
	NSFileHandle *fh = [notification object];
	NSData *data;
	data = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
	if ([data length]){
		[self send:data];
		[fh readInBackgroundAndNotify];
	} else {
		[self.delegate taskDidTerminate];
	}
}

+ (NSString *) diff:(NSURL *) a against:(NSURL *) b {
	return [NSString stringWithFormat:@"diff -rupN %@ %@",[a path],[b path]];
}
- (void) terminate {
	[serial lock];
	if ([task isRunning]) {
		[task terminate];
		[task waitUntilExit];
	}
	if (![task isRunning])
		_rc = [task terminationStatus];
	[serial unlock];
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
			[self.serial lock];
			if (self.task && [self.task isRunning]) {
				self._terminated = YES;
				[self.task terminate];
			}
			[self.serial unlock];
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
	[serial lock];
	if ([self.task isRunning] || (self.pty = [[PseudoTTY alloc] init]) == nil) {
		[serial unlock];
		return NO;
	}	
	self.task = [[NSTask alloc] init];
	self._command = [command copy];
	self._rc = 0;
	self._timeout = timeout;
	self._startTime = [NSDate date];
	[self.delegate taskDidStart];
	[self run];
	[serial unlock];
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
