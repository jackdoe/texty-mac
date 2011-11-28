#import <Foundation/Foundation.h>

@interface m_range : NSObject {
	NSRange range;
	unsigned char color;
	NSInteger change;
}
@property (assign) NSRange range;
@property (assign) unsigned char color;
@property (assign) NSInteger change;
- (void) dump;
- (NSRange) paragraph:(NSTextView *) tv;
+ (NSRange) rangeOfLine:(NSInteger) requested_line inString:(NSString *) s;
@end
