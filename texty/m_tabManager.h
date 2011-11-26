#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "Text.h"
#import "m_diff.h"
@interface m_tabManager : NSObject <NSTabViewDelegate,NSMenuDelegate> {
	NSTabView *tabView;
	NSWindow * IBOutlet goto_window;
	NSWindow * IBOutlet modal_panel;
	NSTextView * IBOutlet modal_tv;
	WebView * IBOutlet modal_www;
	NSTextField * IBOutlet modal_field;
	NSTimer *timer;
}
- (m_tabManager *) initWithFrame:(NSRect) frame;
- (IBAction)openButton:(id)sender;
- (IBAction)closeButton:(id)sender;
- (IBAction)saveButton:(id)sender;
- (IBAction)newTabButton:(id)sender;
- (IBAction)revertToSavedButton:(id)sender;
- (IBAction)saveAsButton:(id)sender;
- (IBAction)goLeft:(id) sender;
- (IBAction)goRight:(id) sender;
- (IBAction)goto_button:(id) sender;
- (IBAction)goto_action:(id) sender;
- (IBAction)run_button:(id)sender;
- (IBAction)save_all:(id)sender;
- (IBAction)modal_escape:(id)sender;
- (void) open:(NSURL *) file;
- (NSApplicationTerminateReply) gonna_terminate;
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
- (void) runModalWithString:(NSString *) data andType:(int) type;
@property (retain) NSTabView *tabView;
@property (retain) NSWindow *goto_window;
@property (retain) NSTimer *timer;
@property (retain) NSWindow *modal_panel;
@property (retain) NSTextView *modal_tv;
@property (retain) WebView *modal_www;
@property (retain) NSTextField *modal_field;
@end
