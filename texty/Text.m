#import "Text.h"
@implementation Text
@synthesize tv,sv,box,tabItem,s,something_changed,autosave_ts,serializator,need_to_autosave;

- (Text *) initWithFrame:(NSRect) frame {
	self = [super init];
	colorAttr[VARTYPE_COLOR_IDX] = [NSDictionary dictionaryWithObject:VARTYPE_COLOR forKey:NSForegroundColorAttributeName];
	colorAttr[VALUE_COLOR_IDX] = [NSDictionary dictionaryWithObject:VALUE_COLOR forKey:NSForegroundColorAttributeName];
	colorAttr[KEYWORD_COLOR_IDX] = [NSDictionary dictionaryWithObject:KEYWORD_COLOR forKey:NSForegroundColorAttributeName];
	colorAttr[COMMENT_COLOR_IDX] = [NSDictionary dictionaryWithObject:COMMENT_COLOR forKey:NSForegroundColorAttributeName];
	colorAttr[STRING1_COLOR_IDX] = [NSDictionary dictionaryWithObject:STRING1_COLOR forKey:NSForegroundColorAttributeName];
	colorAttr[STRING2_COLOR_IDX] = [NSDictionary dictionaryWithObject:STRING2_COLOR forKey:NSForegroundColorAttributeName];
	colorAttr[PREPROCESS_COLOR_IDX] = [NSDictionary dictionaryWithObject:PREPROCESS_COLOR forKey:NSForegroundColorAttributeName];
	colorAttr[CONDITION_COLOR_IDX] = [NSDictionary dictionaryWithObject:CONDITION_COLOR forKey:NSForegroundColorAttributeName];
	colorAttr[TEXT_COLOR_IDX] = [NSDictionary dictionaryWithObject:TEXT_COLOR forKey:NSForegroundColorAttributeName];
	colorAttr[CONSTANT_COLOR_IDX] = [NSDictionary dictionaryWithObject:CONSTANT_COLOR forKey:NSForegroundColorAttributeName];


	self.serializator = [[NSLock alloc] init];
	self.sv = [[NSScrollView alloc] initWithFrame:frame];
	NSSize contentSize = [sv contentSize];
	[sv setBorderType:NSNoBorder];
	[sv setHasVerticalScroller:YES];
	[sv setHasHorizontalScroller:YES];
	[sv setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
	self.tabItem = [[NSTabViewItem alloc] init];
	tabItem.identifier = self;
	tabItem.view = sv;
	self.tv = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, contentSize.width, contentSize.height)];
	tv.delegate = self;
	tv.textStorage.delegate = self;
	[tv setMinSize:NSMakeSize(0.0, contentSize.height)];
	[tv setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
	[tv setVerticallyResizable:YES];
	[tv setHorizontallyResizable:YES];
	[tv setAutoresizingMask:NSViewWidthSizable];
	tv.allowsUndo = YES;
	[tv setUsesRuler:NO];
	tv.usesFindBar = YES;
	[tv.textStorage setParagraphs:nil];
	[tv setAutomaticDashSubstitutionEnabled:NO];
	[tv setAutomaticQuoteSubstitutionEnabled:NO];
	[tv setAutomaticLinkDetectionEnabled:NO];
	[tv setAutomaticSpellingCorrectionEnabled:NO];
	[tv setAutomaticTextReplacementEnabled:NO];
	[tv setImportsGraphics:NO];
	[[tv textContainer] setContainerSize:NSMakeSize(contentSize.width, FLT_MAX)];
	[[tv textContainer] setWidthTracksTextView:YES];
	NSMutableDictionary *selected = [[tv selectedTextAttributes] mutableCopy];
	NSMutableParagraphStyle *para = [[NSMutableParagraphStyle alloc] init];
	[para setLineSpacing:NSLineBreakByTruncatingHead];
	[para setDefaultTabInterval:36.];
	[para setTabStops:[NSArray array]];	
	[tv setDefaultParagraphStyle:para];
	[tv setTypingAttributes:[NSDictionary dictionaryWithObject:para forKey:NSParagraphStyleAttributeName]];
	[tv setFont:FONT];
	[tv setRichText:NO];
	[tv setTextColor:TEXT_COLOR];
	[tv setCanDrawConcurrently:NO];
	[selected setObject:BG_COLOR forKey:NSForegroundColorAttributeName];
	[selected setObject:TEXT_COLOR forKey:NSBackgroundColorAttributeName];
	[tv setSelectedTextAttributes:selected];
	[tv setBackgroundColor:BG_COLOR];
	[tv setInsertionPointColor:CURSOR_COLOR];
	NSRect boxRect = frame;
	NSSize char_size = [[NSString stringWithString:@"a"] sizeWithAttributes: [NSDictionary dictionaryWithObject:FONT forKey: NSFontAttributeName]];
	boxRect.size.width = 1;
	boxRect.origin.y = 0;
	boxRect.origin.x +=  char_size.width * 80;
	self.box = [[NSBox alloc] initWithFrame:boxRect];
	[box setBoxType:NSBoxCustom];
	box.fillColor = [NSColor clearColor];
	box.borderType =  NSLineBorder;
	box.borderColor = LINE_80_COLOR;
	[box setTitlePosition:NSNoTitle];
	[box setAutoresizingMask:NSViewHeightSizable];
	[box setTransparent:NO];
	[box setHidden:YES];
	[tv addSubview:box];
	[sv setDocumentView:tv];
	tabItem.label = @"aaaaa :) should never happen";	
	self.s = [[m_Storage alloc] init];
	something_changed = NO;
	return self;
}
- (void) responder {
	[tv setSelectedRange:NSMakeRange(0, 0)];
	[sv becomeFirstResponder];
}
- (void) resign {
	[sv resignFirstResponder];
}

