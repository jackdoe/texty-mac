#import "m_range.h"

@implementation m_range
@synthesize range,color,change;
- (void) dump {
	NSLog(@"change: %ld range: %@",change,NSStringFromRange(range));
}
- (void) dump:(NSString *) s {
	NSRange para = [s paragraphRangeForRange:range];
	unichar last = [s characterAtIndex:NSMaxRange(para)-1];
	unichar first = [s characterAtIndex:para.location];
	NSLog(@"first: '%c', last:'%c'",first,last);
}
- (BOOL) range:(NSRange) _range fitsInside:(NSInteger) len {
	NSInteger max = NSMaxRange(_range);
	if (max < len)
		return YES;
	return NO;
}
- (NSRange) paragraph:(NSTextView *) tv {
	NSString *s = [tv string];
	NSInteger len = [s length];
	/* XXX: parse everything at every keystroke to test the syntax highlighter */
	return NSMakeRange(0, len);
//
//	
//	
//	
//	if (len < 1 || ![self range:range fitsInside:len])
//		return NSMakeRange(0, len);
//
//		
//	NSRange para = [s paragraphRangeForRange:range];
//	NSRange combine = NSMakeRange(para.location, para.length+1); /* just get the next line */	
//	if ([self range:combine fitsInside:len]) {
//		return [s paragraphRangeForRange:combine];
//	}
//	return para;
}
@end
