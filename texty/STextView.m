#import "STextView.h"

@implementation STextView
@synthesize _box,_auto_indent,um,parser;
- (STextView *) initWithFrame:(NSRect) frame {
	self = [super initWithFrame:frame];
	if (self) {
		NSSize char_size = [[NSString stringWithString:@" "] sizeWithAttributes: [NSDictionary dictionaryWithObject:FONT forKey: NSFontAttributeName]];	
		[self setMinSize:NSMakeSize(0.0, frame.size.height)];
		[self setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
		[self setVerticallyResizable:YES];
		[self setHorizontallyResizable:YES];
		[self setAutoresizingMask:NSViewWidthSizable];
		self.allowsUndo = YES;
		[self setUsesRuler:NO];
		self.usesFindBar = YES;
		[self.textStorage setParagraphs:nil];
		[self setAutomaticDashSubstitutionEnabled:NO];
		[self setAutomaticQuoteSubstitutionEnabled:NO];
		[self setAutomaticLinkDetectionEnabled:NO];
		[self setAutomaticSpellingCorrectionEnabled:NO];
		[self setAutomaticTextReplacementEnabled:NO];
		[self setImportsGraphics:NO];
		NSMutableDictionary *selected = [[self selectedTextAttributes] mutableCopy];
		NSMutableParagraphStyle *para = [[NSMutableParagraphStyle alloc] init];
		[para setLineSpacing:NSLineBreakByTruncatingHead];
		[para setDefaultTabInterval:(char_size.width * 8)];
		[para setTabStops:[NSArray array]];			
		[self setDefaultParagraphStyle:para];
		[self setTypingAttributes:[NSDictionary dictionaryWithObject:para forKey:NSParagraphStyleAttributeName]];
		[self setFont:FONT];
		[self setRichText:NO];
		[self setTextColor:TEXT_COLOR];
		[self setCanDrawConcurrently:NO];
		[selected setObject:BG_COLOR forKey:NSForegroundColorAttributeName];
		[selected setObject:TEXT_COLOR forKey:NSBackgroundColorAttributeName];
		[self setSelectedTextAttributes:selected];
		[self setBackgroundColor:BG_COLOR];
		[self setInsertionPointColor:CURSOR_COLOR];
		NSRect boxRect = frame;
		boxRect.size.width = 1;
		boxRect.origin.y = 0;
		boxRect.origin.x +=  char_size.width * 80;
		self._box = [[NSBox alloc] initWithFrame:boxRect];
		[_box setBoxType:NSBoxCustom];
		_box.fillColor = [NSColor clearColor];
		_box.borderType =  NSLineBorder;
		_box.borderColor = LINE_80_COLOR;
		[_box setTitlePosition:NSNoTitle];
		[_box setAutoresizingMask:NSViewHeightSizable];
		[_box setTransparent:NO];
		[_box setHidden:YES];
		self.parser = [[m_parse alloc] init];
		self.um = [[NSUndoManager alloc] init];
		[self addSubview:_box];
	}
	return self;
}
- (void) selectMove:(int) spots {
	NSRange selected = [self selectedRange];
	if (spots < 0) {
		spots = -spots;
		if (selected.location >= spots) 
			selected.location -= spots;
	} else {
		if ([[self string] length] >= spots)
			selected.location += spots;
	}
	[self setSelectedRange:selected];
}
- (BOOL) colorPrev:(unichar) opens ends:(unichar) ends inRange:(NSRange) range{
	if (range.location < 1 || range.location == NSNotFound) 
		return NO;
	
	NSInteger open,pos,foundone;
	open = foundone = 0;
	NSString *string = [self string];
	range.location--;
	range.length=1;
	for (pos = range.location; pos >= 0 ; pos--) {
		unichar c = [string characterAtIndex:pos];
		if (c == ends) {
			open++;
			foundone++;
		}
		if (c == opens)
			open--;
		if (open == 0) {
			if (foundone) {
				[self showFindIndicatorForRange:NSMakeRange(pos,1)];
				return YES;
			}
			break;
		}
	}
	return NO;
}

- (BOOL) colorBracket {
	NSString *string = [self string];
	NSRange selected = [self selectedRange];
	if (selected.length > 0 || selected.location < 1)
		return NO;
		
	unichar cursor = (selected.location != NSNotFound && selected.location > 0) ? [string characterAtIndex:selected.location-1] : 0;
	switch (cursor) {
	case '}':
		return [self colorPrev:'{' ends:'}' inRange:selected];
	case ')':
		return [self colorPrev:'(' ends:')' inRange:selected];
	case ']':
		return [self colorPrev:'[' ends:']' inRange:selected];
	break;
	case '>':
		return [self colorPrev:'<' ends:'>' inRange:selected];
	break;
	}
	return NO;
}



- (NSRange) currentLine {
	NSString *string = [self string];
	NSRange selected = [self selectedRange];
	NSInteger i;
	i = (selected.location > 0) ? selected.location - 1 : 0;
	for (;i>0;i--) {
		unichar c = [string characterAtIndex:i];
		if (c == '\n' || c == '\r')
			break;
	}
	return NSMakeRange(i, selected.location - i);
}
- (BOOL) eachLineOfSelectionBeginsWith:(NSString *)symbol {
	NSRange selection = [[self string] paragraphRangeForRange:[self selectedRange]];
	return [self eachLineInRange:selection beginsWith:symbol];
}


- (BOOL) eachLineInRange:(NSRange) range beginsWith:(NSString *) symbol {
	if (range.location == NSNotFound)
		return NO;
		
	NSString *string = [self string];
	__block BOOL ret = YES;
	[string enumerateSubstringsInRange:range options:NSStringEnumerationByLines usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
		if ([substring length] > 0) {
			NSRange f = [substring rangeOfString:[NSString stringWithFormat:@"^%@",symbol] options:NSRegularExpressionSearch];
			if (f.location == NSNotFound) {
				*stop = YES;
				ret = NO;
			}
		}
	}];
	return ret;
}

