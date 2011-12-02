#import <Foundation/Foundation.h>
@interface m_range : NSObject {
	NSRange _range;
	unsigned char _color;
	NSInteger _change;
}
@property (assign) NSRange _range;
@property (assign) unsigned char _color;
@property (assign) NSInteger _change;
- (void) dump;
- (NSRange) paragraph:(NSTextView *) tv;
+ (NSRange) rangeOfLine:(NSInteger) requested_line inString:(NSString *) s;
@end
