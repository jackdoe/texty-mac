#import <Foundation/Foundation.h>
#define TEXTY_DIR @"~/TEXTY_DATA"
#define DEFAULT_COMMAND @"http://localhost:3000/"
#define AUTOSAVE_INTERVAL @"60" 
#define TERMINATE_ON_CLOSE @"YES"

@interface Preferences : NSObject
+ (NSString *) defaultDir;
+ (NSString *) defaultCommand;
+ (BOOL) terminateOnClose;
+ (void) initialValues;
+ (int) defaultAutoSaveInterval;
@end
