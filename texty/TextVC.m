#import "TextVC.h"
#define L_LOCKED	0
#define L_MODIFIED	1
#define L_DEFAULT	2
#define L_UNDEFINED 3
@implementation TextVC
@synthesize tabItem,s,parser,box,text,scroll,ewc;
- (NSRange) fullRange {
	NSRange range = {0,[[text string] length]};
	return range;
}

+ (void) scrollEnd:(NSTextView *) tv {
	NSRange range = { [[tv string] length], 0 };
	[tv scrollRangeToVisible: range];
}

- (void) signal {
	if (need_to_autosave) {
		if (time(NULL) - autosave_ts > [Preferences defaultAutoSaveInterval]) {
			if (s.temporary)
				[s migrate:s.fileURL withString:[text string] autosaving:YES];
			else 
				[s autosave:NO];
			autosave_ts = time(NULL);
			need_to_autosave = NO;
		}
	}
	if (something_changed) {
		if ([self is_modified]) {
			[self label:L_MODIFIED];
			need_to_autosave = YES;
		} else {
			[self label:L_DEFAULT];
		}
		something_changed = NO;
	}

	if ([s same_as_disk] == NO) 
		if (locked == NO)
			[self lockText];
}
- (void) label:(int) type {
	switch(type) {
	case L_MODIFIED:
		tabItem.label = [NSString stringWithFormat:@"%@ *",[s basename]];
		break;
	case L_LOCKED:
		tabItem.label = [NSString stringWithFormat:@"%@ *Locked*",[s basename]];
		break;
	case L_DEFAULT:
		tabItem.label = [NSString stringWithFormat:@"%@",[s basename]];			
		break;
	case L_UNDEFINED:
	default:
		tabItem.label = @"aaaaa :) should never happen";
	}
}
- (void) lockText {
	NSInteger alert = [s fileAlert:s.fileURL withMessage:@"The File was modified by someone else\nReload or Overwrite it." def:@"Cancel" alternate:@"Reload" other:@"Overwrite"];
	if (alert == NSAlertAlternateReturn) {
		if ([self open:self.s.fileURL])
			return;
	} else if (alert == NSAlertOtherReturn) {
		if ([self save])
			return;
	}
	[self label:L_LOCKED];
	locked = YES;
	[text setBackgroundColor:[NSColor darkGrayColor]];
	[text setEditable:NO];	
}
- (id) initWithFrame:(NSRect) frame {
    self = [super init];
    if (self) {
		self.s = [[m_Storage alloc] init];
		self.parser = [[m_parse alloc] init];
		self.tabItem  = [[NSTabViewItem alloc] initWithIdentifier:self];
		self.scroll = [[NSScrollView alloc] initWithFrame:frame];
		NSSize char_size = [[NSString stringWithString:@" "] sizeWithAttributes: [NSDictionary dictionaryWithObject:FONT forKey: NSFontAttributeName]];

		NSSize contentSize = [self.scroll contentSize];
		[scroll setBorderType:NSNoBorder];
		[scroll setHasVerticalScroller:YES];
		[scroll setHasHorizontalScroller:NO];
		[scroll setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
		tabItem.view = scroll;
		self.text = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, contentSize.width, contentSize.height)];
		[text setMinSize:NSMakeSize(0.0, contentSize.height)];
		[text setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
		text.delegate = self;
		text.textStorage.delegate = self;		
		[text setVerticallyResizable:YES];
		[text setHorizontallyResizable:YES];
		[text setAutoresizingMask:NSViewWidthSizable];
		text.allowsUndo = YES;
		[text setUsesRuler:NO];
		text.usesFindBar = YES;
		[text.textStorage setParagraphs:nil];
		[text setAutomaticDashSubstitutionEnabled:NO];
		[text setAutomaticQuoteSubstitutionEnabled:NO];
		[text setAutomaticLinkDetectionEnabled:NO];
		[text setAutomaticSpellingCorrectionEnabled:NO];
		[text setAutomaticTextReplacementEnabled:NO];
		[text setImportsGraphics:NO];
		NSMutableDictionary *selected = [[text selectedTextAttributes] mutableCopy];
		NSMutableParagraphStyle *para = [[NSMutableParagraphStyle alloc] init];
		[para setLineSpacing:NSLineBreakByTruncatingHead];
		[para setDefaultTabInterval:(char_size.width * 4)];
		[para setTabStops:[NSArray array]];			
		[text setDefaultParagraphStyle:para];
		[text setTypingAttributes:[NSDictionary dictionaryWithObject:para forKey:NSParagraphStyleAttributeName]];
		[text setFont:FONT];
		[text setRichText:NO];
		[text setTextColor:TEXT_COLOR];
		[text setCanDrawConcurrently:NO];
		[selected setObject:BG_COLOR forKey:NSForegroundColorAttributeName];
		[selected setObject:TEXT_COLOR forKey:NSBackgroundColorAttributeName];
		[text setSelectedTextAttributes:selected];
		[text setBackgroundColor:BG_COLOR];
		[text setInsertionPointColor:CURSOR_COLOR];
		NSRect boxRect = [text frame];
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
		[text addSubview:box];
		locked = NO;
		[self label:L_UNDEFINED];
		[self.scroll setDocumentView:self.text];
    }
    return self;
}
- (void) responder {
	[text setSelectedRange:NSMakeRange(0, 0)];
	[scroll becomeFirstResponder];
}
- (void) syntax_reload {
	m_range *r = [[m_range alloc] init];
	r._range = NSMakeRange(0, [self strlen]);
	r._change = [self strlen];
	[parser initSyntax:[[s basename] pathExtension] box:box];
	[parser parse:r inTextView:text];
}
- (BOOL) saveAs:(NSURL *) to {
	if ([s migrate:to withString:[text string] autosaving:NO]) {
		[self syntax_reload];
		[self label:L_DEFAULT];
		return YES;
	}
	return NO;
}
- (BOOL) save {
	return [self saveAs:s.fileURL];
}
- (void) revertToSaved {
	[text setString:s.data];
}
- (BOOL) is_modified {
	return ![[text string] isEqualToString:s.data];
}
- (void) goto_line:(NSInteger) want_line {
	NSRange area = [m_range rangeOfLine:want_line inString:[text string]];
	if (area.location != NSNotFound) {
		[text setSelectedRange: area];
		[text scrollRangeToVisible: area];
	}
}
- (void) reload {
	[text setString:s.data];
	[self label:L_DEFAULT];
	[self performSelector:@selector(responder) withObject:self afterDelay:0];
	[self syntax_reload];

}
- (BOOL) open:(NSURL *)file {
	if ([s open:file]) {
		[self reload];
		return YES;
	}
	return NO;
}

