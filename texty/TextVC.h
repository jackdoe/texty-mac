#import <Cocoa/Cocoa.h>
#import "m_Storage.h"
#import "m_range.h"
#import "m_parse.h"
#import "ExecuteWC.h"
#import "Preferences.h"
@interface TextVC : NSViewController <NSTextStorageDelegate,NSTextViewDelegate> {
	NSTextView *text;
	NSScrollView *scroll;
	m_Storage *s;
	m_parse *parser;
	ExecuteWC *ewc;
	NSTabViewItem *tabItem;
	BOOL something_changed, need_to_autosave;
	long autosave_ts;
	NSBox *box;
	BOOL locked;
	BOOL bracketColored;
}
- (BOOL) open:(NSURL *)file;
- (BOOL) saveAs:(NSURL *) to;
- (BOOL) save;
- (BOOL) is_modified;
- (void) signal;
- (void) revertToSaved;
- (void) goto_line:(NSInteger) want_line;
- (NSInteger) strlen;
- (NSString *) get_line:(NSInteger) lineno;
- (NSString *) get_execute_command;
- (void) insert:(NSString *) value atLine:(NSInteger) line;
- (void) reload;
- (void) close;
- (void) lockText;
- (void) label:(int) type;
+ (void) scrollEnd:(NSTextView *) tv;
- (void) insert:(NSString *) value atEachLineOfSelectionWithDirection:(NSInteger) direction;
- (BOOL) extIs:(NSArray *) ext;
- (BOOL) eachLineOfSelectionBeginsWith:(NSString *) symbol;
- (BOOL) eachLineInRange:(NSRange) range beginsWith:(NSString *) symbol;
- (BOOL) colorBracket;
- (id) initWithFrame:(NSRect) frame;
- (void) run_self;
- (void) run_diff_against:(NSURL *) b;
- (void) run: (NSString *) cmd withTimeout:(int) timeout;
@property (retain) ExecuteWC *ewc;
@property (retain) NSTabViewItem *tabItem;
@property (retain) m_Storage *s;
@property (retain) m_parse *parser;
@property (retain) NSBox *box;
@property (retain) NSTextView *text;
@property (retain) NSScrollView *scroll;
@end
