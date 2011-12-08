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
	NSTextField * IBOutlet modal_input;
	NSPopUpButton * IBOutlet signal_popup;
	NSTimer *timer;
	m_exec *e;
	m_status *_status;
	NSRange lastColorRange;
	NSArray *snipplet;
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
- (IBAction)taskSendSignal:(id) sender;

- (void) walk_tabs:(void (^)(TextVC *t)) callback;
- (BOOL) open:(NSURL *) file;
- (NSApplicationTerminateReply) gonna_terminate;
- (BOOL) openStoredURLs;
- (void) storeOpenedURLs;
- (NSInteger) getTabIndex:(int) direction;
- (void) displayModalTV;
- (void) taskAddExecuteText:(NSString *)text;
- (void) taskDidTerminate;
- (void) taskDidStart;
- (void) taskSendSignal:(id)sender;
- (BOOL) AlertIfTaskIsRunning;
- (void) fixModalTextView;
@property (retain) NSTabView *tabView;
@property (retain) NSTimer *timer;
@property (retain) NSArray *snipplet;
@property (retain) m_exec *e;
@property (retain) m_status *_status;
@property (assign) NSPopUpButton * signal_popup;
@property (assign) NSWindow *goto_window;
@property (assign) NSWindow *modal_panel;
@property (assign) NSTextView *modal_tv;
@property (assign) NSTextField *modal_field,*modal_input;
@end
