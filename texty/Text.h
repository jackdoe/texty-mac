#import <Foundation/Foundation.h>
#import "m_Storage.h"
#import "m_range.h"
#ifndef TEXT_H
#define TEXT_H
#include <sys/queue.h>
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
#define RGB(r, g, b) [NSColor colorWithSRGBRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]
#define AUTOSAVE_INTERVAL 60 /* in seconds */
#define B_COMMENT 1
#define B_STRING_1 2
#define B_STRING_2 3
#define B_FORCE 4

#define HASH_SIZE 1024
#define HASH_MASK HASH_SIZE - 1
#define WORD_SIZE 32
#define WORD_MASK WORD_SIZE - 1
#define WORD_ALPHA_LOWER 	1
#define WORD_ALPHA_UPPER 	2
#define WORD_NUMBER			4
#define WORD_OTHER			8
#define WORD_DASH			16
#define WORD_VARSYMBOL		32
struct block {
	NSRange range;
	char started;
	char type;
	int color;
	unichar expect;
};

struct word {
	unichar data[WORD_SIZE];
	NSInteger len;
	unsigned int flags;
	NSInteger pos;
	char started;
};

struct _hash_table {
        char count;
        SLIST_HEAD(,_hash_entry) head;
};
struct _hash_entry {
        char data[WORD_SIZE];
        char len;
        char color;
        SLIST_ENTRY(_hash_entry) list;  
};

static void hash_init(struct _hash_table *t);
static unsigned long hash_get_bucket(unichar *word);
static struct _hash_entry *hash_lookup(struct _hash_table *t,struct word *w);
static struct _hash_entry *hash_insert(struct _hash_table *t,struct word *w);
static inline void block_begin(struct block *b, NSInteger pos, int type, int color);
static inline int block_end(struct block *b,int type);
static inline void word_begin(struct word *w, NSInteger pos);
static inline int word_end(struct word *w);
static inline int word_append(struct word *w, unichar c, NSInteger pos);
static inline int word_is_valid_word(struct word *w);
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
	NSDictionary *colorAttr[20];
	NSColor *colorSet[20];
	unichar syntax_var_symbol;
	struct _hash_table hash[HASH_SIZE];
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
- (void) highlight:(NSRange) range;
- (void) string:(NSString *) source toWordStruct:(struct word *) w;
- (void) addKeywords:(NSString *) words withColor:(int) color;

@property (strong,retain) NSTabViewItem *tabItem;
@property (retain) NSTextView *tv;
@property (retain) NSScrollView *sv;
@property (retain) NSBox *box;
@property (retain) m_Storage *s;
@property (atomic,assign) BOOL something_changed,need_to_autosave;
@property (assign) unsigned long autosave_ts;
@property (retain) NSLock *serializator;
@property (assign) unichar syntax_var_symbol;
@end
