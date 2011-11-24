#import <Foundation/Foundation.h>
#import "m_exec.h"
@interface m_diff : NSObject {
	NSURL *a;
	NSURL *b;
}
@property (retain) NSURL *a,*b;
- (NSString *) diff;
@end
