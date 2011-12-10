#import "m_tabManager.h"
@implementation m_tabManager
@synthesize tabView,goto_window = _goto_window,timer,modal_panel = _modal_panel,modal_tv = _modal_tv,modal_field = _modal_field,e,_status,modal_input = _modal_input,snipplet,signal_popup = _signal_popup;
- (m_tabManager *) init {
	return [self initWithFrame:[[NSApp mainWindow] frame]];
}
- (void) createCodeSnipplets {
	NSMutableArray *a = [NSMutableArray array];
	[a addObject:[NSArray arrayWithObjects:@"c template", @"#include <stdio.h>\n\n//TEXTY_EXECUTE gcc -Wall -o {MYDIR}/{MYSELF_BASENAME_NOEXT} {MYSELF}\nint main(int ac, char *av[]) {\n\n\n\treturn 0;\n}" ,[NSNumber numberWithInt:0],nil]];

	[a addObject:[NSArray arrayWithObjects:@"GCC compile", @"//TEXTY_EXECUTE gcc -Wall -o {MYDIR}/{MYSELF_BASENAME_NOEXT} {MYSELF}" ,[NSNumber numberWithInt:EXECUTE_LINE],nil]];
	[a addObject:[NSArray arrayWithObjects:@"GCC compile and run", @"//TEXTY_EXECUTE gcc -Wall -o {MYDIR}/{MYSELF_BASENAME_NOEXT} {MYSELF} && {MYDIR}/{MYSELF_BASENAME_NOEXT} {NOTIMEOUT}",[NSNumber numberWithInt:EXECUTE_LINE],nil]];
	[a addObject:[NSArray arrayWithObjects:@"GCC compile and GDB", @"//TEXTY_EXECUTE gcc -g3 -Wall -o {MYDIR}/{MYSELF_BASENAME_NOEXT} {MYSELF} && gdb -f -q {MYDIR}/{MYSELF_BASENAME_NOEXT} {NOTIMEOUT}",[NSNumber numberWithInt:EXECUTE_LINE],nil]];

	[a addObject:[NSArray arrayWithObjects:@"{MYSELF}", @"//TEXTY_EXECUTE {MYSELF} {NOTIMEOUT}",[NSNumber numberWithInt:EXECUTE_LINE],nil]];
	[a addObject:[NSArray arrayWithObjects:@"perl {MYSELF}", @"#TEXTY_EXECUTE perl {MYSELF} {NOTIMEOUT}",[NSNumber numberWithInt:EXECUTE_LINE],nil]];	
	[a addObject:[NSArray arrayWithObjects:@"ruby {MYSELF}", @"#TEXTY_EXECUTE ruby {MYSELF} {NOTIMEOUT}",[NSNumber numberWithInt:EXECUTE_LINE],nil]];	
	[a addObject:[NSArray arrayWithObjects:@"sh {MYSELF}", @"#TEXTY_EXECUTE sh {MYSELF} {NOTIMEOUT}",[NSNumber numberWithInt:EXECUTE_LINE],nil]];	
	[a addObject:[NSArray arrayWithObjects:@"rails", @"#TEXTY_EXECUTE http://localhost:3000",[NSNumber numberWithInt:EXECUTE_LINE],nil]];	
	NSString *url = [NSString stringWithFormat:@"http://localhost/~%@/",NSUserName()];
	[a addObject:[NSArray arrayWithObjects:url, [NSString stringWithFormat:@"#TEXTY_EXECUTE %@",url],[NSNumber numberWithInt:EXECUTE_LINE],nil]];	

	self.snipplet = [NSArray arrayWithArray:a];
}
- (m_tabManager *) initWithFrame:(NSRect) frame {
	self = [super init];
	if (self) {
		self.tabView = [[NSTabView alloc] initWithFrame:frame];
		self.tabView.delegate = self;
		[self.tabView setFont:FONT];
		[self.tabView setControlTint:NSClearControlTint];
		self.timer = [NSTimer scheduledTimerWithTimeInterval: 1
					target: self
					selector: @selector(handleTimer:)
					userInfo: nil
					repeats: YES];
		self.e = [[m_exec alloc] init];
		self.e.delegate = self;
		[self createCodeSnipplets];
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
		colorAttr[BRACKET_COLOR_IDX] = [NSDictionary dictionaryWithObject:VARTYPE_COLOR forKey:NSBackgroundColorAttributeName];
		colorAttr[NOBRACKET_COLOR_IDX] = [NSDictionary dictionaryWithObject:BG_COLOR forKey:NSBackgroundColorAttributeName];
		
		self._status = [[m_status alloc] initWithTabManager:self];
		lastColorRange = NSMakeRange(0, 0);
		[self performSelector:@selector(fixModalTextView) withObject:nil afterDelay:0];
		if (![self openStoredURLs]) {
			[self open:nil];
		}
	}
	return self;
}

