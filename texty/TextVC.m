#import "TextVC.h"
#define L_LOCKED	0
#define L_MODIFIED	1
#define L_DEFAULT	2
#define L_UNDEFINED 3
@implementation TextVC
@synthesize tabItem,s,parser,box;

+ (void) scrollEnd:(NSTextView *) tv {
	NSRange range = { [[tv string] length], 0 };
	[tv scrollRangeToVisible: range];
}

- (void) signal {
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
	if (alert == NSAlertOtherReturn) {
		if ([self open:self.s.fileURL])
			return;
	} else if (alert == NSAlertAlternateReturn) {
		if ([self save])
			return;
	}
	[self label:L_LOCKED];
	locked = YES;
	[text setBackgroundColor:[NSColor darkGrayColor]];
	[text setEditable:NO];	
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		self.s = [[m_Storage alloc] init];
		self.parser = [[m_parse alloc] init];
		self.tabItem  = [[NSTabViewItem alloc] initWithIdentifier:self];
		tabItem.view = self.view;
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
		[para setDefaultTabInterval:36.];
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
		[text addSubview:box];
		locked = NO;
		[self label:L_UNDEFINED];
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
	if ([s migrate:to withString:[text string]]) {
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

- (void) clearColors:(NSRange) area {	
	NSLayoutManager *lm = [[text.textStorage layoutManagers] objectAtIndex: 0];
	[lm setTemporaryAttributes:colorAttr[TEXT_COLOR_IDX] forCharacterRange:area];
}

- (void) color:(NSRange) range withColor:(unsigned char) color {
	NSLayoutManager *lm = [[text.textStorage layoutManagers] objectAtIndex: 0];
	[lm setTemporaryAttributes:colorAttr[color] forCharacterRange:range];
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
		[text replaceCharactersInRange:NSMakeRange(0, [[text string] length]) withString:[NSString stringWithFormat:@"%@%@",[text string],enter]];
			
	}
	NSRange area = [m_range rangeOfLine:line inString:[text string]];
	if (area.location == NSNotFound) {
		[text insertText:value];
	} else {
		NSString *update = [NSString stringWithFormat:@"%@%@",value,[[text string] substringWithRange:area]];
		[text replaceCharactersInRange:area withString:update];
	}
}
- (void) insert:(NSString *) value atEachLineOfSelectionWithDirection:(NSInteger) direction {
	NSRange selection,selected = [text selectedRange];
	if (selected.length < 2)
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
				NSRange f = [substring rangeOfString:[NSString stringWithFormat:@"^%@",value] options:NSRegularExpressionSearch];
				if (f.location != NSNotFound) {
					updatedRange.length -= valueLen;
					[update appendFormat:@"%@\n",[substring stringByReplacingCharactersInRange:f withString:@""]];
				} else {
					[update appendFormat:@"%@\n",substring];
				}
			}
		}];
		[text replaceCharactersInRange:selection withString:update];
		selection = [string paragraphRangeForRange:updatedRange];
		[text setSelectedRange:selection];
	}
}
@end
