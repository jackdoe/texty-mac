#import "m_status.h"

@implementation m_status
@synthesize menu,sbar,sitem,stopItem,showItem;
- (m_status *) initWithTabManager:(m_tabManager *) manager {
	self = [super init];
	if (self) {
		self.sbar = [NSStatusBar systemStatusBar];
		self.sitem = [sbar statusItemWithLength:NSSquareStatusItemLength];
		[sitem setTarget:self];
		[sitem setImage:[NSImage imageNamed:@"texty_small.png"]];
		self.menu = [[NSMenu alloc] initWithTitle:@"texty"];
		[menu setAutoenablesItems:NO];
		self.stopItem = [[NSMenuItem alloc] init];
		[stopItem setTitle:@"TASK: stop"];
		[stopItem setTarget:manager];
		[stopItem setAction:@selector(stopTask:)];
		[stopItem setEnabled:NO];
		[menu addItem:stopItem];
		self.showItem = [[NSMenuItem alloc] init];
		[showItem setTitle:@"Show Run Buffer"];
		[showItem setTarget:manager];
		[showItem setAction:@selector(showRunBuffer:)];
		[showItem setEnabled:YES];
		[menu addItem:showItem];
		[sitem setMenu:menu];
	}
	return self;
}
- (void) enable {
	[stopItem setEnabled:YES];
	[sitem setImage:[NSImage imageNamed:@"texty_red_small.png"]];
}
- (void) disable {
	[stopItem setEnabled:NO];
	[sitem setImage:[NSImage imageNamed:@"texty_small.png"]];
}

@end