#pragma mark restore workspace
- (BOOL) openStoredURLs {
	BOOL ret = NO;
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	NSArray *d = [preferences objectForKey:@"openedTabs"];
	for (NSString *f in d) {
		if ([self open:[NSURL fileURLWithPath:f]])
			ret = YES;
	}
	NSString *selected = [preferences objectForKey:@"selectedTab"];
	__block TextVC *exists = nil;
	if (selected) {
		[self walk_tabs:^(TextVC *t) {
			if ([[t.s.fileURL path] isEqualToString:selected]) {
				exists = t;
			}
		}];
		if (exists) {
			[self.tabView selectTabViewItem:exists.tabItem];
		}
	}
	return ret;
}
- (void) storeOpenedURLs {
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	NSMutableArray *opened = [NSMutableArray array];
	[self walk_tabs:^(TextVC *t) {
			[opened addObject:[t.s.fileURL path]];
	}];
	TextVC *t = [self.tabView selectedTabViewItem].identifier;
	[preferences setObject:[NSArray arrayWithArray:opened] forKey:@"openedTabs"];
	[preferences setObject:[t.s.fileURL path] forKey:@"selectedTab"];
}

#pragma mark tabManagement
- (void) goLeft:(id) sender {
	[self.tabView selectTabViewItemAtIndex:[self getTabIndex:DIRECTION_LEFT]];
}
- (void) goRight:(id) sender {
	[self.tabView selectTabViewItemAtIndex:[self getTabIndex:DIRECTION_RIGHT]];
}
- (NSInteger) getTabIndex:(int) direction {
	NSTabViewItem *selected = [self.tabView selectedTabViewItem];
	NSInteger selectedIndex = [self.tabView indexOfTabViewItem:selected];
	NSInteger firstIndex = 0;
	NSInteger lastIndex = [self.tabView numberOfTabViewItems] - 1;
	if (lastIndex == firstIndex)
		return selectedIndex;

	if (direction == DIRECTION_LEFT) {
		if (selectedIndex > 0)
			return selectedIndex - 1;
		return lastIndex;
	} else {
		if (selectedIndex < lastIndex)
			return selectedIndex + 1;
		return 0;
	}
}
- (void) swapTab:(NSInteger) first With:(NSInteger) second {
	NSTabViewItem *f, *s;
	f = [self.tabView tabViewItemAtIndex:first];
	s = [self.tabView tabViewItemAtIndex:second];
	if ([f isEqual:s])
		return;
	[self.tabView removeTabViewItem:f];
	[self.tabView insertTabViewItem:f atIndex:second];
	[self.tabView selectTabViewItemAtIndex:second];
}
- (IBAction)swapRight:(id)sender {
	NSInteger rightIndex = [self getTabIndex:DIRECTION_RIGHT];
	NSInteger selectedIndex = [self.tabView indexOfTabViewItem:[self.tabView selectedTabViewItem]];
	[self swapTab:selectedIndex With:rightIndex];
}
- (IBAction)swapLeft:(id)sender {
	NSInteger leftIndex = [self getTabIndex:DIRECTION_LEFT];
	NSInteger selectedIndex = [self.tabView indexOfTabViewItem:[self.tabView selectedTabViewItem]];
	[self swapTab:selectedIndex With:leftIndex];
}

