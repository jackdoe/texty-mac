#import "PrefWC.h"

@implementation PrefWC

#define HOST @"http://localhost"
#define PORT @"80"
+ (NSString *) getDefaultCommand {
	NSUserDefaults *p = [NSUserDefaults standardUserDefaults];
	NSString *port = [p stringForKey:@"DefaultPort"];
	if (!port) {
		port = PORT;
	}
	return [NSString stringWithFormat:@"%@:%d/",HOST,[port intValue]];
	
}
- (id) init {
    self = [super initWithWindowNibName:@"PreferencesWindow"];
	return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	NSUserDefaults *p = [NSUserDefaults standardUserDefaults];
	NSString *cmd = [p stringForKey:@"DefaultPort"];
	if (!cmd) {
		cmd = PORT;
	}

 	[defaultCommand setStringValue:cmd];   
//	[defaultDirectory setStringValue:dir];
}
#define TAG_CMD 0
#define TAG_DIR 1
- (IBAction)action:(id)sender {
	NSUserDefaults *p = [NSUserDefaults standardUserDefaults];
	switch([sender tag]) {
	case TAG_CMD:
		[p setObject:[sender stringValue] forKey:@"DefaultPort"];
	break;
//	case TAG_DIR:
//		[p setObject:[sender stringValue] forKey:@"DefaultDirectory"];
//	break;
	}
}
@end
