#import "m_diff.h"

@implementation m_diff
@synthesize a,b;
- (NSString *) diff {
	return [m_exec execute:[NSString stringWithFormat:@"diff -rupN %@ %@",[a path],[b path]] withTimeout:1 saveRC:nil];
}
@end
