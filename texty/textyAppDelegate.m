//
//  textyAppDelegate.m
//  texty7
//
//  Created by jack on 11/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "textyAppDelegate.h"

@implementation textyAppDelegate

@synthesize window = _window;
@synthesize tab;
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[[NSApplication sharedApplication] setPresentationOptions:NSFullScreenWindowMask];
	[self.window setCollectionBehavior: NSWindowCollectionBehaviorFullScreenPrimary];
	[self.window becomeFirstResponder];
	self.window.title = @"texty";
	[self.window setContentView:self.tab.tabView];
	self.window.delegate = self;
}
- (void) application:(NSApplication *)sender openFiles:(NSArray *)filenames {
	for (NSString *file in filenames) {
		NSURL *fileURL = [NSURL fileURLWithPath:file];
		[self.tab open:fileURL];
	}
}
- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
	NSURL *fileURL = [NSURL fileURLWithPath:filename];
	[self.tab open:fileURL];
	return TRUE;
}
- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return YES;
}
- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *)sender {
	return [self.tab gonna_terminate];
}
- (BOOL) windowShouldClose:(id)sender {
	return [self.tab gonna_terminate];
}
@end
