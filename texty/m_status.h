#import <Foundation/Foundation.h>
@class m_tabManager;
@interface m_status : NSObject {
	NSStatusBar *sbar;
	NSStatusItem *sitem;
	NSMenu *menu;
	NSMenuItem *stopItem;
	NSMenuItem *showItem;
}
@property (retain) NSStatusBar *sbar;
@property (retain) NSStatusItem *sitem;
@property (retain) NSMenu *menu;
@property (retain) NSMenuItem *stopItem,*showItem;
- (m_status *) initWithTabManager:(m_tabManager *) manager;
- (void) enable;
- (void) disable;
@end
