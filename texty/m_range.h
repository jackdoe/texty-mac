//
//  m_range.h
//  texty7
//
//  Created by jack on 11/24/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

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
@end
