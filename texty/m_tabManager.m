#import "m_tabManager.h"
@implementation m_tabManager
@synthesize tabView,goto_window = _goto_window,timer,snipplet;
#define CURRENT(__t) 	TextVC *__t = [self.tabView selectedTabViewItem].identifier;

- (m_tabManager *) init {
	return [self initWithFrame:[[NSApp mainWindow] frame]];
}
- (void) createCodeSnipplets {
	NSMutableArray *a = [NSMutableArray array];
	[a addObject:[NSArray arrayWithObjects:@"c template", @"#include <stdio.h>\n\nint main(int ac, char *av[]) {\n\n\n\treturn 0;\n}" ,[NSNumber numberWithInt:0],nil]];

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
		
		if (![self openStoredURLs]) {
			[self open:nil];
		}
	}
	return self;
}
- (void) tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
	CURRENT(t);
	[t.text delayedParse];
}
#pragma mark restore workspace
- (BOOL) openStoredURLs {
	BOOL ret = NO;
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	NSArray *d = [preferences objectForKey:@"openedTabs"];
	for (NSString *f in d) {
		if ([m_Storage fileExists:f]) {
			if ([self open:[NSURL fileURLWithPath:f]])
				ret = YES;
		}
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
	CURRENT(t);	
	[preferences setObject:[NSArray arrayWithArray:opened] forKey:@"openedTabs"];
	[preferences setObject:[t.s.fileURL path] forKey:@"selectedTab"];
}

#pragma mark tabManagement
- (IBAction) selectTabAtIndex:(id) sender {
	NSInteger index = [sender tag];
	NSInteger max = [self.tabView.tabViewItems count];
	if (index >= 0 && max > 0 && index <= (max - 1)) {
		[self.tabView selectTabViewItemAtIndex:index];
	}
}
- (IBAction) goLeft:(id) sender {
	[self.tabView selectTabViewItemAtIndex:[self getTabIndex:DIRECTION_LEFT]];
}
- (IBAction) goRight:(id) sender {
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
	CURRENT(t);	
	[panel setDirectoryURL:[[t.s fileURL] URLByDeletingLastPathComponent]];
	panel.allowsMultipleSelection = YES;
	if ([panel runModal] == NSOKButton) {
		NSArray *files = [panel URLs];;
		for (NSURL *url in files) {
			[self performSelector:@selector(open:) withObject:url afterDelay:0];
		}
	}	

}
- (IBAction)saveButton:(id)sender {
	CURRENT(t);
	if (t.s.temporary) {
		[self saveAsButton:nil];
	} else {
		[t save];
	}
}
- (IBAction)saveAsButton:(id)sender {
	CURRENT(t);
	NSSavePanel *spanel = [NSSavePanel savePanel];
	[spanel setPrompt:@"Save"];
	[spanel setShowsToolbarButton:YES];
	if (t.s.temporary) {
		TextVC *prev = [self.tabView tabViewItemAtIndex:[self getTabIndex:DIRECTION_LEFT]].identifier;
		[spanel setDirectoryURL:[prev.s.fileURL URLByDeletingLastPathComponent]];
	} else {
		[spanel setDirectoryURL:[t.s.fileURL URLByDeletingLastPathComponent]];
	}
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
	CURRENT(t);
	if ([t.ewc.window isVisible]) {
		[t.ewc.e terminate];
		[t.ewc.window orderOut:nil];
		return;
	}

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
	CURRENT(t);
 	[t revertToSaved];
}
- (IBAction)newTabButton:(id)sender {
	[self open:nil];
}
- (IBAction)goto_action:(id)sender {
	NSTextField *field = sender;
	NSString *value = [field stringValue];
	CURRENT(t);
	[t goto_line:[value integerValue]];	
	[self.goto_window orderOut:nil];
}

- (IBAction)commentSelection:(id)sender {
	NSString *commentSymbol;
	CURRENT(t);
	if ([t extIs:[NSArray arrayWithObjects:@"c", @"h",@"m",@"cpp",@"java",nil]]) {
		commentSymbol = @"//";
	} else {
		commentSymbol = @"#";
	}
	
	if ([t.text eachLineOfSelectionBeginsWith:commentSymbol]) {
		[t.text insert:commentSymbol atEachLineOfSelectionWithDirection:DIRECTION_LEFT];
	} else {
		[t.text insert:commentSymbol atEachLineOfSelectionWithDirection:DIRECTION_RIGHT];	
	}
}
- (IBAction)tabSelection:(id)sender {
	CURRENT(t);
	[t.text insert:@"\t" atEachLineOfSelectionWithDirection:[sender tag]];	
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
	o = [[TextVC alloc] initWithFrame:[self.tabView frame]];
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
		[self stopAllTasks:nil];
	}
	return ret;
}
- (void) diff_button:(id) sender {
	NSMenuItem *m = sender;
	NSURL *b = [NSURL fileURLWithPath:[m title]];
	CURRENT(t);
	[t run_diff_against:b];
}
- (void) encoding_button:(id) sender {
	NSMenuItem *m = sender;
	NSStringEncoding enc = m.tag;
	CURRENT(t);
	if ([t.s convertTo:enc]) {
		[t reload];
		[t save];
	}
}
- (void) snipplet_button:(id) sender {
	CURRENT(t);
	NSMenuItem *m = sender;
	NSInteger idx = m.tag;	
	NSArray *snip = [snipplet objectAtIndex:idx];
	NSString *value = [NSString stringWithFormat:@"%@\n",[snip objectAtIndex:1]];	
	[t.text insertAtBegin:value];
}
- (void) menuWillOpen:(NSMenu *)menu {
	CURRENT(t);
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
		NSMenuItem *m = [[NSMenuItem alloc] initWithTitle:[t.s currentEncoding] action:nil keyEquivalent:@""];
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
	} else if ([[menu title] isEqualToString:@"Snipplets"]) {
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
- (void) stopAllTasks:(id) sender {
	[self walk_tabs:^(TextVC *t) {
		[t.ewc.e terminate];
	}];
}
- (IBAction)run_button:(id)sender {
	CURRENT(t);
	[t run_self];
}
#pragma mark Timer
- (void) handleTimer:(id) sender {
	[self performSelectorOnMainThread:@selector(signal:) withObject:self waitUntilDone:YES];
}

- (void) signal:(id) sender {
	if ([NSApp isActive]) {
		[self walk_tabs:^(TextVC *t) {
			[t signal];
		}];
	}
}
#pragma mark aways on top action

- (IBAction)alwaysOnTop:(id)sender {
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	[preferences setObject:[NSNumber numberWithBool:([preferences boolForKey:@"DefaultAlwaysOnTop"] == YES) ? NO : YES] forKey:@"DefaultAlwaysOnTop"];
}

#pragma mark undo/redo
- (IBAction)undo:(id)sender {
	CURRENT(t);
	[[t.text undoManager] undo];
}
- (IBAction)redo:(id)sender {
	CURRENT(t);
	[[t.text undoManager] redo];
}
@end
