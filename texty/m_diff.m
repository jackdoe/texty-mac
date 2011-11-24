//
//  m_diff.m
//  texty7
//
//  Created by jack on 11/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "m_diff.h"

@implementation m_diff
@synthesize a,b;
- (NSString *) diff {
	return [m_exec execute:[NSString stringWithFormat:@"diff -rupN %@ %@",[a path],[b path]]];
}
@end
