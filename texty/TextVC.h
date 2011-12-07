#import <Cocoa/Cocoa.h>
#import "m_Storage.h"
#import "m_range.h"
#import "m_parse.h"

@interface TextVC : NSViewController <NSTextStorageDelegate,NSTextViewDelegate> {
	IBOutlet NSTextView *text;
	IBOutlet NSScrollView *scroll;
	m_Storage *s;
	m_parse *parser;
	NSTabViewItem *tabItem;
	BOOL something_changed, need_to_autosave;
	long autosave_ts;
	NSBox *box;
	BOOL locked;
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
- (void) reload;
- (void) lockText;
- (void) label:(int) type;
@property (retain) NSTabViewItem *tabItem;
@property (retain) m_Storage *s;
@property (retain) m_parse *parser;
@property (retain) NSBox *box;
@end
