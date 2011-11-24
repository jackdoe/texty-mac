#import "m_range.h"

@implementation m_range
@synthesize range,color,change;
- (void) dump {
	NSLog(@"change: %ld range: %@",self.change,NSStringFromRange(self.range));
}
- (void) dump:(NSString *) s {
	NSRange para = [s paragraphRangeForRange:self.range];
	unichar last = [s characterAtIndex:NSMaxRange(para)-1];
	unichar first = [s characterAtIndex:para.location];
	NSLog(@"first: '%c', last:'%c'",first,last);
}
- (NSRange) paragraph:(NSTextView *) tv {
	NSString *s = [tv string];
	NSInteger len = [s length];
	if (len < 1)
		return NSMakeRange(0, 0);
	NSRange para = [s paragraphRangeForRange:self.range];
	NSRange selected = [s paragraphRangeForRange:[tv selectedRange]];
	NSRange inter = NSIntersectionRange(para, selected);
	if (inter.length != 0) {
		return [s paragraphRangeForRange:inter];
	}
	return para;
}
@end
