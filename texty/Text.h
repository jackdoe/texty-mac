#import <Foundation/Foundation.h>
#import "m_Storage.h"
#import "m_range.h"
#ifndef TEXT_H
#define TEXT_H
#include <sys/queue.h>

#define DEFAULT_EXECUTE_TIMEOUT 1
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
#define STRING1_COLOR RGB(0xaa,0x96,0x50)
#define STRING1_COLOR_IDX 4
#define STRING2_COLOR RGB(0xEC,0x76,0x00)
#define STRING2_COLOR_IDX 5
#define PREPROCESS_COLOR RGB(0xa8,0xa2,0x97)
#define PREPROCESS_COLOR_IDX 6
#define COMMENT_COLOR RGB(0x7D,0x8C,0x93)
#define COMMENT_COLOR_IDX 7
#define TEXT_COLOR_IDX 8
#define CONSTANT_COLOR RGB(0xA0,0x82,0xBD)
#define CONSTANT_COLOR_IDX 9

#define EXECUTE_COMMAND @"TEXTY_RUN_SHELL"
#define RGB(r, g, b) [NSColor colorWithSRGBRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]
#define AUTOSAVE_INTERVAL 60 /* in seconds */

#define HASH_SIZE 4096
#define HASH_MASK HASH_SIZE - 1
#define WORD_SIZE 64
#define WORD_MASK WORD_SIZE - 1
#define WORD_INVALID 		0
#define WORD_ALPHA_LOWER 	1
#define WORD_ALPHA_UPPER 	2
#define WORD_NUMBER			4
#define WORD_OTHER			8
#define WORD_DASH			16
#define WORD_VARSYMBOL		32
#define WORD_ENDED			64
#define WORD_CONTINUE		128
#define WORD_SHARP			256
#define B_TABLE_MASK		255
#define B_TABLE_SIZE		256
#define B_ENDS_WITH_NEW_LINE 1
#define B_COMMENT 		2
#define B_STRING_1 		4
#define B_STRING_2 		8
struct block {
	NSRange range;
	char started;
	char type;
	int color;
	unichar char_begin;
	unichar char_begin_prev;
	unichar char_end;
	unichar char_end_prev;
	unichar char_escape;
	unsigned int flags;
};
struct syntax_blocks {
	struct block b[B_TABLE_SIZE];
};


struct word {
	unichar data[WORD_SIZE];
	NSInteger len;
	NSInteger pos;
	unsigned int flags;
	char current_block_flags;
	char started;
	char color;
	struct word *next;
};
struct word_head {
	struct word *head;
	struct word *tail;
};
struct _hash_table {
        char count;
        SLIST_HEAD(,_hash_entry) head;
};
struct _hash_entry {
		struct word w;
        SLIST_ENTRY(_hash_entry) list;  
};

#define Q_APPEND(_q,_m)                         \
do {                                            \
        if (_q->head == NULL)                   \
                _q->head = _m;                  \
        else                                    \
                _q->tail->next = _m;            \
        _q->tail = _m;                          \
        _m->next = NULL;                        \
} while (0);




static void hash_init(struct _hash_table *t);
static unsigned long hash_get_bucket(unichar *word);
static struct _hash_entry *hash_lookup(struct _hash_table *t,struct word *w);
static struct _hash_entry *hash_insert(struct _hash_table *t,struct word *w);
static inline void block_begin(struct block *b, NSInteger pos);
static inline int block_cond(struct block *b, char cmask, char pmask,int type);
static inline void word_begin(struct word *w, NSInteger pos);
static inline void word_end(struct word *w);
static inline int word_append(struct word *w, unichar c, NSInteger pos,char current_block_flags);
static inline int word_is_valid_word(struct word *w);
static inline void word_dump(struct word *w);
static struct word * word_new(struct word_head *wh);
#endif

@interface Text : NSObject <NSTextStorageDelegate,NSTextViewDelegate>{
	NSTabViewItem *tabItem;
	NSTextView *tv;
	NSScrollView *sv;
	NSBox *box;
	m_Storage *s;
	BOOL something_changed,need_to_autosave;
	unsigned long autosave_ts;
	NSLock *serializator;
	NSDictionary *colorAttr[20];
	unichar _syntax_var_symbol;
	char 	_syntax_color_numbers;
	char 	_syntax_color;
	struct syntax_blocks _syntax_blocks;
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
- (void) colorBracket;
- (void) string:(NSString *) source toWordStruct:(struct word *) w;
- (void) addKeywords:(NSString *) words withColor:(int) color;
- (void) colorPrev:(unichar) opens ends:(unichar) ends inRange:(NSRange) range inString:(NSString *) string;

@property (retain) NSTabViewItem *tabItem;
@property (retain) NSTextView *tv;
@property (retain) NSScrollView *sv;
@property (retain) NSBox *box;
@property (retain) NSLock *serializator;
@property (retain) m_Storage *s;
@property (atomic,assign) BOOL something_changed,need_to_autosave;
@property (assign) unsigned long autosave_ts;
@end
