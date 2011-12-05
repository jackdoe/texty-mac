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
	BOOL _terminated;
}
@property (assign) id <m_execDelegate> delegate;
@property (retain) NSTask *task;
@property (assign) int _rc;
@property (retain) NSString * _command;
@property (assign) BOOL _terminated;
- (void) readPipe:(NSNotification *)notification;
- (BOOL) diff:(NSURL *) a against:(NSURL *) b;
- (BOOL) execute:(NSString *) command withTimeout:(int) timeout;
@end
