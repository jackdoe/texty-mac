// forked from Ingvar Nedrebo's PseudoTTY.m


// add enable/disable echo
// remove pty's name - it is unsecure because nobody knows how big is it, except the caller
// clean up
#import "PseudoTTY.h"
#import <util.h>
#include <sys/ioctl.h>
#include <termios.h>
@implementation PseudoTTY
@synthesize master,slave;
-(id)init {
	self = [super init];
	if (self) {
		int masterfd, slavefd;
        if (openpty(&masterfd, &slavefd, NULL, NULL, NULL) == -1) {
			return nil;
        }
        self.slave = [[NSFileHandle alloc] initWithFileDescriptor:slavefd];
        self.master = [[NSFileHandle alloc] initWithFileDescriptor:masterfd closeOnDealloc:YES];
		[self disableEcho];
    }
    return self;
}
- (void) disableEcho {
	int slavefd = [slave fileDescriptor];
	struct termios t;
	if (tcgetattr (slavefd, &t) == 0) {
		t.c_lflag &= ~ECHO;
		tcsetattr (slavefd, TCSANOW, &t);
	}
}
- (void) enableEcho {
	int slavefd = [slave fileDescriptor];
	struct termios t;
	if (tcgetattr (slavefd, &t) == 0) {
		t.c_lflag |= ECHO;
		tcsetattr (slavefd, TCSANOW, &t);
	}
}

@end