#pragma mark Open/Save/Close/Goto
- (IBAction)openButton:(id)sender {
	NSOpenPanel *panel	= [NSOpenPanel openPanel];
	NSString *home = NSHomeDirectory();
	[panel setDirectoryURL:[NSURL fileURLWithPath:[home stringByAppendingPathComponent:DEFAULT_OPEN_DIR]]];
	panel.allowsMultipleSelection = YES;
	if ([panel runModal] == NSOKButton) {
		NSArray *files = [panel URLs];;
		for (NSURL *url in files) {
			[self performSelector:@selector(open:) withObject:url afterDelay:0];
		}
	}	

}
- (IBAction)saveButton:(id)sender {
	TextVC *t = [self.tabView selectedTabViewItem].identifier;
	[t save];
}
- (IBAction)saveAsButton:(id)sender {
	TextVC *t = [self.tabView selectedTabViewItem].identifier;
	NSSavePanel *spanel = [NSSavePanel savePanel];
	[spanel setPrompt:@"Save"];
	[spanel setShowsToolbarButton:YES];
	[spanel setDirectoryURL:[t.s.fileURL URLByDeletingLastPathComponent]];
	[spanel setRepresentedURL:[t.s.fileURL URLByDeletingLastPathComponent]];
	[spanel setExtensionHidden:NO];
	[spanel setNameFieldStringValue:[t.s basename]];
	[spanel beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton) {
			[t saveAs:[spanel URL]];
		}
	}];
}

- (IBAction)closeButton:(id)sender {
	TextVC *t = [self.tabView selectedTabViewItem].identifier;
	if ([t is_modified]) {
		NSInteger alertReturn = [t.s fileAlert:t.s.fileURL withMessage:@"WARNING: unsaved data." def:@"Cancel" alternate:@"Close w/o Save" other:@"Save & Close"];
		if (alertReturn == NSAlertOtherReturn) { 		/* Save */
			[t save];
		} else if (alertReturn == NSAlertDefaultReturn) { 	/* Cancel */
			return; 
		}
	}
	/* remove the empty file */
	[t close];
	[self.tabView removeTabViewItem:[self.tabView selectedTabViewItem]];
	if ([[self.tabView tabViewItems] count] == 0) {
		[NSApp terminate: self];
	}
}
- (IBAction)revertToSavedButton:(id)sender {
	TextVC *t = [self.tabView selectedTabViewItem].identifier;
 	[t revertToSaved];
}
- (IBAction)newTabButton:(id)sender {
	[self open:nil];
}
- (IBAction)goto_action:(id)sender {
	NSTextField *field = sender;
	NSString *value = [field stringValue];
	TextVC *t = [self.tabView selectedTabViewItem].identifier;
	[t goto_line:[value integerValue]];	
	[self.goto_window orderOut:nil];
}

