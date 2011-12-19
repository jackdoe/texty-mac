#import "m_range.h"

@implementation m_range
@synthesize _range,_color,_change;
- (void) dump {
	NSLog(@"change: %ld range: %@",_change,NSStringFromRange(_range));
}
- (void) dump:(NSString *) s {
	NSRange para = [s paragraphRangeForRange:_range];
	unichar last = [s characterAtIndex:NSMaxRange(para)-1];
	unichar first = [s characterAtIndex:para.location];
	NSLog(@"first: '%c', last:'%c'",first,last);
}
- (BOOL) range:(NSRange) range fitsInside:(NSInteger) len {
	NSInteger max = NSMaxRange(range);
	if (max < len)
		return YES;
	return NO;
}
+ (NSInteger) numberOfLines:(NSString *) s {
	__block NSUInteger total_lines = 1;
	[s enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
		total_lines++;
	}];
	return total_lines;
}
+ (NSRange) rangeOfLine:(NSInteger) requested_line inString:(NSString *) s {
	NSUInteger total_len = [s length];
	NSUInteger total_lines = 0, i;
	unichar c;
	for (i=0;i<total_len;i++) {
		c = [s characterAtIndex:i];
		if (c == '\n' || c == '\r') {
			if (++total_lines >= requested_line)
				break;
			
		}
	}
	if (total_lines != requested_line) {
		return NSMakeRange(NSNotFound, 0);
	}
	NSRange area = [s paragraphRangeForRange:NSMakeRange(i, 0)];
	return area;
}

+(NSRange) visibleRangeinTextView:(NSTextView *) tv{
    NSRect visibleRect = [tv visibleRect];
    NSLayoutManager *lm = [tv layoutManager];
    NSTextContainer *tc = [tv textContainer];
    
    NSRange glyphVisibleRange = [lm glyphRangeForBoundingRect:visibleRect inTextContainer:tc];;
    NSRange charVisibleRange = [lm characterRangeForGlyphRange:glyphVisibleRange  actualGlyphRange:nil];
    return charVisibleRange;
}

- (NSRange) paragraph:(NSTextView *) tv {
	return [m_range visibleRangeinTextView:tv];
//	NSString *s = [tv string];
//	NSInteger len = [s length];
/*  XXX: parse everything at every keystroke to test the syntax highlighter */	
//	return NSMakeRange(0, len);
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
