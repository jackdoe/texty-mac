#import "Text.h"
@implementation Text
@synthesize tv,sv,box,tabItem,s,something_changed,autosave_ts,serializator,need_to_autosave;

- (Text *) initWithFrame:(NSRect) frame {
	self = [super init];
	colorSet[VARTYPE_COLOR_IDX] = VARTYPE_COLOR;
	colorAttr[VARTYPE_COLOR_IDX] = [NSDictionary dictionaryWithObject:VARTYPE_COLOR forKey:NSForegroundColorAttributeName];

	colorSet[VALUE_COLOR_IDX] = VALUE_COLOR;
	colorAttr[VALUE_COLOR_IDX] = [NSDictionary dictionaryWithObject:VALUE_COLOR forKey:NSForegroundColorAttributeName];

	
	colorSet[KEYWORD_COLOR_IDX] = KEYWORD_COLOR;
	colorAttr[KEYWORD_COLOR_IDX] = [NSDictionary dictionaryWithObject:KEYWORD_COLOR forKey:NSForegroundColorAttributeName];

	colorSet[COMMENT_COLOR_IDX] = COMMENT_COLOR;
	colorAttr[COMMENT_COLOR_IDX] = [NSDictionary dictionaryWithObject:COMMENT_COLOR forKey:NSForegroundColorAttributeName];

	colorSet[STRING1_COLOR_IDX] = STRING1_COLOR;
	colorAttr[STRING1_COLOR_IDX] = [NSDictionary dictionaryWithObject:STRING1_COLOR forKey:NSForegroundColorAttributeName];

	colorSet[STRING2_COLOR_IDX] = STRING2_COLOR;
	colorAttr[STRING2_COLOR_IDX] = [NSDictionary dictionaryWithObject:STRING2_COLOR forKey:NSForegroundColorAttributeName];

	colorSet[PREPROCESS_COLOR_IDX] = PREPROCESS_COLOR;
	colorAttr[PREPROCESS_COLOR_IDX] = [NSDictionary dictionaryWithObject:PREPROCESS_COLOR forKey:NSForegroundColorAttributeName];

	
	colorSet[CONDITION_COLOR_IDX] = CONDITION_COLOR;
	colorAttr[CONDITION_COLOR_IDX] = [NSDictionary dictionaryWithObject:CONDITION_COLOR forKey:NSForegroundColorAttributeName];

	colorSet[TEXT_COLOR_IDX] = TEXT_COLOR;
	colorAttr[TEXT_COLOR_IDX] = [NSDictionary dictionaryWithObject:TEXT_COLOR forKey:NSForegroundColorAttributeName];


	self.serializator = [[NSLock alloc] init];
	self.sv = [[NSScrollView alloc] initWithFrame:frame];
	NSSize contentSize = [self.sv contentSize];
	[self.sv setBorderType:NSNoBorder];
	[self.sv setHasVerticalScroller:YES];
	[self.sv setHasHorizontalScroller:YES];
	[self.sv setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
	self.tabItem = [[NSTabViewItem alloc] init];
	self.tabItem.identifier = self;
	self.tabItem.view = self.sv;
	self.tv = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, contentSize.width, contentSize.height)];
	self.tv.delegate = self;
	self.tv.textStorage.delegate = self;
	[self.tv setMinSize:NSMakeSize(0.0, contentSize.height)];
	[self.tv setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
	[self.tv setVerticallyResizable:YES];
	[self.tv setHorizontallyResizable:YES];
	[self.tv setAutoresizingMask:NSViewWidthSizable];
	self.tv.allowsUndo = YES;
	[self.tv setUsesRuler:NO];
	self.tv.usesFindBar = YES;
	[self.tv.textStorage setParagraphs:nil];
	[self.tv setAutomaticDashSubstitutionEnabled:NO];
	[self.tv setAutomaticQuoteSubstitutionEnabled:NO];
	[self.tv setAutomaticLinkDetectionEnabled:NO];
	[self.tv setAutomaticSpellingCorrectionEnabled:NO];
	[self.tv setAutomaticTextReplacementEnabled:NO];
	[self.tv setImportsGraphics:NO];
	[[self.tv textContainer] setContainerSize:NSMakeSize(contentSize.width, FLT_MAX)];
	[[self.tv textContainer] setWidthTracksTextView:YES];
	NSMutableDictionary *selected = [[self.tv selectedTextAttributes] mutableCopy];
	NSMutableParagraphStyle *para = [[NSMutableParagraphStyle alloc] init];
	[para setLineSpacing:NSLineBreakByTruncatingHead];
	[para setDefaultTabInterval:36.];
	[para setTabStops:[NSArray array]];	
	[self.tv setDefaultParagraphStyle:para];
	[self.tv setTypingAttributes:[NSDictionary dictionaryWithObject:para forKey:NSParagraphStyleAttributeName]];
	[self.tv setFont:FONT];
	[self.tv setRichText:NO];
	[self.tv setTextColor:TEXT_COLOR];
	[self.tv setCanDrawConcurrently:NO];
	[selected setObject:BG_COLOR forKey:NSForegroundColorAttributeName];
	[selected setObject:TEXT_COLOR forKey:NSBackgroundColorAttributeName];
	[self.tv setSelectedTextAttributes:selected];
	[self.tv setBackgroundColor:BG_COLOR];
	[self.tv setInsertionPointColor:CURSOR_COLOR];
	NSRect boxRect = frame;
	NSSize char_size = [[NSString stringWithString:@"a"] sizeWithAttributes: [NSDictionary dictionaryWithObject:FONT forKey: NSFontAttributeName]];
	boxRect.size.width = 1;
	boxRect.origin.y = 0;
	boxRect.origin.x +=  char_size.width * 80;
	self.box = [[NSBox alloc] initWithFrame:boxRect];
	[self.box setBoxType:NSBoxCustom];
	self.box.fillColor = [NSColor clearColor];
	self.box.borderType =  NSLineBorder;
	self.box.borderColor = LINE_80_COLOR;
	[self.box setTitlePosition:NSNoTitle];
	[self.box setAutoresizingMask:NSViewHeightSizable];
	[self.box setTransparent:NO];
	[self.box setHidden:YES];
	[self.tv addSubview:self.box];
	[self.sv setDocumentView:self.tv];
	self.tabItem.label = @"SHOULD NOT HAPPEN, REPORT IT";	
	self.s = [[m_Storage alloc] init];
	self.something_changed = NO;
	return self;
}
- (void) resign {
	[self.sv resignFirstResponder];
}
- (void) responder {
		[self.tv setSelectedRange:NSMakeRange(0, 0)];
		[self.sv becomeFirstResponder];
}


