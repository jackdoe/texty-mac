#import "ExecuteWC.h"
@implementation ExecuteWC
@synthesize e;
- (id) init {
	self = [self initWithWindowNibName:@"ExecuteWindow"];
	if (self) {
		self.e = [[m_exec alloc] init];
		e.delegate = self;
	}
	return self;
}
- (void) execute:(NSString *) command withTimeout:(int)timeout {
	[e execute:command withTimeout:timeout];	
}
- (void)windowDidLoad {
    [super windowDidLoad];
	[self fixModalTextView];
}
- (void) windowWillClose:(NSNotification *)notification {
	if ([Preferences terminateOnClose])
		[e terminate];
}
- (IBAction)action:(id)sender {
	switch ([sender tag]) {
	case TAG_INPUT:
		[e write:[[sender stringValue] stringByAppendingString:@"\n"]];
	break;
	case TAG_STOP:
		[e terminate];
		[input becomeFirstResponder];	
	break;
	case TAG_CLEAR:
		[output setString:@""];
		lastColorRange = NSMakeRange(0, 0);
		[input becomeFirstResponder];
	break;
	case TAG_RELOAD:
		[e restart];
		[input becomeFirstResponder];	
	break;
	}
}

- (void) taskAddExecuteText:(NSString *)text {
	NSRange range = { [[output string] length], 0 };
	[output setSelectedRange: range];
	[output replaceCharactersInRange: range withString:text];
	[output scrollRangeToVisible:NSMakeRange([[output string] length], 0)];
}
- (void) taskDidStart {
	[self taskAddExecuteText:[NSString stringWithFormat:@"\nSTART: [%@] TASK(timeout: %@): %@\n",e._startTime,(e._timeout == 0 ? @"NOTIMEOUT" : [NSString stringWithFormat:@"%d",e._timeout]),e._command]];
	[input setEnabled:YES];
	[self.window setTitle:e._command];
}
- (void) taskDidTerminate {
	NSString *timedOut = @"";
	if (e._terminated) {
		timedOut = @" [TOUT]";
	} 
	NSDate *now = [NSDate date];
	NSTimeInterval diff = [now timeIntervalSinceDate:e._startTime];
	[self taskAddExecuteText:[NSString stringWithFormat:@"\nEND : [%@ - took: %llfs] TASK(RC: %d%@): %@\n",now,diff,e._rc,timedOut,e._command]];
	[input setEnabled:NO];

	NSInteger max = NSMaxRange(lastColorRange);
	NSInteger len = [[output string] length];
	NSRange range = {0 ,max};
	[[output textStorage] addAttribute:NSForegroundColorAttributeName value:COMMENT_COLOR range:range];
	range = NSMakeRange(max,len - max);
	[[output textStorage] addAttribute:NSForegroundColorAttributeName value:VALUE_COLOR range:range];
	
	lastColorRange = range;
	[input setEnabled:NO];
}
- (IBAction)taskSendSignal:(id) sender {
	[e sendSignal:(int) [sender tag]];
}
- (void) fixModalTextView {
	[output setHidden:NO];
	[output setFont:FONT];
	[output setTextColor:TEXT_COLOR];
	NSMutableDictionary *selected = [[output selectedTextAttributes] mutableCopy];
	[selected setObject:BG_COLOR forKey:NSForegroundColorAttributeName];
	[selected setObject:TEXT_COLOR forKey:NSBackgroundColorAttributeName];
	[output setSelectedTextAttributes:selected];
	[output setBackgroundColor:BG_COLOR];
	[output setInsertionPointColor:CURSOR_COLOR];
	[self.window setLevel: NSFloatingWindowLevel]; 
}

- (void) dealloc {
	[e terminate];
}

@end
