#import "m_parse.h"

@implementation m_parse
@synthesize autoindent;
static void hash_init(struct _hash_table *t) {
	for (int i=0;i<HASH_SIZE;i++) {
		if (!SLIST_EMPTY(&t[i].head)) {
			struct _hash_entry *e;
			while (!SLIST_EMPTY(&t[i].head)) {
				 e = SLIST_FIRST(&t[i].head);
				 SLIST_REMOVE_HEAD(&t[i].head, list);
				 free(e);
			}
		}
		SLIST_INIT(&t[i].head);
		t[i].count = 0;
	}
}
- (NSArray *) hash_to_array:(NSString *) part {
	NSMutableArray *ret = [NSMutableArray array];
	for (int i=0;i<HASH_SIZE;i++) {
		if (!SLIST_EMPTY(&hash[i].head)) {
			struct _hash_entry *e;
			SLIST_FOREACH(e, &hash[i].head, list) {
				NSString *word = [NSString stringWithCharacters:e->w.data length:e->w.len];
				NSRange range = [word rangeOfString:part];
				if (range.location == 0) {
					[ret addObject:[word copy]];
				}
			}
		}
	}
	return [NSArray arrayWithArray:ret];
}
static unsigned long hash_get_bucket(unichar *word) {
        /* from gawk */
        unsigned long hash = 0;
        register unichar c;

        while ((c = *word++) != '\0')
                hash = c + (hash << 6) + (hash << 16) - hash;
        return hash & HASH_MASK;
}

static struct _hash_entry *hash_lookup(struct _hash_table *t,struct word *w) {
	unsigned long k = hash_get_bucket(w->data);
	if (t[k].count == 0)
		return NULL;
	struct _hash_entry *e;
	SLIST_FOREACH(e, &t[k].head, list) {
		if (e->w.len == w->len && bcmp(e->w.data,w->data,e->w.len) == 0) {
			return e;
		}
	}
	return NULL;
}
static struct _hash_entry *hash_insert(struct _hash_table *t,struct word *w) {
	struct _hash_entry *e;
	if ((e = hash_lookup(t,w)))
		return e;
	e = malloc(sizeof(*e));
	if (!e) {
		NSLog(@"no mem for hash entry");
		return NULL;
	}
	bzero(e,sizeof(*e));
	bcopy(w,&e->w,sizeof(*w));
	unsigned long k = hash_get_bucket(w->data);
	t[k].count++;
	SLIST_INSERT_HEAD(&t[k].head, e, list);
	return e;
}

