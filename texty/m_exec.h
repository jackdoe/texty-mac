#import <Foundation/Foundation.h>
#import "PseudoTTY.h"
@protocol m_execDelegate <NSObject>
@optional
- (void) taskAddExecuteText:(NSString *) text;
- (void) taskDidTerminate;
- (void) taskDidStart;
@end
@interface m_exec : NSObject {
	id <m_execDelegate> delegate;
	NSTask *task;
	NSString *_command;
	int _rc;
	NSDate *_startTime;
	BOOL _terminated;
	int _timeout;
	PseudoTTY *pty;
	NSLock *serial;
}
@property (retain) PseudoTTY *pty;
@property (assign) id <m_execDelegate> delegate;
@property (retain) NSTask *task;
@property (retain) NSDate *_startTime;
@property (assign) int _rc;
@property (retain) NSString * _command;
@property (assign) BOOL _terminated;
@property (assign) int _timeout;
@property (retain) NSLock *serial;
- (void) terminate;
- (void) readPipe:(NSNotification *)notification;
- (void) restart;
- (void) sendTerminate;
- (BOOL) diff:(NSURL *) a against:(NSURL *) b;
- (BOOL) execute:(NSString *) command withTimeout:(int) timeout;
- (void) write:(NSString *) value;
@end
