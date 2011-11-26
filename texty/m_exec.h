#import <Foundation/Foundation.h>

@interface m_exec : NSObject
+ (NSString *) execute:(NSString *) command withTimeout:(int) timeout saveRC:(int *) rc;
@end
