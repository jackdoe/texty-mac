#import <AppKit/AppKit.h>
#import "colors.h"
@class m_parse;
#import "m_parse.h"

@interface STextView : NSTextView {
	NSBox *_box;
	BOOL _auto_indent;
	NSUndoManager *um;
	m_parse *parser;
}
- (BOOL) colorBracket;
- (BOOL) eachLineInRange:(NSRange) range beginsWith:(NSString *) symbol;
- (BOOL) eachLineOfSelectionBeginsWith:(NSString *)symbol;
- (void) insert:(NSString *) value atEachLineOfSelectionWithDirection:(NSInteger) direction;
- (void) insertAtBegin:(NSString *) value;
- (void) clearColors:(NSRange) area;
- (void) color:(NSRange) range withColor:(unsigned char) color;
- (NSRange) rangeOfLine:(NSInteger) requested_line;
- (NSRange) visibleRange;
- (void) delayedParse;
@property (retain) NSBox *_box;
@property (assign) BOOL _auto_indent;
@property (retain) NSUndoManager *um;
@property (retain) m_parse *parser;
@end
