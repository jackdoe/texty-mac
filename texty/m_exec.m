#import "m_exec.h"
@implementation m_exec
+ (NSString *) execute:(NSString *) command withTimeout:(int)timeout saveRC:(int *) rc{
	__block BOOL terminated = NO;
	NSTask *task = [[NSTask alloc] init];
	if (timeout > 0) {
		dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		dispatch_async(queue, ^{
			sleep(timeout);
			if (task && [task isRunning]) {
				terminated = YES;
				[task terminate];
			}
		});
	}
	[task setLaunchPath: @"/bin/sh"];
	NSArray *arguments = [NSArray arrayWithObjects: @"-c", command,nil];		
	[task setArguments: arguments];
	NSPipe *pipe[3];
	pipe[0] = [NSPipe pipe];
	pipe[1] = [NSPipe pipe];
	pipe[2] = [NSPipe pipe];
	[task setStandardInput: pipe[0]];
	[task setStandardOutput: pipe[1]];
	[task setStandardError:pipe[2]];
	NSFileHandle *file = [pipe[1] fileHandleForReading];
	NSFileHandle *err = [pipe[2] fileHandleForReading];
	[task launch];
	[task waitUntilExit];
	if (rc)
		*rc = [task terminationStatus];
	
	NSData *data = [file readDataToEndOfFile];
	NSData *errData = [err readDataToEndOfFile];
	NSString *output = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
	NSString *errOutput = [[NSString alloc] initWithData: errData encoding: NSUTF8StringEncoding];
	if (terminated)
		NSRunAlertPanel(@"Execute timeout reached.", [NSString stringWithFormat:@"terminating task after: %d second timeout",timeout] , @"Close", nil,nil);

	if ([errData length] > 0) {
		output = [output stringByAppendingFormat:@"\n**********[STDERR]**********\n%@",errOutput]; 
	}
	return output;
}
@end