- (NSRange) rangeOfLine:(NSInteger) requested_line {
	NSString *s = [self string];
	NSUInteger total_len = [s length];
	NSUInteger total_lines = 0, i;
	unichar c;
	for (i=0;i<total_len;i++) {
		c = [s characterAtIndex:i];
		if (c == '\n' || c == '\r') {
			if (++total_lines >= requested_line)
				break;
			
		}
	}
	if (total_lines != requested_line) {
		return NSMakeRange(NSNotFound, 0);
	}
	NSRange area = [s paragraphRangeForRange:NSMakeRange(i, 0)];
	return area;
}

- (NSInteger) numberOfLines {
	__block NSUInteger total_lines = 1;
	[[self string] enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
		total_lines++;
	}];
	return total_lines;
}

- (void) insertAtBegin:(NSString *) value {
	[self replaceCharactersInRange:NSMakeRange(0, 0) withString:value];
}

- (void) insert:(NSString *) value atEachLineOfSelectionWithDirection:(NSInteger) direction {
	NSRange selection,selected = [self selectedRange];
	NSString *remove = value;
	if ([value isEqualToString:@"\t"]) {
		remove = @"\\s";
	}
	
	if (direction == DIRECTION_LEFT && ![self eachLineOfSelectionBeginsWith:remove]) 
		return;
			
	NSString *string = [self string];
	NSInteger valueLen = [value length];		
	selection = [string paragraphRangeForRange:selected];
	NSMutableString *update = [NSMutableString string];
	__block NSRange updatedRange = selection;
	if (selection.location != NSNotFound) {
		[string enumerateSubstringsInRange:selection options:NSStringEnumerationByLines usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
			if (direction == DIRECTION_RIGHT) {
				updatedRange.length += valueLen;
				[update appendFormat:@"%@%@\n",value,substring];
			} else {
				NSRange f = [substring rangeOfString:[NSString stringWithFormat:@"^%@",remove] options:NSRegularExpressionSearch];
				if (f.location != NSNotFound) {
					updatedRange.length -= f.length;
					[update appendFormat:@"%@\n",[substring stringByReplacingCharactersInRange:f withString:@""]];
				} else {
					[update appendFormat:@"%@\n",substring];
				}
			}
		}];
		
		[self replaceCharactersInRange:selection withString:update];
		selection = [string paragraphRangeForRange:updatedRange];
		[self setSelectedRange:selection];
	}
}
//- (void) replaceCharactersInRange:(NSRange)range withString:(NSString *)aString {
//	[super replaceCharactersInRange:range withString:aString];
//}
//- (void) paste:(id)sender {
//	[super paste:sender];
//}
//- (void) insertText:(id)insertString {
//	[super insertText:insertString];
//}
- (NSUndoManager *) undoManager {
	return self.um;
}

