#import "m_tabManager.h"
#define EXECUTE_TYPE_SHELL 1
#define EXECUTE_TYPE_WWW 2
#define DIRECTION_LEFT 1
#define DIRECTION_RIGHT 2
@implementation m_tabManager
@synthesize tabView,goto_window,timer,modal_panel,modal_tv = _modal_tv,modal_field,e,_status;
- (m_tabManager *) init {
	return [self initWithFrame:[[NSApp mainWindow] frame]];
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

}
- (m_tabManager *) initWithFrame:(NSRect) frame {
	self = [super init];
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
	self._status = [[m_status alloc] initWithTabManager:self];
	lastColorRange = NSMakeRange(0, 0);
	[self performSelector:@selector(fixModalTextView) withObject:nil afterDelay:0];
	if (![self openStoredURLs]) {
		[self open:nil];
	}
	return self;
}
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
- (void) signal:(id) sender {
	if ([self.e.task isRunning]) {
		[_status enable];
	} else {
		[_status disable];
	}
	[self walk_tabs:^(TextVC *t) {
		[t signal];
	}];
}
- (void) handleTimer:(id) sender {
	[self performSelectorOnMainThread:@selector(signal:) withObject:self waitUntilDone:YES];
}
- (IBAction)openButton:(id)sender {
	[self modal_escape:nil];
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
	[self modal_escape:nil];
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
		NSInteger alertReturn = NSRunAlertPanel(@"WARNING: unsaved data.", @"You have unsaved data for 1 file." , @"Cancel",@"Save & Close", @"Close w/o Save");
		if (alertReturn == NSAlertAlternateReturn) { 		/* Save */
			[t save];
		} else if (alertReturn == NSAlertDefaultReturn) { /* Cancel */
			return; 
		}
	}
	/* remove the empty file */
	if ([t strlen] < 1 && t.s.temporary) {
		NSFileManager *f = [[NSFileManager alloc] init];
		[f removeItemAtURL:t.s.fileURL error:nil];
	}
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
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [NSApp endSheet:sheet];
}
- (IBAction)goto_button:(id)sender {
	if ([self.goto_window isVisible])
		[self.goto_window orderOut:nil];
	else 
		[self.goto_window makeKeyAndOrderFront:nil];
}
- (IBAction)run_button:(id)sender {
	if ([self modal_escape:nil])
		return; 
	TextVC *t = [self.tabView selectedTabViewItem].identifier;
	NSString *cmd = [t get_execute_command];
	if (!cmd) 
		return;
	[t save];

	cmd = [cmd stringByReplacingOccurrencesOfString:@"{MYSELF}" withString:[t.s.fileURL path]];
	cmd = [cmd stringByReplacingOccurrencesOfString:@"{MYSELF_BASENAME}" withString:[t.s basename]];
	cmd = [cmd stringByReplacingOccurrencesOfString:@"{MYSELF_BASENAME_NOEXT}" withString:[[t.s basename] stringByDeletingPathExtension]];
	cmd = [cmd stringByReplacingOccurrencesOfString:@"{MYDIR}" withString:[[t.s.fileURL path] stringByDeletingLastPathComponent]];
	BOOL output = ([cmd rangeOfString:@"{NOOUTPUT}"].location == NSNotFound);
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
	if (output) {
		[self displayModalTV];
	}
}
- (BOOL) open:(NSURL *) file {
	__block TextVC *o = nil;
	[self walk_tabs:^(TextVC *t) {
		if ([t.s.fileURL isEqualTo:file]) {
			o = t;
		};
	}];
	if (o) {
		NSInteger alertReturn = NSRunAlertPanel(@"file is already opened", [NSString stringWithFormat:@"File: %@ is already open, do you want to reload it from disk?",[file path]] ,@"Reload", @"Cancel",nil);
		if (alertReturn == NSOKButton) {
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
	if (have_unsaved) {
		NSInteger alertReturn = NSRunAlertPanel(@"WARNING: unsaved data.", [NSString stringWithFormat:@"You have unsaved data for %u file%s",have_unsaved,(have_unsaved > 1 ? "s." : ".")] ,@"Cancel", @"Save & Close",@"Close w/o Save");
		if (alertReturn == NSAlertAlternateReturn) {
			[self save_all:nil];
			return NSTerminateNow;
		} else if (alertReturn == NSAlertDefaultReturn) {
			return NSTerminateCancel;
		}
	}
	return NSTerminateNow;
}
- (BOOL) AlertIfTaskIsRunning {
	
	if ([self.e.task isRunning]) {
		NSString *running = [NSString stringWithFormat:@"CURRENT TASK:\n%@",self.e._command];
		NSInteger ret = NSRunAlertPanel(@"There is a task running.", running , @"Close", @"Stop Task",nil);
		if (ret != NSAlertDefaultReturn) {
			[self stopTask:nil];
			return YES;
		}
		return NO;
	}
	return YES;
}
- (void) diff_button:(id) sender {
	if ([self AlertIfTaskIsRunning] == NO)
		return;
	[self modal_escape:nil];
	NSMenuItem *item = sender;
	TextVC *t = [self.tabView selectedTabViewItem].identifier;
	NSURL *a = t.s.fileURL;
	NSURL *b = [NSURL fileURLWithPath:[item title]];
	if ([e diff:a against:b]) {
		[self displayModalTV];
	}
}

- (void) displayModalTV {
	[self scrollEnd];
	[NSApp beginSheet:self.modal_panel modalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}
- (void) menuWillOpen:(NSMenu *)menu {
	[menu removeAllItems];
	TextVC *t = [self.tabView selectedTabViewItem].identifier;
	for (NSString *b in t.s.backups) {
		NSMenuItem *m = [[NSMenuItem alloc] initWithTitle:b action:@selector(diff_button:) keyEquivalent:@""];
		[m setTarget:self];
		[menu addItem:m];		
	}
}
- (void) menuDidClose:(NSMenu *)menu {
}

- (IBAction)clearTV:(id)sender {
	[self.modal_tv setString:@""];
	lastColorRange = NSMakeRange(0, 0);
}
- (IBAction)stopTask:(id)sender {
	[self.e.task terminate];
}
- (IBAction)showRunBuffer:(id)sender {
	if ([NSApp isActive]) {
		[self modal_escape:nil];
		[self displayModalTV];
	}
}
- (void) scrollEnd {
	NSRange range = { [[self.modal_tv string] length], 0 };
	[self.modal_tv scrollRangeToVisible: range];
}
- (void) taskAddExecuteText:(NSString *)text {
	NSRange range = { [[self.modal_tv string] length], 0 };
	[self.modal_tv setSelectedRange: range];
	[self.modal_tv replaceCharactersInRange: range withString:text];
	[self scrollEnd];
}
- (void) taskAddExecuteTitle:(NSString *)title {
	[self.modal_field setStringValue:[title copy]];
}
- (void) taskDidTerminate {
	NSInteger max = NSMaxRange(lastColorRange);
	NSInteger len = [[self.modal_tv string] length];
	NSRange range = {0 ,max};
	[[self.modal_tv textStorage] addAttribute:NSForegroundColorAttributeName
                            value:COMMENT_COLOR
							range:range];
	range = NSMakeRange(max,len - max);
	[[self.modal_tv textStorage] addAttribute:NSForegroundColorAttributeName
                            value:PREPROCESS_COLOR
							range:range];
	
	lastColorRange = range;
}
- (BOOL)modal_escape:(id)sender {
	BOOL ret = NO;
	if ([self.modal_panel isVisible])
		ret = YES;
	[self sheetDidEnd:self.modal_panel returnCode:0 contextInfo:nil];
	return ret;
}
@end
