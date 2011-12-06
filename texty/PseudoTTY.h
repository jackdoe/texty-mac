#import <Foundation/Foundation.h>

@interface PseudoTTY : NSObject {
    NSFileHandle * master;
    NSFileHandle * slave;
}
@property (retain) NSFileHandle * master;
@property (retain) NSFileHandle * slave;
- (void) disableEcho;
- (void) enableEcho;
@end
