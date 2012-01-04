#import <AppKit/AppKit.h>
#import "colors.h"
@interface STextView : NSTextView {
	NSBox *_box;
	BOOL _auto_indent;
	NSUndoManager *um;
}
- (BOOL) colorBracket;
- (BOOL) eachLineInRange:(NSRange) range beginsWith:(NSString *) symbol;
- (BOOL) eachLineOfSelectionBeginsWith:(NSString *)symbol;
- (void) insert:(NSString *) value atEachLineOfSelectionWithDirection:(NSInteger) direction;
- (void) insert:(NSString *) value atLine:(NSInteger) line;
- (void) clearColors:(NSRange) area;
- (void) color:(NSRange) range withColor:(unsigned char) color;
- (NSRange) rangeOfLine:(NSInteger) requested_line;
- (NSRange) visibleRange;
@property (retain) NSBox *_box;
@property (assign) BOOL _auto_indent;
@property (retain) NSUndoManager *um;
@end
