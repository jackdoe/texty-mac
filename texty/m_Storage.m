#import "m_Storage.h"
#import "FileWatcher.h"
@implementation m_Storage
@synthesize fileURL, data,temporary,existing_backups,encoding,delegate = _delegate;
- (void) changed_under_your_nose:(NSURL *) file {
	if (self.delegate && [self.delegate respondsToSelector:@selector(changed_under_my_nose:)]) {
		[self.delegate changed_under_my_nose:file];
	}
}
+ (BOOL) fileExists:(NSString *) path {
	NSFileManager *f = [[NSFileManager alloc] init];
	return [f fileExistsAtPath:path];
}
- (NSInteger) fileAlert:(NSURL *) url withMessage:(NSString *) message def:(NSString *) def alternate:(NSString *) alternate other:(NSString *) other {
	return NSRunAlertPanel([url path], message, def, alternate, other);
}
- (void) noChoiceAlert:(NSString *) message withURL:(NSURL *) url{
	[self fileAlert:url withMessage:message def:nil alternate:nil other:nil];
}
- (BOOL) open:(NSURL *) URL {
	[self close:NO];
	self.existing_backups = nil;
	if (!URL) {
		URL = [self temporaryFileURL];
		if (!URL) {
			return FALSE;
		}
		self.temporary = YES;
	} else {
		self.temporary = NO;
	}
	
	if (self.fileURL) 
		[self close:NO];
	
	self.fileURL = [URL copy];
	NSError *err;
	NSStringEncoding usedEncoding;
	self.data = [NSString stringWithContentsOfURL:URL usedEncoding:&usedEncoding error:&err];
	if (err) {
		[self noChoiceAlert:[err localizedDescription] withURL:self.fileURL];
		return FALSE;	
	}
	self.encoding = usedEncoding;
	if (!temporary)
		[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:self.fileURL];
	self.existing_backups = [self backups];
	[[FileWatcher shared] watch:self.fileURL notify:self];
	return TRUE;
}
- (NSString *) encodingName:(NSStringEncoding) enc{
	return [NSString localizedNameOfStringEncoding:enc];
}
- (NSString *) currentEncoding {
	return [self encodingName:self.encoding];
}
- (NSArray *) encodings {
	NSMutableArray *e = [NSMutableArray array];
	const NSStringEncoding * encodings = [NSString availableStringEncodings];
	while (*encodings) {
		[e addObject:[NSArray arrayWithObjects:[NSString localizedNameOfStringEncoding:*encodings],[NSNumber numberWithLong:*encodings],nil]];
		encodings++;
	}
	[e sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		NSString *a, *b;
		a = [obj1 objectAtIndex:0];
		b = [obj2 objectAtIndex:0];
		if ([a isGreaterThan:b])
			return NSOrderedDescending;
		if ([a isLessThan:b])
			return NSOrderedAscending;
		return NSOrderedSame;
	}];
	return [NSArray arrayWithArray:e];
}
- (BOOL) convertTo:(NSStringEncoding) enc {
	if ([self.data canBeConvertedToEncoding:enc]) {
		NSData *temp = [self.data dataUsingEncoding:enc];
		if (temp) {
			encoding = enc;
			self.data = [[NSString alloc] initWithData:temp encoding:enc];
			return TRUE;
		}
	}
	NSString *message = [NSString stringWithFormat:@"ERROR: %@ can not be coverted from %@ to %@ without data loss.",[self basename],[self currentEncoding],[self encodingName:enc]];
	[self noChoiceAlert:message withURL:self.fileURL];
	return FALSE;
}
- (BOOL) close:(BOOL) save {
	if (save) 
		[self migrate:self.fileURL withString:self.data autosaving:NO];
	[self close];
	self.data = nil;
	self.fileURL = nil;
	return TRUE;
}