static inline void block_begin(struct block *b, NSInteger pos) {
	b->range = NSMakeRange(pos, 0);
	b->started = 1;
}
static inline int block_cond(struct block *b, char cmask, char pmask,int type,NSInteger pos) {
	if (pmask == '\\') 
		return 0;
		
	if (type == BLOCK_BEGINS) {
		if (b->char_begin == cmask && (b->char_begin_prev == 0 || b->char_begin_prev == pmask)) {
			block_begin(b, pos);
			if (b->char_begin_prev) 
				b->range.location--;
			b->range.length++;
			return 1;
		}
	} else {
		if (((cmask == '\n' || cmask == '\r') && (b->flags & B_ENDS_WITH_NEW_LINE)) 
			|| (b->char_end == cmask && (b->char_end_prev == 0 || b->char_end_prev == pmask))) {
			
			if (b->char_end_prev) 
				b->range.length++;
			return 1;
		}
	}
	return 0;
}
-(BOOL) block_color:(struct block *)b superBlock:(struct block *)superblock {
	if (b->flags & B_SUPERBLOCK)
		return NO;
	if ((b->flags & B_REQUIRE_SUPERBLOCK)) {
		if (superblock) 
			return YES;
	} else {
		return YES;
	}
	return NO;
}
static inline void word_begin(struct word *w, NSInteger pos) {
	w->pos = pos;
	w->started = 1;
	w->flags = 0;
	w->data[0] = '\0';
	w->len = 0;
}
static inline void word_dump(struct word *w) {
	NSLog(@"word pos,len:%ld,%ld data: '%@'",w->pos,w->len,[NSString stringWithCharacters:w->data length:w->len]);
}
static inline void word_end(struct word *w) {
	w->started = 0;
	w->data[w->len & WORD_MASK] = '\0';
}
static inline int word_is_valid_word(struct word *w) {
	return (w->len >= MIN_WORD_LEN && (w->flags & (WORD_NUMBER|WORD_ALPHA_LOWER|WORD_ALPHA_UPPER|WORD_DASH|WORD_VARSYMBOL)) == w->flags);
}
static inline int word_valid_symbol(unichar c, struct var_symbol *var_symbol_table) {
	if (c >= 'a' && c <= 'z')
		return WORD_ALPHA_LOWER;
	else if (c >= '0' && c <= '9') 
		return WORD_NUMBER;
	else if (c >= 'A' && c <= 'Z') 
		return  WORD_ALPHA_UPPER;
	else if (c == '_')
		return WORD_DASH;
	else if (c < B_TABLE_SIZE && var_symbol_table[c].color) 
		return WORD_VARSYMBOL;
	else 
		return WORD_INVALID;
}
static inline int word_append(struct word *w, unichar c, NSInteger pos,char current_block_flags, struct var_symbol *var_symbol_table) {
	if (!w) {
		/* no mem */
		return 0;
	}
	int flags = word_valid_symbol(c,var_symbol_table);
	if (flags == WORD_INVALID) {
		if (w->started) {
			word_end(w);	
			return WORD_ENDED;
		} else {
			return WORD_CONTINUE;
		}
		flags = 0;
	}
	if (!w->started)
		word_begin(w,pos);

	w->current_block_flags = current_block_flags;
	w->flags |= flags;
	w->data[w->len++ & WORD_MASK] = c;
	return WORD_CONTINUE;
}

static struct word * word_new(struct word_head *wh) {
	struct word *w;
	w = malloc(sizeof(*w));
	if (w) {
		bzero(w,sizeof(*w));
		Q_APPEND(wh, w);
	}
	return w;
}

- (void) clearColors:(NSRange) area inTextView:(NSTextView *) tv{	
	NSLayoutManager *lm = [[tv.textStorage layoutManagers] objectAtIndex: 0];
	[lm setTemporaryAttributes:colorAttr[TEXT_COLOR_IDX] forCharacterRange:area];
}

- (void) color:(NSRange) range withColor:(unsigned char) color inTextView:(NSTextView *) tv{
	NSLayoutManager *lm = [[tv.textStorage layoutManagers] objectAtIndex: 0];
	[lm setTemporaryAttributes:colorAttr[color] forCharacterRange:range];
}