- (NSInteger) strlen {
	return [[text string] length];
}

- (BOOL) extIs:(NSArray *) ext {
	NSString *fileExt = [s.fileURL pathExtension];
	for (NSString *str in ext)
		if ([fileExt isEqualToString:str])
			return YES;
	return NO;
}

- (void) parse:(m_range *) range {
	[parser parse:range inTextView:text];
}

- (void) textStorageWillProcessEditing:(NSNotification *)notification {
	NSTextStorage *ts = [notification object];
	if ([ts editedMask] & NSTextStorageEditedCharacters) {
		m_range *range = [[m_range alloc] init];
		NSInteger change = [ts changeInLength];
		NSRange editted = [ts editedRange];
		range._change = change;
		range._range = editted;
		something_changed = YES;
		[self performSelector:@selector(parse:) withObject:range afterDelay:0];		
	}
}
- (void) textViewDidChangeSelection:(NSNotification *)notification {
	if (bracketColored)
		[parser color:[self fullRange] withColor:NOBRACKET_COLOR_IDX inTextView:text];		
	bracketColored = [self colorBracket];
	
}
- (NSArray *) textView:(NSTextView *)textView completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index {
	NSString *part = [[textView string] substringWithRange:charRange];
	return [parser hash_to_array:part];
}
- (BOOL) textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
	if (commandSelector ==  @selector(insertNewline:)) {
		NSString *spaces = @"";
		if (parser.autoindent) {
			NSString *string = [textView string];
			NSRange selected = [textView selectedRange];
			NSRange paraRange = [string paragraphRangeForRange:selected];
			if (paraRange.location != NSNotFound && paraRange.location != selected.location && paraRange.length > 0) {
				NSInteger i,max;
				max = NSMaxRange(paraRange);
				paraRange =NSMakeRange(paraRange.location, 0);
				for (i=paraRange.location;i<max;i++) {
					unichar c = [string characterAtIndex:i];
					if (c == ' ' || c == '\t') 
						paraRange.length++;
					else
						break;
				}
				spaces = [string substringWithRange:paraRange];
			}
		}
		something_changed = YES;
		[textView insertText:[NSString stringWithFormat:@"\n%@",spaces]];
		return YES;
	}
	return NO;
}

