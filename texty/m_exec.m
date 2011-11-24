//
//  m_exec.m
//  texty7
//
//  Created by jack on 11/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "m_exec.h"
#define MAX_TIMEOUT 1
@implementation m_exec
+ (NSString *) execute:(NSString *) command {
	NSTask *task = [[NSTask alloc] init];
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	__block BOOL terminated = NO;
	dispatch_async(queue, ^{
		sleep(MAX_TIMEOUT);
		if (task && [task isRunning]) {
			terminated = YES;
			[task terminate];
		}
	});
	[task setLaunchPath: @"/bin/sh"];
	NSArray *arguments = [NSArray arrayWithObjects: @"-c", command,nil];		
	[task setArguments: arguments];
	NSPipe *pipe[2];
	pipe[0] = [NSPipe pipe];
	pipe[1] = [NSPipe pipe];
	[task setStandardInput: pipe[0]];
	[task setStandardOutput: pipe[1]];
	NSFileHandle *file = [pipe[1] fileHandleForReading];
	[task launch];
	NSData *data = [file readDataToEndOfFile];
	NSString *output = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
	if (terminated)
		NSRunAlertPanel(@"Execute timeout reached.", [NSString stringWithFormat:@"terminating task after: %d second timeout",MAX_TIMEOUT] , @"Close", nil,nil);

	return output;
}
@end
