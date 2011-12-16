#import "Preferences.h"

@implementation Preferences
+ (NSString *) defaultDir {
	NSString *s = TEXTY_DIR;
	return [s stringByExpandingTildeInPath];
}
+ (int) defaultAutoSaveInterval {
	NSUserDefaults *p = [NSUserDefaults standardUserDefaults];
	NSString *d = [p objectForKey:@"PAutoSaveInterval"];
	if (!d || [d intValue] <= 0) {
		[p setValue:AUTOSAVE_INTERVAL forKey:@"PAutoSaveInterval"];
		d = AUTOSAVE_INTERVAL;
	}
	return abs([d intValue]);
}
+ (NSString *) defaultCommand {
	NSUserDefaults *p = [NSUserDefaults standardUserDefaults];
	NSString *d = [p objectForKey:@"PDefaultCommand"];
	if (!d || [d rangeOfString:@"^http(s)?://" options:NSRegularExpressionSearch].location == NSNotFound) {
		[p setValue:DEFAULT_COMMAND forKey:@"PDefaultCommand"];
		return DEFAULT_COMMAND;
	}
	return d;
}
+ (BOOL) terminateOnClose {
	NSUserDefaults *p = [NSUserDefaults standardUserDefaults];
	NSString *d = [p objectForKey:@"PTerminateOnClose"];
	if (!d) {
		[p setValue:TERMINATE_ON_CLOSE forKey:@"PTerminateOnClose"];
		d = TERMINATE_ON_CLOSE;
	}
	return [d boolValue];	
}
+ (void) initialValues {
	[Preferences defaultDir];
	[Preferences defaultAutoSaveInterval];
	[Preferences defaultCommand];
}
@end
