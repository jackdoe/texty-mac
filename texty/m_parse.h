#import <Foundation/Foundation.h>
#import "colors.h"
#import "STextView.h"
#include <sys/queue.h>
#ifndef _M_PARSE_H
#define _M_PARSE_H
#define HASH_SIZE 8192 
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

#define B_TABLE_SIZE		256
#define B_TABLE_MASK		B_TABLE_SIZE - 1
#define B_ENDS_WITH_NEW_LINE 	1
#define B_COMMENT 				2
#define B_STRING_1 				4
#define B_STRING_2 				8
#define B_SHOW_VAR				16
#define B_NO_VAR				32
#define B_SHOW_KEYWORD			64
#define B_NO_KEYWORD			128
#define B_SUPERBLOCK			256
#define B_REQUIRE_SUPERBLOCK	512
#define BLOCK_BEGINS 	1
#define BLOCK_ENDS 		2
#define MIN_WORD_LEN	1

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
	struct block *fallback;
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
struct var_symbol {
	char color;
	char required_len;
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
static inline int block_cond(struct block *b, char cmask, char pmask,int type,NSInteger pos);
static inline void word_begin(struct word *w, NSInteger pos);
static inline void word_end(struct word *w);
static inline int word_append(struct word *w, unichar c, NSInteger pos,char current_block_flags,struct var_symbol *var_symbol_table);
static inline int word_is_valid_word(struct word *w);
static inline void word_dump(struct word *w);
static struct word * word_new(struct word_head *wh);
NSDictionary *colorAttr[20];
#endif
@class STextView;
@interface m_parse : NSObject{
	struct var_symbol _syntax_var_symbol[B_TABLE_SIZE];
	char 	_syntax_color_numbers;
	char 	_syntax_color;
	struct syntax_blocks _syntax_blocks;
	struct _hash_table hash[HASH_SIZE];
}
- (void) initSyntax:(NSString *) ext box:(NSBox *) box;
- (NSArray *) hash_to_array:(NSString *) part;
- (void) parse:(STextView *) tv;
@end