- (void) highlight:(NSRange) range inTextView:(NSTextView *) tv {
	/* XXX: getting more and more ugly */
	if (!_syntax_color)
		return;

	NSString *string = [tv string];
	NSInteger pos;
	char prev=0,c;
	struct word *w;
	struct word_head wh;
	bzero(&wh,sizeof(wh));
	w = word_new(&wh);
	struct block *b = NULL;
	NSInteger begin,end;
	begin = range.location;
	end = NSMaxRange(range);
	struct block *superblock = NULL;

	for (pos = begin; pos < end; pos++) {
		c = [string characterAtIndex:pos] & B_TABLE_MASK;
		if (superblock && block_cond(superblock, c, prev, BLOCK_ENDS, pos)) {
			superblock = NULL;
		}
		
		if (b == NULL) {
			if (_syntax_blocks.b[c].color != 0) {
				b = &_syntax_blocks.b[c];
				if (!block_cond(b, c, prev, BLOCK_BEGINS,pos)) {
					b = NULL;
				} else {
					if (b->flags & B_SUPERBLOCK) {
						/* beginning of the uncolored superblock */
						superblock = b;
						b = NULL;
					}
				}
			}
		} else {
			b->range.length++;
			if (block_cond(b, c, prev, BLOCK_ENDS,pos)) {
				if ([self block_color:b superBlock:superblock])
					[self color:b->range withColor:b->color inTextView:tv];
				
				b = NULL;
			}
		}

		if (word_append(w,c,pos,(b ? b->flags : 0),_syntax_var_symbol) == WORD_ENDED) {
			w = word_new(&wh);
		}
		prev = c;
	}

	if (b) {
		b->range.length++;
		if ([self block_color:b superBlock:superblock])
			[self color:b->range withColor:b->color inTextView:tv];

	}

	while ((w = wh.head) != NULL) {
		wh.head = w->next;
		if (!word_is_valid_word(w) || w->current_block_flags & B_NO_KEYWORD)
			goto next;
		if (_syntax_var_symbol[(char)w->data[0]].color && w->len >= _syntax_var_symbol[(char)w->data[0]].required_len) {
			if (!(w->current_block_flags & B_NO_VAR)) 	/* dont color vars in single quoted strings */
				[self color:NSMakeRange(w->pos, w->len) withColor:_syntax_var_symbol[(char) w->data[0]].color inTextView:tv];
		} else if (w->current_block_flags == 0 || w->current_block_flags & B_SHOW_KEYWORD) { 		/* find keywords and numbers outside of blocks */
			if ((w->flags & WORD_NUMBER) == w->flags) {
				if (_syntax_color_numbers)
					[self color:NSMakeRange(w->pos, w->len) withColor:VALUE_COLOR_IDX inTextView:tv];	
			} else {
				struct _hash_entry *e = hash_lookup(&hash[0],w);
				if (e) 
					[self color:NSMakeRange(w->pos, w->len) withColor:e->w.color inTextView:tv];			
			}		
		}
next:
		free(w);
	}
}
//
//- (void) colorBracket {
//	NSString *string = [tv string];
//	NSRange selected = [tv selectedRange];
//	unichar cursor = (selected.location != NSNotFound && selected.location > 0) ? [string characterAtIndex:selected.location-1] : 0;
//	switch (cursor) {
//	case '}':
//		[self colorPrev:'{' ends:'}' inRange:selected inString:string];
//	case ')':
//		[self colorPrev:'(' ends:')' inRange:selected inString:string];
//	case ']':
//		[self colorPrev:'[' ends:']' inRange:selected inString:string];
//	break;
//	}
//}
- (void) colorPrev:(unichar) opens ends:(unichar) ends inRange:(NSRange) range inString:(NSString *) string{
	NSInteger open,pos;
	open = 0;
	for (pos = range.location-1; pos >= 0 ; pos--) {
		unichar c = [string characterAtIndex:pos];
		if (c == ends) {
			open++;
		}
		if (c == opens)
			open--;
		if (open == 0) {
			break;
		}
	}
}
- (void) string:(NSString *) source toWordStruct:(struct word *) w {
	NSInteger i;
	for (i=0;i<[source length]; i++) {
		w->data[w->len++ & WORD_MASK] = [source characterAtIndex:i];
	}
	w->data[w->len] = '\0';
}
- (void) addKeywords:(NSString *) words withColor:(int) color {
	NSArray *c = [words componentsSeparatedByString:@" "];
	for (NSString *e in c) {
		if ([e length] < WORD_SIZE) {
			struct word w;
			bzero(&w,sizeof(w));
			[self string:e toWordStruct:&w];
			struct _hash_entry *he = hash_insert(&hash[0], &w);
			he->w.color = color;
		}
	}
}


