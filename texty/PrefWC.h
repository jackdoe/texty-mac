#import <Cocoa/Cocoa.h>

@interface PrefWC : NSWindowController {
	IBOutlet NSTextField *defaultCommand;
	IBOutlet NSTextField *defaultDirectory;
}
+ (NSString *) getDefaultCommand;
@end
