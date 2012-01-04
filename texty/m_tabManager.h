#import <Foundation/Foundation.h>
#import "m_exec.h"
#import "TextVC.h"
#import "Preferences.h"
@interface m_tabManager : NSObject <NSTabViewDelegate,NSMenuDelegate> {
	NSTabView *tabView;
	NSWindow * IBOutlet goto_window;
	NSTimer *timer;
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
- (IBAction)tabSelection:(id) sender;
- (IBAction)commentSelection:(id)sender;
- (IBAction)alwaysOnTop:(id)sender;
- (IBAction)selectTabAtIndex:(id) sender;
- (IBAction)run_button:(id)sender;
- (IBAction)undo:(id)sender;
- (IBAction)redo:(id)sender;
- (void) diff_button:(id) sender;
- (void) walk_tabs:(void (^)(TextVC *t)) callback;
- (BOOL) open:(NSURL *) file;
- (NSApplicationTerminateReply) gonna_terminate;
- (BOOL) openStoredURLs;
- (void) storeOpenedURLs;
- (NSInteger) getTabIndex:(int) direction;
- (void)swapTab:(NSInteger) first With:(NSInteger) second;
- (void) stopAllTasks:(id) sender;
@property (retain) NSTabView *tabView;
@property (retain) NSTimer *timer;
@property (retain) NSArray *snipplet;
@property (assign) NSWindow *goto_window;
@end
