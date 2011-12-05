#import <Foundation/Foundation.h>
#import "m_exec.h"
#import "TextVC.h"
#import "m_status.h"
@interface m_tabManager : NSObject <NSTabViewDelegate,NSMenuDelegate,m_execDelegate,NSWindowDelegate> {
	NSTabView *tabView;
	NSWindow * IBOutlet goto_window;
	NSWindow * IBOutlet modal_panel;
	NSTextView * IBOutlet modal_tv;
	NSTextField * IBOutlet modal_field;
	NSTimer *timer;
	m_exec *e;
	m_status *_status;
	NSRange lastColorRange;
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
- (IBAction)swapLeft:(id)sender;
- (IBAction)swapRight:(id)sender;
- (IBAction)goto_button:(id) sender;
- (IBAction)goto_action:(id) sender;
- (IBAction)run_button:(id)sender;
- (IBAction)save_all:(id)sender;
- (IBAction)clearTV:(id)sender;
- (IBAction)stopTask:(id)sender;
- (IBAction)showRunBuffer:(id)sender;
- (BOOL) modal_escape:(id)sender;
- (void) walk_tabs:(void (^)(TextVC *t)) callback;
- (BOOL) open:(NSURL *) file;
- (NSApplicationTerminateReply) gonna_terminate;
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
- (BOOL) openStoredURLs;
- (void) storeOpenedURLs;
- (NSInteger) getTabIndex:(int) direction;
- (void) displayModalTV;
- (void) taskAddExecuteTitle:(NSString *)title;
- (void) taskAddExecuteText:(NSString *)text;
- (void) taskDidTerminate;
- (BOOL) AlertIfTaskIsRunning;
- (void) scrollEnd;
@property (retain) NSTabView *tabView;
@property (retain) NSWindow *goto_window;
@property (retain) NSTimer *timer;
@property (retain) NSWindow *modal_panel;
@property (assign) NSTextView *modal_tv;
@property (retain) NSTextField *modal_field;
@property (retain) m_exec *e;
@property (retain) m_status *_status;
@end
