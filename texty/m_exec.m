#import "m_exec.h"
@implementation m_exec
@synthesize delegate = _delegate,task,_rc,_command,_terminated;
- (void) sendTitle:(NSString *) s {
	if ([self.delegate respondsToSelector:@selector(taskAddExecuteTitle:)]) 
		[self.delegate taskAddExecuteTitle:s];
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
		[self readWhatIsLeft:fh];
		/* this is not cool, but there are so many races with didterminate notification and read in background notification */
		if ([fh isEqual:[[task standardOutput] fileHandleForReading]]) {
			NSString *timedOut = @"";
			if (_terminated) {
				timedOut = @" [TOUT]";
			} 
			[self sendString:[NSString stringWithFormat:@"\n[%@] END TASK(RC: %d%@): %@\n",[NSDate date],[task terminationStatus],timedOut,_command]];
			if ([self.delegate respondsToSelector:@selector(taskDidTerminate)])
				[self.delegate taskDidTerminate];
		}
	}
}

- (BOOL) diff:(NSURL *) a against:(NSURL *) b {
	return [self execute:[NSString stringWithFormat:@"diff -rupN %@ %@",[a path],[b path]] withTimeout:1];
}

- (BOOL) execute:(NSString *) command withTimeout:(int)timeout {
	if ([task isRunning]) 
		return NO;
	
	self.task = [[NSTask alloc] init];
	self._command = [command copy];
	self._rc = 0;

	[task setLaunchPath: @"/bin/sh"];
	NSArray *arguments = [NSArray arrayWithObjects: @"-c", command,nil];		
	[task setArguments: arguments];
	NSPipe *pipe[3];
	pipe[0] = [NSPipe pipe];
	pipe[1] = [NSPipe pipe];
	pipe[2] = [NSPipe pipe];
	[task setStandardInput: pipe[0]];
	[task setStandardOutput: pipe[1]];
	[task setStandardError: pipe[2]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(readPipe:) name:NSFileHandleReadCompletionNotification object:[[task standardOutput] fileHandleForReading] ];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(readPipe:) name:NSFileHandleReadCompletionNotification object:[[task standardError] fileHandleForReading] ];
	
	[[[task standardOutput] fileHandleForReading] readInBackgroundAndNotify];
	[[[task standardError] fileHandleForReading] readInBackgroundAndNotify];
	[self sendTitle:command];
	[self sendString:[NSString stringWithFormat:@"\n[%@] START TASK(timeout: %@): %@\n",[NSDate date],(timeout == 0 ? @"NOTIMEOUT" : [NSString stringWithFormat:@"%d",timeout]),command]];
	[task launch];

	if (timeout > 0) {
		dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		dispatch_async(queue, ^{
			sleep(timeout);
			if (self.task && [self.task isRunning]) {
				self._terminated = YES;
				[self.task terminate];
			}
		});
	}
	return YES;
}
@end