- (BOOL) open:(NSURL *)file {
	if ([self.s open:file]) {
		[self.tv setString:self.s.data];
		self.tabItem.label = [self.s basename];
		[self performSelector:@selector(responder) withObject:self afterDelay:0];
		m_range *range = [[m_range alloc] init];
		range.range = NSMakeRange(0, [[self.tv string] length]);
		range.change = [[self.tv string] length];
		[self parse:range];
		self.autosave_ts = 0;
		[self initSyntax];
		return YES;
	}
	return NO;
}
- (void) saveAs:(NSURL *) to {
	[self.s migrate:to];
	[self initSyntax];
	self.tabItem.label = [self.s basename];
}
- (void) save {
	if ([self.s overwrite:[self.tv.textStorage string]]) 
		self.tabItem.label = [self.s basename];
}
- (void) revertToSaved {
	[self.tv setString:self.s.data];
}
- (BOOL) is_modified {
	return ![[self.tv.textStorage string] isEqualToString:self.s.data];
}
- (void) goto_line:(NSInteger) want_line {
	NSString *string = [self.tv.textStorage string];		
	NSUInteger total_len = [string length];
	__block NSUInteger total_lines = 0, pos = 0;
	[string enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
		total_lines++;
		if (total_lines < want_line) {
			pos += [line length];
			if (pos < total_len)
				pos++; /* new line */;
		} else {
			*stop = YES;
		}
	}];
	NSRange area = [string paragraphRangeForRange:NSMakeRange(pos, 0)];
	[self.tv setSelectedRange: area];
	[self.tv scrollRangeToVisible: area];
}
- (NSString *) get_line:(NSInteger) lineno {
	NSString *t = [self.tv.textStorage string];
	__block NSString *ret = nil;
	__block NSInteger num = 1;
	[t enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
		if (num++ == lineno) {
			ret = [line copy];
			*stop = YES;
		}
	}];
	return ret;
}
- (NSString *) get_execute_command {
	NSString *line = [self get_line:2];
	NSString *ret = nil;
	NSRange commandRange = [line rangeOfString:EXECUTE_COMMAND];
	if (commandRange.location != NSNotFound) {
		ret = [line substringFromIndex:commandRange.location+commandRange.length];
	}
	return ret;
}
- (void) signal {
	[self.serializator lock];
	if (self.need_to_autosave) {
		if (time(NULL) - self.autosave_ts > AUTOSAVE_INTERVAL) {
			if (self.s.temporary)
				[self save];
			else 
				[self.s autosave:NO];
			self.autosave_ts = time(NULL);
			self.need_to_autosave = NO;
		}
	}
	if (self.something_changed) {
		if ([self is_modified]) {
			self.tabItem.label = [NSString stringWithFormat:@"%@ *",[self.s basename]];
			self.need_to_autosave = YES;
		}
		self.something_changed = NO;
	}
	[self.serializator unlock];
}