- (NSString *) get_line:(NSInteger) lineno {
	return [parser get_line:lineno inTextView:text];
}
- (NSString *) get_execute_command {
	return [parser get_execute_command:text];
}
- (void) insert:(NSString *)value atLine:(NSInteger) line {
	NSInteger lineCount = [m_range numberOfLines:[text string]];
	NSInteger required = lineCount < line ? line - lineCount : 0;
	if (required > 0) {
		NSMutableString *enter = [NSMutableString string];
		for (int i=0;i<=required;i++) {
			[enter appendFormat:@"\n"];
		}
		[text replaceCharactersInRange:NSMakeRange(0, [self strlen]) withString:[NSString stringWithFormat:@"%@%@",[text string],enter]];
			
	}
	NSRange area = [m_range rangeOfLine:line inString:[text string]];
	if (area.location == NSNotFound) {
		[text insertText:value];
	} else {
		NSString *update = [NSString stringWithFormat:@"%@%@",value,[[text string] substringWithRange:area]];
		[text replaceCharactersInRange:area withString:update];
	}
	something_changed = YES;
}

- (BOOL) eachLineInRange:(NSRange) range beginsWith:(NSString *) symbol {
	if (range.location == NSNotFound)
		return NO;
		
	NSString *string = [text string];
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

- (void) insert:(NSString *) value atEachLineOfSelectionWithDirection:(NSInteger) direction {
	NSRange selection,selected = [text selectedRange];
	if (selected.length < 2)
		return;
	NSString *remove = value;
	if ([value isEqualToString:@"\t"]) {
		remove = @"\\s";
	}
		
	if (direction == DIRECTION_LEFT && ![self eachLineOfSelectionBeginsWith:remove]) 
		return;
	
		
	NSString *string = [text string];
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
		[text replaceCharactersInRange:selection withString:update];
		selection = [string paragraphRangeForRange:updatedRange];
		[text setSelectedRange:selection];
		something_changed = YES;
	}
}

- (BOOL) eachLineOfSelectionBeginsWith:(NSString *)symbol {
	NSRange selection = [[text string] paragraphRangeForRange:[text selectedRange]];
	return [self eachLineInRange:selection beginsWith:symbol];
}
- (BOOL) colorPrev:(unichar) opens ends:(unichar) ends inRange:(NSRange) range{
	if (range.location < 1 || range.location == NSNotFound) 
		return NO;
	
	NSInteger open,pos,foundone;
	open = foundone = 0;
	NSString *string = [text string];
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
				[parser color:NSMakeRange(pos,1)  withColor:BRACKET_COLOR_IDX inTextView:text];		
				[parser color:range  withColor:BRACKET_COLOR_IDX inTextView:text];		
				return YES;
			}
			break;
		}
	}
	return NO;
}

- (BOOL) colorBracket {
	NSString *string = [text string];
	NSRange selected = [text selectedRange];
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
	}
	return NO;
}

- (void) run_diff_against:(NSURL *) b {
	NSURL *a = s.fileURL;
	[self run:[m_exec diff:a against:b] withTimeout:0];
}
- (void) run_self {
	NSString *cmd = [self get_execute_command];
	if (!cmd) {
		cmd = [Preferences defaultCommand];
	}
	[self save];
	cmd = [cmd stringByReplacingOccurrencesOfString:@"{MYSELF}" withString:[s.fileURL path]];
	cmd = [cmd stringByReplacingOccurrencesOfString:@"{MYSELF_BASENAME}" withString:[s basename]];
	cmd = [cmd stringByReplacingOccurrencesOfString:@"{MYSELF_BASENAME_NOEXT}" withString:[[s basename] stringByDeletingPathExtension]];
	cmd = [cmd stringByReplacingOccurrencesOfString:@"{MYDIR}" withString:[[s.fileURL path] stringByDeletingLastPathComponent]];
	int timeout = DEFAULT_EXECUTE_TIMEOUT;  
	if ([cmd rangeOfString:@"{NOTIMEOUT}"].location != NSNotFound) {
		timeout = 0;
		cmd = [cmd stringByReplacingOccurrencesOfString:@"{NOTIMEOUT}" withString:@""];
	}
	
	if ([cmd rangeOfString:@"^\\s*?http(s)?://" options:NSRegularExpressionSearch].location != NSNotFound) {
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[cmd stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]]];
		return;
	}
	[self run:cmd withTimeout:timeout];
}

- (void) run: (NSString *) cmd withTimeout:(int) timeout {
	if (!ewc)
		self.ewc = [[ExecuteWC alloc] init];
	[ewc execute:cmd withTimeout:timeout];
	[ewc.window makeKeyAndOrderFront:nil];
}

- (void) close {
	[s close];
	[ewc.e terminate];
	self.ewc = nil;
}
@end