- (BOOL) ext:(NSString *) ext is:(NSString *) like {
	NSArray *l = [like componentsSeparatedByString:@" "];
	for (NSString *s in l) {
		if ([ext isEqualToString:s])
			return YES;
	}
	return NO;
}
- (void) initSyntax:(NSString *) ext box:(NSBox *) box{
#define SET_BLOCK(_b,_begin,_begin_prev,_end,_end_prev,_color,_flags) 		\
do {																		\
	_b = &_syntax_blocks.b[_begin];											\
	_b->char_begin = _begin;												\
	_b->char_begin_prev = _begin_prev;										\
	_b->char_end = _end;													\
	_b->char_end_prev = _end_prev;											\
	_b->color = _color;														\
	_b->flags = _flags;														\
} while (0);

	hash_init(&hash[0]);
	bzero(_syntax_var_symbol,sizeof(_syntax_var_symbol));
	for (int i = 0;i < B_TABLE_SIZE; i++) {
		_syntax_var_symbol[i].required_len = 2;
	}
	_syntax_color_numbers = 0;
	_syntax_color = 0;
	autoindent = YES;
	bzero(&_syntax_blocks, sizeof(_syntax_blocks));
	struct block *b;	
	[box setHidden:YES];
	if ([self ext:ext is:@"c h"]) {
		autoindent = YES;
		[self addKeywords:@"goto break return continue asm case default if else switch while for do" withColor:KEYWORD_COLOR_IDX];
		[self addKeywords:@"int long short char void signed unsigned float double size_t ssize_t off_t wchar_t ptrdiff_t sig_atomic_t fpos_t clock_t time_t va_list jmp_buf FILE DIR div_t ldiv_t mbstate_t wctrans_t wint_t wctype_t bool complex int8_t int16_t int32_t int64_t uint8_t uint16_t uint32_t uint64_t int_least8_t int_least16_t int_least32_t int_least64_t  uint_least8_t uint_least16_t uint_least32_t uint_least64_t int_fast8_t int_fast16_t int_fast32_t int_fast64_t  uint_fast8_t uint_fast16_t uint_fast32_t uint_fast64_t intptr_t uintptr_t intmax_t uintmax_t __label__ __complex__ __volatile__ struct union enum typedef static register auto volatile extern const" withColor:VARTYPE_COLOR_IDX];
		_syntax_color_numbers=1;
		_syntax_color = 1;
		SET_BLOCK(b,'*', '/', '/', '*', COMMENT_COLOR_IDX, B_NO_KEYWORD);
		SET_BLOCK(b,'/', '/', 0, 0, COMMENT_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_NO_KEYWORD))
		SET_BLOCK(b,'#', 0, 0, 0, PREPROCESS_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_NO_KEYWORD))
		SET_BLOCK(b,'"', 0, '"', 0, STRING2_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_SHOW_VAR))
		SET_BLOCK(b,'\'', 0, '\'', 0, STRING1_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_NO_VAR))
		[box setHidden:NO];
	} else if ([self ext:ext is:@"php"]) {
		autoindent = YES;
		[self addKeywords:@"abstract and as break case catch clone const continue declare default do else elseif enddeclare endfor endforeach endif end switch while extends array final for foreach function global goto if implements interface instanceof namespace new or private protected public static switch throw try use var while xor class function" withColor:KEYWORD_COLOR_IDX];
		[self addKeywords:@"echo print printf" withColor:CONSTANT_COLOR_IDX];
		[self addKeywords:@"__CLASS__ __DIR__ __FILE__ __LINE__ __FUNCTION__ __METHOD__ __NAMESPACE__"  withColor:CONDITION_COLOR_IDX];
		SET_BLOCK(b,'*', '/', '/', '*', COMMENT_COLOR_IDX, B_NO_KEYWORD);
		SET_BLOCK(b,'/', '/', 0, 0, COMMENT_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_NO_KEYWORD))
		SET_BLOCK(b,'#', 0, 0, 0, COMMENT_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_NO_KEYWORD))
		SET_BLOCK(b,'"', 0, '"', 0, STRING2_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_SHOW_VAR))
		SET_BLOCK(b,'\'', 0, '\'', 0, STRING1_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_NO_VAR))
		_syntax_var_symbol['$'].color = VARTYPE_COLOR_IDX;
		_syntax_color_numbers = 1;
		_syntax_color = 1;
	} else if ([self ext:ext is:@"rb erb rhtml"]) {
		autoindent = YES;
		int flags = 0;
		if ([self ext:ext is:@"erb rhtml"]) {
			flags = B_REQUIRE_SUPERBLOCK;
			SET_BLOCK(b,'%', '<', '>', '%', COMMENT_COLOR_IDX, (B_SUPERBLOCK | B_SHOW_VAR | B_SHOW_KEYWORD));
		}
		[self addKeywords:@"BEGIN END __ENCODING__ __END__ __FILE__ __LINE__ alias and begin break case class def defined? do else elsif end ensure false for if in module next nil not or redo rescue retry return super then true undef unless until when while yield protected private require" withColor:KEYWORD_COLOR_IDX];
		[self addKeywords:@"self attr_writer attr_reader attr_accessor"  withColor:CONDITION_COLOR_IDX];
		SET_BLOCK(b,'*', '/', '/', '*', COMMENT_COLOR_IDX, B_NO_KEYWORD| flags);
		SET_BLOCK(b,'/', '/', 0, 0, COMMENT_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_NO_KEYWORD | flags))
		SET_BLOCK(b,'#', 0, 0, 0, COMMENT_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_NO_KEYWORD | flags))
		SET_BLOCK(b,'"', 0, '"', 0, STRING2_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_SHOW_VAR | flags))		
		SET_BLOCK(b,'\'', 0, '\'', 0, STRING1_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_NO_VAR | flags))
		SET_BLOCK(b,'|', 0, '|', 0, PREPROCESS_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_SHOW_VAR | flags))
		SET_BLOCK(b,'/', 0, '/', 0, PREPROCESS_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_NO_KEYWORD | flags))
		_syntax_var_symbol['@'].color = VARTYPE_COLOR_IDX;
		_syntax_var_symbol[':'].color = CONSTANT_COLOR_IDX;
		_syntax_var_symbol['$'].color = VARTYPE_COLOR_IDX;
		_syntax_var_symbol['%'].color = VARTYPE_COLOR_IDX;
		_syntax_color_numbers = 1;
		_syntax_color = 1;
	} else if ([self ext:ext is:@"sh pl"]) {
		autoindent = YES;
		[self addKeywords:@"esac break return continue case default if else switch while for do in for expr true false done" withColor:KEYWORD_COLOR_IDX];
		[self addKeywords:@"echo print printf read exit"  withColor:CONDITION_COLOR_IDX];

		SET_BLOCK(b,'#', 0, 0, 0, COMMENT_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_NO_KEYWORD))
		SET_BLOCK(b,'"', 0, '"', 0, STRING2_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_SHOW_VAR))
		SET_BLOCK(b,'`', 0, '`', 0, CONSTANT_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_SHOW_VAR | B_SHOW_KEYWORD))
		SET_BLOCK(b,'\'', 0, '\'', 0, STRING1_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_NO_VAR))
		_syntax_var_symbol['$'].color = VARTYPE_COLOR_IDX;
		_syntax_color_numbers = 1;		
		_syntax_color = 1;
	}
	[self addKeywords:EXECUTE_COMMAND withColor:CONDITION_COLOR_IDX];
#undef SET_BLOCK
}

- (NSString *) get_line:(NSInteger) lineno inTextView:(NSTextView *) tv {
	NSRange area = [m_range rangeOfLine:lineno inString:[tv string]];
	if (area.location != NSNotFound) {
		return [[tv string] substringWithRange:area];
	}
	return nil;
}
- (NSString *) get_execute_command:(NSTextView *) tv {
	NSString *line = [self get_line:EXECUTE_LINE inTextView:tv];
	NSString *ret = nil;
	NSRange commandRange = [line rangeOfString:EXECUTE_COMMAND];
	if (commandRange.location != NSNotFound) {
		ret = [line substringFromIndex:commandRange.location+commandRange.length];
	}
	return ret;
}


- (void) parse:(m_range *) _range inTextView:(NSTextView *)tv{
	NSRange area = [_range paragraph:tv];
	[self clearColors:area inTextView:tv];
	[self highlight:area inTextView:tv];
	if ([self get_execute_command:tv]) 
		[self color:[m_range rangeOfLine:EXECUTE_LINE inString:[tv string]] withColor:CONDITION_COLOR_IDX inTextView:tv];
}

#pragma mark textView proto
- (void) dealloc {
	hash_init(&hash[0]);
}


@end
