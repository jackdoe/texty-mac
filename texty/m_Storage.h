#import <Foundation/Foundation.h>
#define TEXTY_DIR @"TEXTY_DATA"

@interface m_Storage : NSObject {
	NSString *data;
	NSURL *fileURL;
	NSArray *existing_backups;
	BOOL temporary;
	NSStringEncoding encoding;
}
@property (retain) NSURL *fileURL;
@property (retain) NSString *data;
@property (assign) BOOL temporary;
@property (retain) NSArray *existing_backups;
@property (assign) NSStringEncoding encoding;
- (BOOL) open:(NSURL *) URL;
- (BOOL) close:(BOOL) save;
- (NSURL *) temporaryFileURL;
- (BOOL) overwrite:(NSString *) withString;
- (BOOL) overwrite;
- (BOOL) migrate:(NSURL *) to;
- (NSString *) basename;
- (BOOL) write:(NSString *) string toURL:(NSURL *) file;
- (BOOL) write:(NSString *) string toPath:(NSString *) file;
- (BOOL) createDirecoryWithPath:(NSString *) path;
- (BOOL) createDirectoryWithURL:(NSURL *) dir;
- (void) backup;
- (NSArray *) backups;
- (NSString *) autosave:(BOOL) export_only;
- (BOOL) convertTo:(NSStringEncoding) enc;
- (NSArray *) encodings;
- (NSString *) currentEncoding;
@end
