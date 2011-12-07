//
//  TextVC.h
//  texty
//
//  Created by jack on 12/2/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "m_Storage.h"
#import "m_range.h"
#import "m_parse.h"

@interface TextVC : NSViewController <NSTextStorageDelegate,NSTextViewDelegate> {
	IBOutlet NSTextView *text;
	IBOutlet NSScrollView *scroll;
	m_Storage *s;
	m_parse *parser;
	NSTabViewItem *tabItem;
	BOOL something_changed, need_to_autosave;
	long autosave_ts;
	NSBox *box;
}
- (BOOL) open:(NSURL *)file;
- (void) saveAs:(NSURL *) to;
- (void) save;
- (BOOL) is_modified;
- (void) signal;
- (void) revertToSaved;
- (void) goto_line:(NSInteger) want_line;
- (NSInteger) strlen;
- (NSString *) get_line:(NSInteger) lineno;
- (NSString *) get_execute_command;
- (void) reload;
@property (retain) NSTabViewItem *tabItem;
@property (retain) m_Storage *s;
@property (retain) m_parse *parser;
@property (retain) NSBox *box;
@end