- (IBAction)commentSelection:(id)sender {
	NSString *commentSymbol;		
	TextVC *t = [self.tabView selectedTabViewItem].identifier;

	if ([t extIs:[NSArray arrayWithObjects:@"c", @"h",@"m",@"cpp",@"java",nil]]) {
		commentSymbol = @"//";
	} else {
		commentSymbol = @"#";
	}
	
	if ([t eachLineOfSelectionBeginsWith:commentSymbol]) {
		[t insert:commentSymbol atEachLineOfSelectionWithDirection:DIRECTION_LEFT];
	} else {
		[t insert:commentSymbol atEachLineOfSelectionWithDirection:DIRECTION_RIGHT];	
	}
}
- (IBAction)tabSelection:(id)sender {
	TextVC *t = [self.tabView selectedTabViewItem].identifier;
	[t insert:@"\t" atEachLineOfSelectionWithDirection:[sender tag]];	
}
- (IBAction)goto_button:(id)sender {
	if ([self.goto_window isVisible])
		[self.goto_window orderOut:nil];
	else 
		[self.goto_window makeKeyAndOrderFront:nil];
}
- (BOOL) open:(NSURL *) file {
	__block TextVC *o = nil;
	[self walk_tabs:^(TextVC *t) {
		if ([t.s.fileURL isEqualTo:file]) {
			o = t;
		};
	}];
	if (o) {
		NSInteger alertReturn = [o.s fileAlert:file withMessage:@"File is already open, do you want to reload it from disk?" def:@"Cancel" alternate:@"Reload" other:nil];

		if (alertReturn == NSAlertAlternateReturn) {
			[o open:file];
			[self.tabView selectTabViewItem:o.tabItem];
			return YES;
		}
		return NO;
	}
	o = [[TextVC alloc] initWithNibName:@"TextVC" bundle:nil];
	if ([o open:file]) {
		[self.tabView addTabViewItem:o.tabItem];
		[self.tabView selectTabViewItem:o.tabItem];
		return YES;
	}
	return NO;
}
- (IBAction) save_all:(id) sender {
	[self walk_tabs:^(TextVC *t) {
		[t save];
	}];
}
- (void) walk_tabs:(void (^)(TextVC *t)) callback {
	NSArray *a = [self.tabView tabViewItems];
	for (NSTabViewItem *tabItem in a) {
		TextVC *t = tabItem.identifier;
		callback(t);
	}	
}

- (NSApplicationTerminateReply) gonna_terminate {
	[self storeOpenedURLs];
	__block unsigned int have_unsaved = 0;
	[self walk_tabs:^(TextVC *t) {
		if ([t is_modified]) {
			have_unsaved++;;
		}		
	}];
	NSInteger ret = NSTerminateNow;
	if (have_unsaved) {
		/* XXX */
		NSInteger alertReturn = NSRunAlertPanel(@"WARNING: unsaved data.", [NSString stringWithFormat:@"You have unsaved data for %u file%s",have_unsaved,(have_unsaved > 1 ? "s." : ".")] ,@"Cancel", @"Close w/o Save",@"Save & Close");
		if (alertReturn == NSAlertOtherReturn) {
			[self save_all:nil];
			ret = NSTerminateNow;
		} else if (alertReturn == NSAlertDefaultReturn) {
			ret = NSTerminateCancel;
		}
	}
	if (ret == NSTerminateNow) {
		[self stopTask:nil];
	}
	return ret;
}
- (void) encoding_button:(id) sender {
	NSMenuItem *m = sender;
	NSStringEncoding enc = m.tag;
	TextVC *t = [self.tabView selectedTabViewItem].identifier;
	if ([t.s convertTo:enc]) {
		[t reload];
		[t save];
	}
}
- (void) snipplet_button:(id) sender {
	NSMenuItem *m = sender;
	NSInteger idx = m.tag;
	TextVC *t = [self.tabView selectedTabViewItem].identifier;
	NSArray *snip = [snipplet objectAtIndex:idx];
	NSString *value = [NSString stringWithFormat:@"%@\n",[snip objectAtIndex:1]];	
	[t insert:value atLine:[[snip objectAtIndex:2] intValue]];
}
- (void) menuWillOpen:(NSMenu *)menu {
	TextVC *t = [self.tabView selectedTabViewItem].identifier;
	if ([[menu title] isEqualToString:@"diff"]) {
		[menu removeAllItems];
		for (NSString *b in t.s.backups) {
			NSMenuItem *m = [[NSMenuItem alloc] initWithTitle:b action:@selector(diff_button:) keyEquivalent:@""];
			[m setTarget:self];
			[menu addItem:m];		
		}
	} else if ([[menu title] isEqualToString:@"Encoding"]) {
		[menu removeAllItems];
		[menu addItemWithTitle:@"Current Encoding:" action:nil keyEquivalent:@""];
		NSMenuItem *m = [[NSMenuItem alloc] initWithTitle:[t.s currentEncoding] action:@selector(encoding_button:) keyEquivalent:@""];
		[m setTarget:self];
		[menu addItem:m];
		[menu addItem:[NSMenuItem separatorItem]];
		for (NSArray *a in t.s.encodings) {
			NSString *title = [a objectAtIndex:0];
			m = [[NSMenuItem alloc] initWithTitle:title action:@selector(encoding_button:) keyEquivalent:@""];
			[m setTag:[[a objectAtIndex:1] intValue]];
			[m setTarget:self];
			[menu addItem:m];
			[m setEnabled:YES];	
		}
	} else if ([[menu title] isEqualToString:@"Snipplets: TEXTY_EXECUTE"]) {
		[menu removeAllItems];
		for (NSArray *a in snipplet) {
			NSString *title = [a objectAtIndex:0];
			NSMenuItem *m = [[NSMenuItem alloc] initWithTitle:title action:@selector(snipplet_button:) keyEquivalent:@""];
			[m setTag:[snipplet indexOfObject:a]];
			[m setTarget:self];
			[menu addItem:m];
			[m setEnabled:YES];	
		}	
	}
}
- (void) menuDidClose:(NSMenu *)menu {
}


