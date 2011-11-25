#import "m_tabManager.h"
#define EXECUTE_TYPE_SHELL 1
#define EXECUTE_TYPE_WWW 2
@implementation m_tabManager
@synthesize tabView,goto_window,timer,modal_panel,modal_tv,modal_www;
- (m_tabManager *) init {
	return [self initWithFrame:[[NSApp mainWindow] frame]];
}
- (m_tabManager *) initWithFrame:(NSRect) frame {
	self = [super init];
	self.tabView = [[NSTabView alloc] initWithFrame:frame];
	self.tabView.delegate = self;
	[self.tabView setFont:FONT];
	[self.tabView setControlTint:NSClearControlTint];
	[self open:nil];

	self.timer = [NSTimer scheduledTimerWithTimeInterval: 1
				target: self
				selector: @selector(handleTimer:)
				userInfo: nil
				repeats: YES];

	return self;
}
- (void) goLeft:(id) sender {
	[self.tabView selectPreviousTabViewItem:nil];
}
- (void) goRight:(id) sender {
	[self.tabView selectNextTabViewItem:nil];
}
- (void) signal:(id) sender {
	NSArray *a = [self.tabView tabViewItems];
	for (NSTabViewItem *tabItem in a) {
		Text *t = tabItem.identifier;
		[t signal];
	}
}
- (void) handleTimer:(id) sender {
	[self performSelectorOnMainThread:@selector(signal:) withObject:self waitUntilDone:YES];
}
- (IBAction)openButton:(id)sender {
	NSOpenPanel *panel	= [NSOpenPanel openPanel];
	panel.allowsMultipleSelection = YES;
	if ([panel runModal] == NSOKButton) {
		NSArray *files = [panel URLs];;
		for (NSURL *url in files) {
			if (url)
				[self open:url];		
		}
	}	

}
- (IBAction)saveButton:(id)sender {
	Text *t = [self.tabView selectedTabViewItem].identifier;
	[t save];
}
- (IBAction)saveAsButton:(id)sender {
	Text *t = [self.tabView selectedTabViewItem].identifier;
	NSSavePanel *spanel = [NSSavePanel savePanel];
	[spanel setPrompt:@"Save"];
	[spanel setShowsToolbarButton:YES];
	[spanel setRepresentedURL:t.s.fileURL];
	[spanel setExtensionHidden:NO];
	[spanel setNameFieldStringValue:[t.s basename]];
	[spanel beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton) {
			[t saveAs:[spanel URL]];
		}
	}];
}
- (IBAction)closeButton:(id)sender {
	Text *t = [self.tabView selectedTabViewItem].identifier;
	if ([t is_modified]) {
		NSInteger alertReturn = NSRunAlertPanel(@"got unsaved data", @"You have unsaved data." , @"Save & Close",@"Close Without Saving", @"Cancel");
		if (alertReturn == NSAlertDefaultReturn) { 		/* Save */
			[t save];
		} else if (alertReturn == NSAlertOtherReturn) { /* Cancel */
			return; 
		}
	}
	/* remove the empty file */
	if ([[t.tv string] length] < 1 && t.s.temporary) {
		NSFileManager *f = [[NSFileManager alloc] init];
		[f removeItemAtURL:t.s.fileURL error:nil];
	}
	[self.tabView removeTabViewItem:[self.tabView selectedTabViewItem]];
	if ([[self.tabView tabViewItems] count] == 0) {
		[NSApp terminate: self];
	}
}
- (IBAction)revertToSavedButton:(id)sender {
	Text *t = [self.tabView selectedTabViewItem].identifier;
 	[t revertToSaved];
}
- (IBAction)newTabButton:(id)sender {
	[self open:nil];
}
- (IBAction)goto_action:(id)sender {
	NSTextField *field = sender;
	NSString *value = [field stringValue];
	Text *t = [self.tabView selectedTabViewItem].identifier;
	[t goto_line:[value integerValue]];	
	[self.goto_window orderOut:nil];
	[NSApp endSheet:self.goto_window];
}
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	[sheet orderOut:self];
    [NSApp endSheet:sheet];
	[sheet close];
}
- (IBAction)goto_button:(id)sender {
	if ([self.goto_window isVisible])
		[self.goto_window orderOut:nil];
	else 
		[self.goto_window makeKeyAndOrderFront:nil];
}
- (IBAction)run_button:(id)sender {
	[self modal_escape:nil];
	Text *t = [self.tabView selectedTabViewItem].identifier;
	NSString *cmd = [t get_execute_command];
	cmd = [cmd stringByReplacingOccurrencesOfString:@"{MYSELF}" withString:[t.s.fileURL path]];
	if (cmd) {
		int type = EXECUTE_TYPE_SHELL;
		NSString *data;
		[t save];
		NSRange found = [cmd rangeOfString:@"^\\s*?http://" options:NSRegularExpressionSearch];
		if (found.location != NSNotFound) {
			type = EXECUTE_TYPE_WWW;
			data = cmd;
			data = [cmd stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		} else {
			data = [m_exec execute:cmd];
		}
		[self runModalWithString:data andType:type];
	}
}
- (void) open:(NSURL *) file{
	Text *t = [[Text alloc] initWithFrame:[self.tabView frame]];
	if ([t open:file]) {
		[self.tabView addTabViewItem:t.tabItem];
		[self.tabView selectTabViewItem:t.tabItem];
	}
}
- (IBAction) save_all:(id) sender {
	NSArray *a = [self.tabView tabViewItems];
	for (NSTabViewItem *tabItem in a) {
		Text *t = tabItem.identifier;
		[t save];
	}
}
- (NSApplicationTerminateReply) gonna_terminate {
	NSArray *a = [self.tabView tabViewItems];
	unsigned int have_unsaved = 0;
	for (NSTabViewItem *tabItem in a) {
		Text *t = tabItem.identifier;
		if ([t is_modified]) {
			have_unsaved++;;
		}
	}
	if (have_unsaved) {
		NSInteger alertReturn = NSRunAlertPanel(@"got unsaved data", [NSString stringWithFormat:@"You have unsaved data for %u files.",have_unsaved] ,@"Cancel", @"Save All & Exit",@"Exit without saving!");
		if (alertReturn == NSAlertAlternateReturn) {
			[self save_all:nil];
			return NSTerminateNow;
		} else if (alertReturn == NSAlertDefaultReturn) {
			return NSTerminateCancel;
		}
	}
	return NSTerminateNow;
}
- (void) diff_button:(id) sender {
	[self modal_escape:nil];
	NSMenuItem *item = sender;
	m_diff *d = [[m_diff alloc] init];
	Text *t = [self.tabView selectedTabViewItem].identifier;
	d.a = t.s.fileURL;
	d.b = [NSURL fileURLWithPath:[item title]];
	[self runModalWithString:[d diff] andType:EXECUTE_TYPE_SHELL];
}
- (void) runModalWithString:(NSString *) data andType:(int) type{
	if (type == EXECUTE_TYPE_WWW) {
		[self.modal_tv setHidden:YES];
		[self.modal_www setHidden:NO];
		[self.modal_www setShouldUpdateWhileOffscreen:NO];
		[self.modal_www setShouldCloseWithWindow:NO];
		WebFrame *mainFrame = [self.modal_www mainFrame];
		[mainFrame stopLoading];
		NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:data]];
		[mainFrame loadRequest:request];
	} else {
		[self.modal_www setHidden:YES];
		[self.modal_tv setHidden:NO];
	}
	[self.modal_tv setString:data];
	[self.modal_tv setFont:FONT];
	[self.modal_tv setTextColor:TEXT_COLOR];
	NSMutableDictionary *selected = [[self.modal_tv selectedTextAttributes] mutableCopy];
	[selected setObject:BG_COLOR forKey:NSForegroundColorAttributeName];
	[selected setObject:TEXT_COLOR forKey:NSBackgroundColorAttributeName];
	[self.modal_tv setSelectedTextAttributes:selected];
	[self.modal_tv setBackgroundColor:BG_COLOR];
	[self.modal_tv setInsertionPointColor:CURSOR_COLOR];
	[NSApp beginSheet:self.modal_panel modalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}
- (void) menuWillOpen:(NSMenu *)menu {
	[menu removeAllItems];
	Text *t = [self.tabView selectedTabViewItem].identifier;
	for (NSString *b in t.s.backups) {
		NSMenuItem *m = [[NSMenuItem alloc] initWithTitle:b action:@selector(diff_button:) keyEquivalent:@""];
		[m setTarget:self];
		[menu addItem:m];		
	}
}
- (void) menuDidClose:(NSMenu *)menu {
}
- (IBAction)modal_escape:(id)sender {
	[[self.modal_www mainFrame] loadHTMLString:@"<html><head></head><body color=black></body></html>" baseURL:nil];
	[self sheetDidEnd:self.modal_panel returnCode:0 contextInfo:nil];
}
@end