#pragma mark Syntax
- (void) clearColors:(NSRange) area {	
	NSLayoutManager *lm = [[self.tv.textStorage layoutManagers] objectAtIndex: 0];
	[lm setTemporaryAttributes:colorAttr[TEXT_COLOR_IDX] forCharacterRange:area];
}

- (void) color:(NSRange) range withColor:(unsigned char) color {
	NSLayoutManager *lm = [[self.tv.textStorage layoutManagers] objectAtIndex: 0];
	[lm setTemporaryAttributes:colorAttr[color] forCharacterRange:range];
}

- (BOOL) extIs:(NSArray *) ext {
	NSString *fileExt = [self.s.fileURL pathExtension];
	for (NSString *str in ext)
		if ([fileExt isEqualToString:str])
			return YES;
	return NO;
}

- (void) parse:(m_range *) m_range {
	NSRange range = [m_range paragraph:self.tv];
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
#define BLOCK_BEGINS 1
#define BLOCK_ENDS 2

static inline int block_cond(struct block *b, char cmask, char pmask,int type) {
	if (type == BLOCK_BEGINS) {
		return (pmask != '\\' && b->char_begin == cmask && (b->char_begin_prev == 0 || b->char_begin_prev == pmask));
	} else {
		return (pmask != '\\' && b->char_end == cmask && (b->char_end_prev == 0 || b->char_end_prev == pmask));
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
static inline int word_valid_symbol(unichar c) {
	if (c >= 'a' && c <= 'z')
		return WORD_ALPHA_LOWER;
	else if (c >= '0' && c <= '9') 
		return WORD_NUMBER;
	else if (c >= 'A' && c <= 'Z') 
		return  WORD_ALPHA_UPPER;
	else if (c == '_')
		return WORD_DASH;
	else if (c == '$') 
		return WORD_VARSYMBOL;
	else 
		return WORD_INVALID;
}
static inline int word_append(struct word *w, unichar c, NSInteger pos,char current_block_flags) {
	if (!w) {
		/* no mem */
		return 0;
	}
	int flags = word_valid_symbol(c);
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
	NSString *string = [self.tv string];
	NSInteger pos;
	unichar prev=0,c;
	struct word *w;
	struct word_head wh;
	bzero(&wh,sizeof(wh));
	w = word_new(&wh);
	struct block *b = NULL;
	for (pos = range.location; pos < NSMaxRange(range); pos++) {
		c = [string characterAtIndex:pos];
		if (!_syntax_color)
			goto keyword_only;
			

		char cmask = c & B_TABLE_MASK;
		char pmask = prev & B_TABLE_MASK;			
		if (b) 
			b->range.length++;

		if (b == NULL && prev != '\\') {
			if (_syntax_blocks.b[cmask].color != 0) {
				struct block *btemp = &_syntax_blocks.b[cmask];				
				if (block_cond(btemp, cmask, pmask, BLOCK_BEGINS)) {
					block_begin(btemp, pos);
					if (btemp->char_begin_prev) {
						btemp->range.location--;
					}
					b = btemp;
					b->range.length++;
				}
			}
		} else {
			switch (c) {
			case '\n':
			case '\r':
				if (prev != '\\' && (b->flags & B_ENDS_WITH_NEW_LINE)) {				
					[self color:b->range withColor:b->color];
					b = NULL;
				}
				break;
			default:
				if (block_cond(b, cmask, pmask, BLOCK_ENDS)) {
						if (b->char_end_prev) {
							b->range.length++;
						}
						[self color:b->range withColor:b->color];
						b = NULL;			
				}
			}
		}

keyword_only:
		if (word_append(w,c,pos,(b ? b->flags : 0)) == WORD_ENDED) {
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
		if (!word_is_valid_word(w))
			goto next;
			
		if (w->current_block_flags && (w->current_block_flags & B_STRING_2)) {
			if (_syntax_var_symbol > 0 && w->data[0] == _syntax_var_symbol) {
				[self color:NSMakeRange(w->pos, w->len) withColor:VARTYPE_COLOR_IDX];				
			}						
		} else {
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
	_syntax_var_symbol = 0;
	_syntax_color_numbers = 0;
	_syntax_color = 1;
	bzero(&_syntax_blocks, sizeof(_syntax_blocks));
	struct block *b;	
	[self.box setHidden:YES];
	if ([self extIs:[NSArray arrayWithObjects:@"c",@"h", nil]]) {
		[self addKeywords:@"goto break return continue asm case default if else switch while for do" withColor:KEYWORD_COLOR_IDX];
		[self addKeywords:@"int long short char void signed unsigned float double size_t ssize_t off_t wchar_t ptrdiff_t sig_atomic_t fpos_t clock_t time_t va_list jmp_buf FILE DIR div_t ldiv_t mbstate_t wctrans_t wint_t wctype_t bool complex int8_t int16_t int32_t int64_t uint8_t uint16_t uint32_t uint64_t int_least8_t int_least16_t int_least32_t int_least64_t  uint_least8_t uint_least16_t uint_least32_t uint_least64_t int_fast8_t int_fast16_t int_fast32_t int_fast64_t  uint_fast8_t uint_fast16_t uint_fast32_t uint_fast64_t intptr_t uintptr_t intmax_t uintmax_t __label__ __complex__ __volatile__ struct union enum typedef static register auto volatile extern const" withColor:VARTYPE_COLOR_IDX];
		_syntax_color_numbers=1;
		_syntax_color = 1;
		SET_BLOCK(b,'*', '/', '/', '*', COMMENT_COLOR_IDX, B_COMMENT);
		SET_BLOCK(b,'/', '/', 0, 0, COMMENT_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_COMMENT))
		SET_BLOCK(b,'#', 0, 0, 0, PREPROCESS_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_COMMENT))
		SET_BLOCK(b,'"', 0, '"', 0, STRING2_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_STRING_2))
		SET_BLOCK(b,'\'', 0, '\'', 0, STRING1_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_STRING_1))
		[self.box setHidden:NO];
	} else if ([self extIs:[NSArray arrayWithObjects:@"php", nil]]) {
		[self addKeywords:@"abstract and as break case catch class clone const continue declare default do else elseif enddeclare endfor endforeach endif end switch while extends array final for foreach function global goto if implements interface instanceof namespace new or private protected public static switch throw try use var while xor __CLASS__ __DIR__ __FILE__ __LINE__ __FUNCTION__ __METHOD__ __NAMESPACE__" withColor:KEYWORD_COLOR_IDX];
		_syntax_var_symbol = '$';
		_syntax_color_numbers = 1;
		_syntax_color = 1;		
		SET_BLOCK(b,'*', '/', '/', '*', COMMENT_COLOR_IDX, B_COMMENT);
		SET_BLOCK(b,'/', '/', 0, 0, COMMENT_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_COMMENT))
		SET_BLOCK(b,'#', 0, 0, 0, COMMENT_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_COMMENT))
		SET_BLOCK(b,'"', 0, '"', 0, STRING2_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_STRING_2))
		SET_BLOCK(b,'\'', 0, '\'', 0, STRING1_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_STRING_1))

		
	} else if ([self extIs:[NSArray arrayWithObjects:@"sh", nil]]) {
		[self addKeywords:@"esac break return continue case default if else switch while for do" withColor:KEYWORD_COLOR_IDX];
		_syntax_var_symbol = '$';
		_syntax_color_numbers = 1;		
		_syntax_color = 1;
		SET_BLOCK(b,'#', 0, 0, 0, COMMENT_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_COMMENT))
		SET_BLOCK(b,'"', 0, '"', 0, STRING2_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_STRING_2))
		SET_BLOCK(b,'\'', 0, '\'', 0, STRING1_COLOR_IDX, (B_ENDS_WITH_NEW_LINE | B_STRING_1))
	}
	[self addKeywords:EXECUTE_COMMAND withColor:CONDITION_COLOR_IDX];
#undef SET_BLOCK
}
#pragma mark textStorage proto
- (NSArray *) textView:(NSTextView *)textView completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index {
	NSString *part = [[self.tv string] substringWithRange:charRange];
	return [self hash_to_array:part];
}
- (void) textStorageWillProcessEditing:(NSNotification *)notification {
	[self.serializator lock];
	self.something_changed = YES;
	[self.serializator unlock];
	NSTextStorage *storage = self.tv.textStorage;
	m_range *range = [[m_range alloc] init];
	NSInteger change = [storage changeInLength];
	NSRange editted = [storage editedRange];
	range.change = change;
	range.range = editted;
	[self performSelector:@selector(parse:) withObject:range afterDelay:0];
}
- (void) dealloc {
	hash_init(&hash[0]);
}
@end
