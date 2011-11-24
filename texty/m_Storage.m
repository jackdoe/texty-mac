#import "m_Storage.h"
@implementation m_Storage
@synthesize fileURL, data,temporary,existing_backups;
- (BOOL) open:(NSURL *) URL {
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
	self.data = [NSString stringWithContentsOfURL:URL encoding:NSUTF8StringEncoding error:&err];
	if (err) {
		NSRunAlertPanel(@"failed to open file",[NSString stringWithFormat:@"error: %@",[err localizedDescription]] , nil,nil,@"Close");
		return FALSE;
	}
	if (!temporary)
		[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:self.fileURL];
	self.existing_backups = [self backups];
	return TRUE;
}
- (BOOL) close:(BOOL) save {
	if (save) {
		[self overwrite];
	}
	self.data = nil;
	self.fileURL = nil;
	return TRUE;
}
- (BOOL) overwrite:(NSString *) withString {
	if (![self.data isEqualToString:withString]) {
		[self backup];
		self.data = [NSString stringWithString:withString];
		return [self overwrite];
	}
	return YES;
}
- (BOOL) migrate:(NSURL *) to {
	self.fileURL = to;
	self.temporary = NO;
	[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:to];
	return [self overwrite];
}
- (BOOL) overwrite {
	if (!self.fileURL)
		return NO;
	self.existing_backups = [self backups];
	[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:self.fileURL];
	return [self write:self.data toURL:self.fileURL];
}
- (NSString *) autosave:(BOOL) export_only {
	NSString *nameDir = [[self.fileURL path] stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
	NSString *dir = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/AUTOSAVE/%@",TEXTY_DIR,nameDir]];
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
		NSString *dir = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/BACKUP/%@",TEXTY_DIR,nameDir]];
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
	NSString *dir = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/BACKUP/%@",TEXTY_DIR,nameDir]];
	NSString *fileName = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%lu.%@",time(NULL),[self.fileURL pathExtension]]];
	if ([self createDirecoryWithPath:dir])
		[self write:self.data toPath:fileName];
}
- (NSURL *) temporaryFileURL {
	int retry = 5;
	NSString *name;
	NSString *dir = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/TEMPORARY",TEXTY_DIR]];
ret:
	
	name = [dir stringByAppendingPathComponent: [NSString stringWithFormat: @"TEMP-%lu.txt",time(NULL) * rand()]];
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
	[string writeToURL:file atomically:YES encoding:NSUTF8StringEncoding error:&err];
	if (err) {
		NSRunAlertPanel(@"failed to overwrite file",[NSString stringWithFormat:@"error: %@",[err localizedDescription]] , nil,nil,@"Close");
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
		NSRunAlertPanel(@"failed to create directory",[NSString stringWithFormat:@"error: %@",[err localizedDescription]] , nil,nil,@"Close");
		return NO;
	}
	return YES;
}
@end