#pragma mark ExecutePanelWindow

- (IBAction)run_button:(id)sender {
	TextVC *t = [self.tabView selectedTabViewItem].identifier;
	NSString *cmd = [t get_execute_command];
	if (!cmd) {
		if (![self.modal_panel isKeyWindow]) {
			[self displayModalTV];
		}
		return;
	}
	
	[t save];

	cmd = [cmd stringByReplacingOccurrencesOfString:@"{MYSELF}" withString:[t.s.fileURL path]];
	cmd = [cmd stringByReplacingOccurrencesOfString:@"{MYSELF_BASENAME}" withString:[t.s basename]];
	cmd = [cmd stringByReplacingOccurrencesOfString:@"{MYSELF_BASENAME_NOEXT}" withString:[[t.s basename] stringByDeletingPathExtension]];
	cmd = [cmd stringByReplacingOccurrencesOfString:@"{MYDIR}" withString:[[t.s.fileURL path] stringByDeletingLastPathComponent]];
	int timeout = DEFAULT_EXECUTE_TIMEOUT;  
	if ([cmd rangeOfString:@"{NOTIMEOUT}"].location != NSNotFound) {
		timeout = 0;
		cmd = [cmd stringByReplacingOccurrencesOfString:@"{NOTIMEOUT}" withString:@""];
	}
		
	if ([cmd rangeOfString:@"^\\s*?http(s)?://" options:NSRegularExpressionSearch].location != NSNotFound) {
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[cmd stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]]];
		return;
	}

	if (![cmd isEqualToString:self.e._command]) { /* if we are trying to run different command alert */
		if ([self AlertIfTaskIsRunning] == NO)
			return;
	}
	[e execute:cmd withTimeout:timeout];
	[self displayModalTV];
}

- (BOOL) AlertIfTaskIsRunning {
	if ([self.e.task isRunning]) {
		NSString *running = [NSString stringWithFormat:@"CURRENT TASK:\n%@",self.e._command];
		NSInteger ret = NSRunAlertPanel(@"There is a task running.", running , @"Close", @"Stop Task",nil);
		if (ret != NSAlertDefaultReturn) {
			[self stopTask:nil];
			sleep(1); /* wait for terminate */
			return YES;
		}
		return NO;
	}
	return YES;
}
- (void) diff_button:(id) sender {
	if ([self AlertIfTaskIsRunning] == NO)
		return;
	NSMenuItem *item = sender;
	TextVC *t = [self.tabView selectedTabViewItem].identifier;
	NSURL *a = t.s.fileURL;
	NSURL *b = [NSURL fileURLWithPath:[item title]];
	if ([e diff:a against:b]) {
		[self displayModalTV];
	}
}

