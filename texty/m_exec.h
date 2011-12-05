#import <Foundation/Foundation.h>
@protocol m_execDelegate <NSObject>
@optional
- (void) taskAddExecuteText:(NSString *)text;
- (void) taskAddExecuteTitle:(NSString *) title;
- (void) taskDidTerminate;
@end
@interface m_exec : NSObject {
	id <m_execDelegate> delegate;
	NSTask *task;
	NSString *_command;
	int _rc;
	NSDate *_startTime;
	BOOL _terminated;
	int _timeout;
}
@property (assign) id <m_execDelegate> delegate;
@property (retain) NSTask *task;
@property (retain) NSDate *_startTime;
@property (assign) int _rc;
@property (retain) NSString * _command;
@property (assign) BOOL _terminated;
@property (assign) int _timeout;
- (void) terminate;
- (void) readPipe:(NSNotification *)notification;
- (void) restart;
- (void) sendTerminate;
- (BOOL) diff:(NSURL *) a against:(NSURL *) b;
- (BOOL) execute:(NSString *) command withTimeout:(int) timeout;
@end