- (BOOL) open:(NSURL *)file {
	if ([s open:file]) {
		[tv setString:s.data];
		tabItem.label = [s basename];
		[self performSelector:@selector(responder) withObject:self afterDelay:0];
		m_range *range = [[m_range alloc] init];
		range.range = NSMakeRange(0, [[tv string] length]);
		range.change = [[tv string] length];
		[self parse:range];
		autosave_ts = 0;
		[self initSyntax];
		return YES;
	}
	return NO;
}
- (void) saveAs:(NSURL *) to {
	[s migrate:to];
	[self initSyntax];
	tabItem.label = [s basename];
}
- (void) save {
	if ([s overwrite:[tv.textStorage string]]) 
		tabItem.label = [s basename];
}
- (void) revertToSaved {
	[tv setString:s.data];
}
- (BOOL) is_modified {
	return ![[tv.textStorage string] isEqualToString:s.data];
}
- (void) goto_line:(NSInteger) want_line {
	NSRange area = [m_range rangeOfLine:want_line inString:[tv string]];
	if (area.location != NSNotFound) {
		[tv setSelectedRange: area];
		[tv scrollRangeToVisible: area];
	}
}
- (NSString *) get_line:(NSInteger) lineno {
	NSRange area = [m_range rangeOfLine:lineno inString:[tv string]];
	if (area.location != NSNotFound) {
		return [[tv string] substringWithRange:area];
	}
	return nil;
}
- (NSString *) get_execute_command {
	NSString *line = [self get_line:EXECUTE_LINE];
	NSString *ret = nil;
	NSRange commandRange = [line rangeOfString:EXECUTE_COMMAND];
	if (commandRange.location != NSNotFound) {
		ret = [line substringFromIndex:commandRange.location+commandRange.length];
	}
	return ret;
}
- (void) signal {
	[serializator lock];
	if (need_to_autosave) {
		if (time(NULL) - autosave_ts > AUTOSAVE_INTERVAL) {
			if (s.temporary)
				[self save];
			else 
				[s autosave:NO];
			autosave_ts = time(NULL);
			need_to_autosave = NO;
		}
	}
	if (something_changed) {
		if ([self is_modified]) {
			tabItem.label = [NSString stringWithFormat:@"%@ *",[s basename]];
			need_to_autosave = YES;
		}
		something_changed = NO;
	}
	[serializator unlock];
}


#pragma mark Syntax
- (void) clearColors:(NSRange) area {	
	NSLayoutManager *lm = [[tv.textStorage layoutManagers] objectAtIndex: 0];
	[lm setTemporaryAttributes:colorAttr[TEXT_COLOR_IDX] forCharacterRange:area];
}

- (void) color:(NSRange) range withColor:(unsigned char) color {
	NSLayoutManager *lm = [[tv.textStorage layoutManagers] objectAtIndex: 0];
	[lm setTemporaryAttributes:colorAttr[color] forCharacterRange:range];
}

- (BOOL) extIs:(NSArray *) ext {
	NSString *fileExt = [s.fileURL pathExtension];
	for (NSString *str in ext)
		if ([fileExt isEqualToString:str])
			return YES;
	return NO;
}