- (void) displayModalTV {
	[TextVC scrollEnd:self.modal_tv];
	[self.modal_panel makeKeyAndOrderFront:nil];
	[self.modal_input becomeFirstResponder];
}
- (IBAction)sendToTask:(id)sender {
	[e write:[[sender stringValue] stringByAppendingString:@"\n"]];
}
- (IBAction)restartTask:(id)sender {
	[e restart];
	[self.modal_input becomeFirstResponder];
}
- (IBAction)clearTV:(id)sender {
	[self.modal_tv setString:@""];
	lastColorRange = NSMakeRange(0, 0);
	[self.modal_input becomeFirstResponder];
}
- (IBAction)stopTask:(id)sender {
	[self.e terminate];
	[self.modal_input becomeFirstResponder];
}
- (IBAction)showRunBuffer:(id)sender {
	[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
	[self displayModalTV];
}
- (void) taskAddExecuteText:(NSString *)text {
	NSRange range = { [[self.modal_tv string] length], 0 };
	[self.modal_tv setSelectedRange: range];
	[self.modal_tv replaceCharactersInRange: range withString:text];
	[TextVC scrollEnd:self.modal_tv];
}
- (void) taskDidStart {
	[self taskAddExecuteText:[NSString stringWithFormat:@"\nSTART: [%@] TASK(timeout: %@): %@\n",e._startTime,(e._timeout == 0 ? @"NOTIMEOUT" : [NSString stringWithFormat:@"%d",e._timeout]),e._command]];
	[self.modal_input setEnabled:YES];
	[self.signal_popup setEnabled:YES];
	[self.modal_field setStringValue:[NSString stringWithString:e._command]];
}
- (void) taskDidTerminate {
	NSString *timedOut = @"";
	if (e._terminated) {
		timedOut = @" [TOUT]";
	} 
	NSDate *now = [NSDate date];
	NSTimeInterval diff = [now timeIntervalSinceDate:e._startTime];
	[self taskAddExecuteText:[NSString stringWithFormat:@"\nEND : [%@ - took: %llfs] TASK(RC: %d%@): %@\n",now,diff,e._rc,timedOut,e._command]];
	[self.modal_input setEnabled:NO];

	NSInteger max = NSMaxRange(lastColorRange);
	NSInteger len = [[self.modal_tv string] length];
	NSRange range = {0 ,max};
	[[self.modal_tv textStorage] addAttribute:NSForegroundColorAttributeName value:COMMENT_COLOR range:range];
	range = NSMakeRange(max,len - max);
	[[self.modal_tv textStorage] addAttribute:NSForegroundColorAttributeName value:PREPROCESS_COLOR range:range];
	
	lastColorRange = range;
	[self.signal_popup setEnabled:NO];
	[self.modal_input setEnabled:NO];
}
- (IBAction)taskSendSignal:(id) sender {
	[e sendSignal:(int) [sender tag]];
}
- (void) fixModalTextView {
	[self.modal_tv setHidden:NO];
	[self.modal_tv setFont:FONT];
	[self.modal_tv setTextColor:TEXT_COLOR];
	NSMutableDictionary *selected = [[self.modal_tv selectedTextAttributes] mutableCopy];
	[selected setObject:BG_COLOR forKey:NSForegroundColorAttributeName];
	[selected setObject:TEXT_COLOR forKey:NSBackgroundColorAttributeName];
	[self.modal_tv setSelectedTextAttributes:selected];
	[self.modal_tv setBackgroundColor:BG_COLOR];
	[self.modal_tv setInsertionPointColor:CURSOR_COLOR];
//	[self.modal_panel setLevel: NSNormalWindowLevel]; /* maybe its better to be always on top */
}

#pragma mark Timer
- (void) handleTimer:(id) sender {
	[self performSelectorOnMainThread:@selector(signal:) withObject:self waitUntilDone:YES];
}

- (void) signal:(id) sender {
	if ([self.e.task isRunning]) {
		[_status enable];
	} else {
		[_status disable];
	}
	if ([NSApp isActive]) {
		[self walk_tabs:^(TextVC *t) {
			[t signal];
		}];
	}
}

@end
