#import <Foundation/Foundation.h>
#import "Preferences.h"
#include <sys/event.h>
#include <sys/time.h> 
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h> 
#define NEV 256
@interface FileWatcher : NSObject {
	NSLock *ex;
	NSString *wakeup;
	NSMutableDictionary *list;
	struct kevent change[NEV];
	struct kevent event[NEV];
}
+ (FileWatcher *) shared;
- (void) watch:(NSURL *) file notify:(id)who;
- (void) unwatch:(NSURL *) file;
@property (retain) NSMutableDictionary *list;
@property (retain) NSLock *ex;
@property (retain) NSString *wakeup;
- (void) start;
@end
