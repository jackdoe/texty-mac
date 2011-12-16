#import <Cocoa/Cocoa.h>
#import "m_tabManager.h"
#import "Preferences.h"
@interface textyAppDelegate : NSObject <NSApplicationDelegate,NSWindowDelegate> {
	m_tabManager IBOutlet *tab;
}

@property (assign) IBOutlet NSWindow *window;
@property (retain) m_tabManager *tab;
@end
