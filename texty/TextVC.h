#import <Cocoa/Cocoa.h>
#import "m_Storage.h"
#import "m_parse.h"
#import "ExecuteWC.h"
#import "Preferences.h"
#import "STextView.h"
@interface TextVC : NSViewController <m_StorageDelegate,NSTextViewDelegate> {
	STextView *text;
	NSScrollView *scroll;
	m_Storage *s;
	m_parse *parser;
	ExecuteWC *ewc;
	NSTabViewItem *tabItem;
	BOOL something_changed, need_to_autosave;
	long autosave_ts;
	BOOL locked;
}
- (BOOL) open:(NSURL *)file;
- (BOOL) saveAs:(NSURL *) to;
- (BOOL) save;
- (BOOL) is_modified;
- (void) signal;
- (void) revertToSaved;
- (void) goto_line:(NSInteger) want_line;
- (void) reload;
- (void) close;
- (void) lockText;
- (void) label:(int) type;
+ (void) scrollEnd:(NSTextView *) tv;
- (BOOL) extIs:(NSArray *) ext;
- (id) initWithFrame:(NSRect) frame;
- (void) run_self;
- (void) run_diff_against:(NSURL *) b;
- (void) run: (NSString *) cmd withTimeout:(int) timeout;
- (void) changed_under_my_nose:(NSURL *) file;
@property (retain) ExecuteWC *ewc;
@property (retain) NSTabViewItem *tabItem;
@property (retain) m_Storage *s;
@property (retain) m_parse *parser;
@property (retain) STextView *text;
@property (retain) NSScrollView *scroll;
@end
