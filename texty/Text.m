#import "Text.h"
@implementation Text
@synthesize tv,sv,box,tabItem,s,something_changed,autosave_ts,serializator,need_to_autosave,patterns;

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
	self.tv.textStorage.delegate = self;
	[self.tv setMinSize:NSMakeSize(0.0, contentSize.height)];
	[self.tv setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
	[self.tv setVerticallyResizable:YES];
	[self.tv setHorizontallyResizable:YES];
	[self.tv setAutoresizingMask:NSViewWidthSizable];
	self.tv.allowsUndo = YES;
	self.tv.usesRuler = NO;
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
	[self.tv setFont:FONT];
	[self.tv setRichText:NO];
	[self.tv setTextColor:TEXT_COLOR];
	[self.tv setCanDrawConcurrently:NO];
	NSMutableDictionary *selected = [[self.tv selectedTextAttributes] mutableCopy];
	NSMutableParagraphStyle *para = [[self.tv defaultParagraphStyle] mutableCopy];
	[para setLineSpacing:NSLineBreakByTruncatingHead];
	[self.tv setDefaultParagraphStyle:para];
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
	self.patterns = nil;
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
		if (time(NULL) - self.autosave_ts > 60) {
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
	NSString *t = [self.tv string];
	
	if (self.patterns) {
		[self clearColors:range];
		for (NSMutableArray *item in self.patterns) {
			int color = [[item objectAtIndex:1] intValue];
			id value = [item objectAtIndex:0];
			if ([value isKindOfClass:[NSMutableDictionary class]]) {
				[t enumerateSubstringsInRange:range options:NSStringEnumerationByWords usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
					if ([(NSMutableDictionary *) value objectForKey:substring]) {
						[self color:substringRange withColor:color];
					}
				}];
			} else {
				NSArray *matches = [(NSRegularExpression *) value matchesInString:t options:0 range:range];
				for (NSTextCheckingResult *match in matches) {
					[self color:[match range] withColor:color];
				}
			}
		}
	}
}
- (void) addSyntax:(NSString *) pattern withColor:(NSInteger) color andType:(int) type {
	NSMutableArray *item = [NSMutableArray array];

	if (type == SYNTAX_TYPE_REGEXP) {
		NSError *err;
		NSRegularExpression *regexp = [[NSRegularExpression alloc] initWithPattern:pattern options:0 error:&err];
		if (err) {
			NSLog(@"failed to create %@",pattern);
			return;
		}
		[item addObject:[regexp copy]];
	} else {
		NSArray *c = [pattern componentsSeparatedByString:@" "];
		NSMutableDictionary *value = [NSMutableDictionary dictionary];
		for (NSString *e in c) {
			[value setValue:@"" forKey:[e copy]];
		}
		[item addObject:value];
	}
	[item addObject:[NSNumber numberWithInteger:color]];
	[self.patterns addObject:item];

}

- (void) initSyntax {
	self.patterns = nil;
	self.patterns = [[NSMutableArray alloc] init];
	if ([self extIs:[NSArray arrayWithObjects:@"c",@"h", nil]]) {
		[self addSyntax:@"\\b(\\d+)\\b" withColor:VALUE_COLOR_IDX andType:SYNTAX_TYPE_REGEXP];
		[self addSyntax:@"goto break return continue asm case default if else switch while for do" withColor:KEYWORD_COLOR_IDX andType:SYNTAX_TYPE_DICT];
		[self addSyntax:@"int long short char void signed unsigned float double size_t ssize_t off_t wchar_t ptrdiff_t sig_atomic_t fpos_t clock_t time_t va_list jmp_buf FILE DIR div_t ldiv_t mbstate_t wctrans_t wint_t wctype_t bool complex int8_t int16_t int32_t int64_t uint8_t uint16_t uint32_t uint64_t int_least8_t int_least16_t int_least32_t int_least64_t  uint_least8_t uint_least16_t uint_least32_t uint_least64_t int_fast8_t int_fast16_t int_fast32_t int_fast64_t  uint_fast8_t uint_fast16_t uint_fast32_t uint_fast64_t intptr_t uintptr_t intmax_t uintmax_t __label__ __complex__ __volatile__ struct union enum typedef static register auto volatile extern const" withColor:VARTYPE_COLOR_IDX andType:SYNTAX_TYPE_DICT];
		[self addSyntax:@"\".*\"" withColor:STRING1_COLOR_IDX andType:SYNTAX_TYPE_REGEXP]; /* XXX */
		[self addSyntax:@"'.*'"	withColor:STRING2_COLOR_IDX andType:SYNTAX_TYPE_REGEXP]; /* XXX */
		[self addSyntax:@"//.*?[\\n|\\r]" withColor:COMMENT_COLOR_IDX andType:SYNTAX_TYPE_REGEXP];
	} else if ([self extIs:[NSArray arrayWithObjects:@"php", nil]]) {
		[self addSyntax:@"\\b(\\d+)\\b" withColor:VALUE_COLOR_IDX andType:SYNTAX_TYPE_REGEXP];
		[self addSyntax:@"goto break return continue asm case default if else switch while for do" withColor:KEYWORD_COLOR_IDX andType:SYNTAX_TYPE_DICT];
		[self addSyntax:@"\".*\"" withColor:STRING1_COLOR_IDX andType:SYNTAX_TYPE_REGEXP]; /* XXX */
		[self addSyntax:@"'.*'"	withColor:STRING2_COLOR_IDX andType:SYNTAX_TYPE_REGEXP]; /* XXX */
		[self addSyntax:@"\\$\\w+" withColor:VARTYPE_COLOR_IDX andType:SYNTAX_TYPE_REGEXP];
		[self addSyntax:@"//.*?[\\n|\\r]" withColor:COMMENT_COLOR_IDX andType:SYNTAX_TYPE_REGEXP];
	}
	[self addSyntax:[NSString stringWithFormat:@"\\b%@\\b",EXECUTE_COMMAND] withColor:CONDITION_COLOR_IDX andType:SYNTAX_TYPE_REGEXP];
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
@end
