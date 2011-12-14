#import <Cocoa/Cocoa.h>
#import "m_exec.h"
#define TAG_INPUT 	0
#define TAG_STOP 	1
#define TAG_CLEAR 	2
#define TAG_RELOAD 	3

@interface ExecuteWC : NSWindowController <NSWindowDelegate,m_execDelegate>{
	m_exec *e;
	IBOutlet NSTextView *output;
	IBOutlet NSTextField *input;
	NSRange lastColorRange;
}
@property (retain) m_exec *e;
- (void) execute:(NSString *) command withTimeout:(int)timeout;
- (IBAction)action:(id)sender;
- (void) fixModalTextView;
@end