- (void) parse:(m_range *) m_range {
	NSRange range = [m_range paragraph:tv];
	[self clearColors:range];
	[self highlight:range];
}

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
static inline int block_cond(struct block *b, char cmask, char pmask,int type) {
	if (pmask == '\\') 
		return 0;
		
	if (type == BLOCK_BEGINS) {
		return (b->char_begin == cmask && (b->char_begin_prev == 0 || b->char_begin_prev == pmask));
	} else {
		if ((cmask == '\n' || cmask == '\r') && (b->flags & B_ENDS_WITH_NEW_LINE)) 
			return 1;
		return (b->char_end == cmask && (b->char_end_prev == 0 || b->char_end_prev == pmask));
	}
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
	return ((w->flags & (WORD_NUMBER|WORD_ALPHA_LOWER|WORD_ALPHA_UPPER|WORD_DASH|WORD_VARSYMBOL)) == w->flags);
}
static inline int word_valid_symbol(unichar c, char *var_symbol_table) {
	if (c >= 'a' && c <= 'z')
		return WORD_ALPHA_LOWER;
	else if (c >= '0' && c <= '9') 
		return WORD_NUMBER;
	else if (c >= 'A' && c <= 'Z') 
		return  WORD_ALPHA_UPPER;
	else if (c == '_')
		return WORD_DASH;
	else if (c < B_TABLE_SIZE && var_symbol_table[c]) 
		return WORD_VARSYMBOL;
	else 
		return WORD_INVALID;
}
static inline int word_append(struct word *w, unichar c, NSInteger pos,char current_block_flags, char *var_symbol_table) {
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

- (void) highlight:(NSRange) range {
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
	for (pos = begin; pos < end; pos++) {
		c = [string characterAtIndex:pos] & B_TABLE_MASK;
		if (!_syntax_color)
			goto keyword_only;
		if (b == NULL) {
			if (_syntax_blocks.b[c].color != 0) {
				b = &_syntax_blocks.b[c];				
				if (block_cond(b, c, prev, BLOCK_BEGINS)) {
					block_begin(b, pos);
					if (b->char_begin_prev) 
						b->range.location--;
					
					b->range.length++;
				} else {
					b = NULL;
				}
			}
		} else {
			b->range.length++;
			if (block_cond(b, c, prev, BLOCK_ENDS)) {
				if (b->char_end_prev) 
					b->range.length++;
				
				[self color:b->range withColor:b->color];
				b = NULL;			
			}
		}

keyword_only:
		if (word_append(w,c,pos,(b ? b->flags : 0),_syntax_var_symbol) == WORD_ENDED) {
			w = word_new(&wh);
		}
		prev = c;
	}

	if (b) {
		b->range.length++;
		[self color:b->range withColor:b->color];
	}

	while ((w = wh.head) != NULL) {
		wh.head = w->next;
		if (!word_is_valid_word(w) || w->current_block_flags & B_NO_KEYWORD)
			goto next;
		if (_syntax_var_symbol[(char)w->data[0]]) {
			if (!(w->current_block_flags & B_NO_VAR)) /* dont color vars in single quoted strings */
				[self color:NSMakeRange(w->pos, w->len) withColor:_syntax_var_symbol[(char) w->data[0]]];				
		} else if (w->current_block_flags == 0) { 		/* find keywords and numbers outside of blocks */
			if ((w->flags & WORD_NUMBER) == w->flags) {
				if (_syntax_color_numbers)
					[self color:NSMakeRange(w->pos, w->len) withColor:VALUE_COLOR_IDX];	
			} else {
				struct _hash_entry *e = hash_lookup(&hash[0],w);
				if (e) 
					[self color:NSMakeRange(w->pos, w->len) withColor:e->w.color];			
			}		
		}
next:
		free(w);
	}
	NSRange execLine = [m_range rangeOfLine:EXECUTE_LINE inString:string];
	[self color:execLine withColor:CONDITION_COLOR_IDX];
}

- (void) colorBracket {
	NSString *string = [tv string];
	NSRange selected = [tv selectedRange];
	unichar cursor = (selected.location != NSNotFound && selected.location > 0) ? [string characterAtIndex:selected.location-1] : 0;
	switch (cursor) {
	case '}':
		[self colorPrev:'{' ends:'}' inRange:selected inString:string];
	case ')':
		[self colorPrev:'(' ends:')' inRange:selected inString:string];
	case ']':
		[self colorPrev:'[' ends:']' inRange:selected inString:string];
	break;
	}
}
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

- (void) initSyntax {
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
	_syntax_color_numbers = 0;
	_syntax_color = 0;
	bzero(&_syntax_blocks, sizeof(_syntax_blocks));
	struct block *b;	
	[box setHidden:YES];
	if ([self extIs:[NSArray arrayWithObjects:@"c",@"h", nil]]) {
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
	} else if ([self extIs:[NSArray arrayWithObjects:@"php", nil]]) {
		[self addKeywords:@"abstract and as break case catch clone const continue declare default do else elseif enddeclare endfor endforeach endif end switch while extends array final for foreach function global goto if implements interface instanceof namespace new or private protected public static switch throw try use var while xor class function" withColor:KEYWORD_COLOR_IDX];
		[self addKeywords:@"echo print printf" withColor:CONSTANT_COLOR_IDX];
		[self addKeywords:@"__CLASS__ __DIR__ __FILE__ __LINE__ __FUNCTION__ __METHOD__ __NAMESPACE__"  withColor:CONDITION_COLOR_IDX];
		SET_BLOCK(b,'*', '/', '/', '*', COMMENT_COLOR_IDX, B_NO_KEYWORD);
		SET_BLOCK(b,'/', '/', 0, 0, COMMENT_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_NO_KEYWORD))
		SET_BLOCK(b,'#', 0, 0, 0, COMMENT_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_NO_KEYWORD))
		SET_BLOCK(b,'"', 0, '"', 0, STRING2_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_SHOW_VAR))
		SET_BLOCK(b,'\'', 0, '\'', 0, STRING1_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_NO_VAR))
		_syntax_var_symbol['$'] = VARTYPE_COLOR_IDX;
		_syntax_color_numbers = 1;
		_syntax_color = 1;
	} else if ([self extIs:[NSArray arrayWithObjects:@"rb", nil]]) {
		[self addKeywords:@"class if else while do puts end def times length yield initialize inspect private protected public block_given" withColor:KEYWORD_COLOR_IDX];
		[self addKeywords:@"echo print printf" withColor:CONSTANT_COLOR_IDX];
		[self addKeywords:@"super attr_writer attr_reader"  withColor:CONDITION_COLOR_IDX];
		SET_BLOCK(b,'*', '/', '/', '*', COMMENT_COLOR_IDX, B_NO_KEYWORD);
		SET_BLOCK(b,'/', '/', 0, 0, COMMENT_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_NO_KEYWORD))
		SET_BLOCK(b,'#', 0, 0, 0, COMMENT_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_NO_KEYWORD))
		SET_BLOCK(b,'"', 0, '"', 0, STRING2_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_SHOW_VAR | B_HAS_SUBBLOCKS))		
		SET_BLOCK(b,'\'', 0, '\'', 0, STRING1_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_NO_VAR))
		SET_BLOCK(b,'|', 0, '|', 0, PREPROCESS_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_SHOW_VAR))
		SET_BLOCK(b,'/', 0, '/', 0, PREPROCESS_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_NO_KEYWORD))
		_syntax_var_symbol['@'] = VARTYPE_COLOR_IDX;
		_syntax_var_symbol[':'] = VARTYPE_COLOR_IDX;
		_syntax_var_symbol['$'] = VARTYPE_COLOR_IDX;
		_syntax_color_numbers = 1;
		_syntax_color = 1;
	} else if ([self extIs:[NSArray arrayWithObjects:@"sh", nil]]) {
		[self addKeywords:@"esac break return continue case default if else switch while for do" withColor:KEYWORD_COLOR_IDX];
		SET_BLOCK(b,'#', 0, 0, 0, COMMENT_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_NO_KEYWORD))
		SET_BLOCK(b,'"', 0, '"', 0, STRING2_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_SHOW_VAR))
		SET_BLOCK(b,'\'', 0, '\'', 0, STRING1_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_NO_VAR))
		_syntax_var_symbol['$'] = VARTYPE_COLOR_IDX;
		_syntax_color_numbers = 1;		
		_syntax_color = 1;
	}
	[self addKeywords:EXECUTE_COMMAND withColor:CONDITION_COLOR_IDX];
#undef SET_BLOCK
}
#pragma mark textStorage proto
- (NSArray *) textView:(NSTextView *)textView completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index {
	NSString *part = [[tv string] substringWithRange:charRange];
	return [self hash_to_array:part];
}
- (void) textStorageWillProcessEditing:(NSNotification *)notification {
	if ([tv.textStorage editedMask] & NSTextStorageEditedCharacters) {
		[serializator lock];
		something_changed = YES;
		[serializator unlock];
		NSTextStorage *storage = tv.textStorage;
		m_range *range = [[m_range alloc] init];
		NSInteger change = [storage changeInLength];
		NSRange editted = [storage editedRange];
		range.change = change;
		range.range = editted;
		[self performSelector:@selector(parse:) withObject:range afterDelay:0];		
	}
}
- (void) dealloc {
	hash_init(&hash[0]);
}
@end