- (void) keyDown:(NSEvent *)theEvent {
	int modified = 0;
	unichar c = [[theEvent characters] characterAtIndex:0];
	switch (c) {
	case '\n':
	case '\r':
		{
			NSRange paraRange = [self currentLine];
			NSString *string = [self string];
			NSString *spaces = @"";
			NSRange spaceRange = [string rangeOfString:@"^\\s+" options:NSRegularExpressionSearch|NSRegularExpressionAnchorsMatchLines range:paraRange];
			if (spaceRange.location != NSNotFound)
				spaces = [[string substringWithRange:spaceRange] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
			[self insertText:[NSString stringWithFormat:@"\n%@",spaces]];
			modified = 1;
		}			
	break;
	case '{':
		[self insertText:@"{  }"]; 
		[self selectMove:-2];
		modified = 1;
	break;
	case '(':
		[self insertText:@"(  )"];
		[self selectMove:-2];
		modified = 1;
	break;
	case '"':
		[self insertText:@"\"  \""];
		[self selectMove:-2];
		modified = 1;
	break;
	case '\'':
		[self insertText:@"'  '"];
		[self selectMove:-2];
		modified = 1;
	break;
	case '[':
		[self insertText:@"[  ]"];
		[self selectMove:-2];			
		modified = 1;
	break;
	}
	if (!modified) {
		[super keyDown:theEvent];
		[self delayedParse];
		/* XXX */
		switch (c) {
			case NSRightArrowFunctionKey:
			case NSUpArrowFunctionKey:
			case NSLeftArrowFunctionKey:
			case NSDownArrowFunctionKey:
				[self colorBracket];
			break;				
		}
	}
	
}

- (void)showFindIndicatorForRange:(NSRange)charRange {
	[super showFindIndicatorForRange:charRange];
}

- (NSRange) visibleRange {
    NSRect visibleRect = [self visibleRect];
    NSLayoutManager *lm = [self layoutManager];
    NSTextContainer *tc = [self textContainer];
    
    NSRange glyphVisibleRange = [lm glyphRangeForBoundingRect:visibleRect inTextContainer:tc];;
    NSRange charVisibleRange = [lm characterRangeForGlyphRange:glyphVisibleRange  actualGlyphRange:nil];
    return charVisibleRange;
}

- (void) clearColors:(NSRange) area{	
	NSLayoutManager *lm = [[self.textStorage layoutManagers] objectAtIndex: 0];
	[lm setTemporaryAttributes:colorAttr[TEXT_COLOR_IDX] forCharacterRange:area];
}

- (void) color:(NSRange) range withColor:(unsigned char) color{
	NSLayoutManager *lm = [[self.textStorage layoutManagers] objectAtIndex: 0];
	[lm setTemporaryAttributes:colorAttr[color] forCharacterRange:range];
}
- (void) delayedParse {
	[parser parse:self];
}
- (NSArray *) completionsForPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index {
	NSString *part = [[self string] substringWithRange:charRange];
	return [parser hash_to_array:part];
}
@end
