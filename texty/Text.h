#import <Foundation/Foundation.h>
#import "m_Storage.h"
#import "m_range.h"
#ifndef TEXT_H
#define TEXT_H
#define FONT [NSFont fontWithName:@"Monaco" size:12]
#define LINE_80_COLOR RGB(150, 150, 150) 
#define TEXT_COLOR RGB(0xE0,0xE2,0xE4)
#define BG_COLOR RGB(0x29,0x31,0x34)
#define CURSOR_COLOR RGB(255,255,255)


#define CONDITION_COLOR RGB(0xFF,0x8B,0xFF)
#define CONDITION_COLOR_IDX 0
#define KEYWORD_COLOR RGB(0x93,0xC7,0x63)
#define KEYWORD_COLOR_IDX 1
#define VARTYPE_COLOR RGB(0x77,0x9C,0xC1)
#define VARTYPE_COLOR_IDX 2
#define VALUE_COLOR RGB(0xFF,0xCD,0x22)
#define VALUE_COLOR_IDX 3
#define STRING1_COLOR RGB(0xEC,0x76,0x00)
#define STRING1_COLOR_IDX 4
#define STRING2_COLOR RGB(255,58,90)
#define STRING2_COLOR_IDX 5
#define PREPROCESS_COLOR RGB(134,140,133)
#define PREPROCESS_COLOR_IDX 6
#define COMMENT_COLOR RGB(0x7D,0x8C,0x93)
#define COMMENT_COLOR_IDX 7
#define TEXT_COLOR_IDX 8
#define EXECUTE_COMMAND @"TEXTY_RUN_SHELL"
#define SYNTAX_TYPE_REGEXP 1
#define SYNTAX_TYPE_DICT 2
#define RGB(r, g, b) [NSColor colorWithSRGBRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]

#define AUTOSAVE_INTERVAL 60 /* in seconds */
#endif

@interface Text : NSObject <NSTextStorageDelegate>{
	NSTabViewItem *tabItem;
	NSTextView *tv;
	NSScrollView *sv;
	NSBox *box;
	m_Storage *s;
	BOOL something_changed,need_to_autosave;
	unsigned long autosave_ts;
	NSLock *serializator;
	NSMutableArray *patterns;
	NSDictionary *colorAttr[20];
	NSColor *colorSet[20];
}
- (Text *) initWithFrame:(NSRect) frame;
- (BOOL) open:(NSURL *) file;
- (void) revertToSaved;
- (void) saveAs:(NSURL *) to;
- (void) save;
- (BOOL) is_modified;
- (void) goto_line:(NSInteger) want_line;
- (NSString *) get_line:(NSInteger) lineno;
- (void) responder;
- (void) parse:(m_range *) m_range;
- (void) signal;
- (void) resign;
- (NSString *) get_execute_command;
- (void) initSyntax;
- (void) addSyntax:(NSString *) pattern withColor:(NSInteger) color andType:(int) type;
@property (strong,retain) NSTabViewItem *tabItem;
@property (retain) NSTextView *tv;
@property (retain) NSScrollView *sv;
@property (retain) NSBox *box;
@property (retain) m_Storage *s;
@property (atomic,assign) BOOL something_changed,need_to_autosave;
@property (assign) unsigned long autosave_ts;
@property (retain) NSLock *serializator;
@property (retain) NSMutableArray *patterns;
@end