- (BOOL) migrate:(NSURL *) to withString:(NSString *) string autosaving:(BOOL) autosaving{
	if (!to || !string)
		return NO;
	[self backup];
	self.existing_backups = [self backups];

	if (!autosaving)
		self.temporary = NO;
	[[FileWatcher shared] unwatch:to];	/* XXX: race */
	if ([self write:string toURL:to]) {
		if (!temporary)
			[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:to];
		[[FileWatcher shared] unwatch:self.fileURL];
		[[FileWatcher shared] watch:to notify:self];			
		self.fileURL = to;
		self.data = [NSString stringWithString:string];	
		return YES;
	}
	return NO;
}
- (NSString *) autosave:(BOOL) export_only {
	NSString *nameDir = [[self.fileURL path] stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
	NSString *dir = [[Preferences defaultDir] stringByAppendingPathComponent:[NSString stringWithFormat:@"AUTOSAVE/%@",nameDir]];
	NSString *fileName = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",[self basename]]];
	if (export_only)
		return fileName;
	if ([self createDirecoryWithPath:dir])
		[self write:self.data toPath:fileName];
	return nil;
}
- (NSArray *) backups {
		NSFileManager *f = [[NSFileManager alloc] init];
		NSString *nameDir = [[self.fileURL path] stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
		NSString *dir = [[Preferences defaultDir] stringByAppendingPathComponent:[NSString stringWithFormat:@"BACKUP/%@",nameDir]];
		NSError *err;
		NSArray *content = [f contentsOfDirectoryAtPath:dir error:&err];
		NSMutableArray *ret = [NSMutableArray array];
		int max = 20;
		if (!err) {
			for (NSString *c in content) {
				if (max < 1)
					break;
				NSString *file = [dir stringByAppendingPathComponent:c];
				BOOL is_dir = NO;
				if ([f fileExistsAtPath:file isDirectory:&is_dir] && is_dir == NO) {
					[ret addObject:file]; 
					max--;
				}
			}
			return [NSArray arrayWithArray:ret];
		}
		return nil;  /* silence */
}
- (void) backup {
	NSString *nameDir = [[self.fileURL path] stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
	NSString *dir = [[Preferences defaultDir] stringByAppendingPathComponent:[NSString stringWithFormat:@"BACKUP/%@",nameDir]];
	NSString *fileName = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%lu.%@",time(NULL),[self.fileURL pathExtension]]];
	if ([self createDirecoryWithPath:dir])
		[self write:self.data toPath:fileName];
}
- (NSURL *) temporaryFileURL {
	int retry = 5;
	NSString *name;
	NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyy-MM-dd"];
	NSString *dir = [[Preferences defaultDir] stringByAppendingPathComponent:[NSString stringWithFormat:@"TEMPORARY/%@",[formatter stringFromDate:[NSDate date]]]];
ret:
	
	name = [dir stringByAppendingPathComponent: [NSString stringWithFormat: @"TEMP-%lu.%ld.txt",time(NULL),random()]];
	NSFileManager *f = [[NSFileManager alloc] init];
	if ([f fileExistsAtPath:name]) {
		retry--;
		goto ret;
	}
	if (retry < 1) {
		return nil;
	}
	if (![self createDirecoryWithPath:dir] || ![self write:@"" toPath:name])
		return nil;
	return [NSURL fileURLWithPath:name];
}
- (NSString *) basename {
	return [[self.fileURL pathComponents] lastObject];
}
- (BOOL) write:(NSString *) string toPath:(NSString *) file {
	return [self write:string toURL:[NSURL fileURLWithPath:file]];
}
- (BOOL) write:(NSString *) string toURL:(NSURL *) file {
	NSError *err;
	[string writeToURL:file atomically:NO encoding:(encoding > 0 ? encoding : NSUTF8StringEncoding) error:&err];
	if (err) {
		[self noChoiceAlert:[err localizedDescription] withURL:self.fileURL];
		return NO;
	}
	return YES;
}
- (BOOL) createDirecoryWithPath:(NSString *) path {
	return [self createDirectoryWithURL:[NSURL fileURLWithPath:path]];
}
- (BOOL) createDirectoryWithURL:(NSURL *) dir {
	NSError *err;
	NSFileManager *f = [[NSFileManager alloc] init];
	BOOL is_dir = NO;
	if ([f fileExistsAtPath:[dir path] isDirectory:&is_dir]) {
		if (is_dir)
			return YES;
	}
	[f createDirectoryAtURL:dir withIntermediateDirectories:YES attributes:nil error:&err];
	if (err) {
		[self noChoiceAlert:[err localizedDescription] withURL:dir];
		return NO;
	}
	return YES;
}
- (BOOL) unlinkIfTemporary {
	if (temporary) {
		return [self unlink:self.fileURL];
	}
	return NO;
}
- (BOOL) unlink:(NSURL *) url {
	NSFileManager *f = [[NSFileManager alloc] init];
	NSError *err;
	[f removeItemAtURL:url error:&err];
	return (err ? NO : YES);
}
- (void) close {
	[[FileWatcher shared] unwatch:self.fileURL];
	if ([self.data length] < 1) {
		[self unlinkIfTemporary];
	}
}
@end
