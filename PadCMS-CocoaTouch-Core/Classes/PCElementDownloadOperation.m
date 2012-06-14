//
//  PCElementDownloadOperation.m
//  Pad CMS
//
//  Created by admin on 02.03.12.
//  Copyright (c) 2012 Adyax. All rights reserved.
//

#import "PCElementDownloadOperation.h"
#import "PCPageElement.h"
#import "PCConfig.h"


@implementation PCElementDownloadOperation

@synthesize element, progressTarget, operationTarget;
@synthesize filePath;

- (id)initWithElement:(PCPageElement*)_element
{
    if (!_element.resource) {
        return nil;
    }
    
    NSString* pathExtension = [[_element.resource pathExtension] lowercaseString];
    NSString* urlStr = nil;
    if ([pathExtension isEqualToString:@"png"]||[pathExtension isEqualToString:@"jpg"]
        ||[pathExtension isEqualToString:@"jpeg"]) {
        urlStr = [[PCConfig serverURLString] stringByAppendingFormat:@"/resources/768-1024%@",_element.resource];
    } else {
        urlStr = [[PCConfig serverURLString] stringByAppendingPathComponent:[@"/resources/none/" stringByAppendingPathComponent:_element.resource]];
        
        NSLog(@"urlStr=%@",urlStr);
    }
    self = [self initWithURL:[NSURL URLWithString:urlStr]];
    if (self) {
        self.element = _element;
    }
    
    return self;
}

- (id)initWithURL:(NSURL *)url
// See comment in header.
{
    
    self = [super initWithURL:url];
    if (self != nil) {
		_isProgressShown = NO;
		_lengthOfDownloadedData = 0;
        _expectedContentLength = 0.0f;
    }
    return self;
}

- (NSOutputStream*)streamForFilePath:(NSString*)path
{
    NSString* directoryPath = [path stringByDeletingLastPathComponent];
    BOOL isDir = NO;        
    NSError* directoryCreateError = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:&isDir]) {
        if (!isDir) {            
            [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath
                                      withIntermediateDirectories:YES attributes:nil error:&directoryCreateError];             
        }
    }
    
    if (!directoryCreateError) {        
        return [[[NSOutputStream alloc] initToFileAtPath:path append:NO] autorelease];
    }
    
    return nil;
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (!self.responseOutputStream) {
        self.responseOutputStream = [self streamForFilePath:[self.filePath stringByAppendingString:@".temp"]];
    }
	[super connection:connection didReceiveData:data];
	_lengthOfDownloadedData += [data length];
	if (_isProgressShown) {
        if (_expectedContentLength == 0.0f) {
            _expectedContentLength = (float) [self.lastResponse expectedContentLength];
        }
		if (_expectedContentLength!=-1.0) {
			[self performSelector:@selector(progressOfDownloadOperation) onThread:_progressWatchingThread 
                       withObject:nil waitUntilDone:NO];
      }
		
	}
}

- (void)setPogresShow:(BOOL)show toThread:(NSThread*)thread andTarget:(id)target
{
	_isProgressShown = show;
	if (_isProgressShown) {
		_progressWatchingThread = thread;
		progressTarget = target;
	}
}

-(float)currentProgress
{
  return ((CGFloat) _lengthOfDownloadedData / (CGFloat)_expectedContentLength);
}

- (void)progressOfDownloadOperation
{
	//NSLog(@"progress = %@", progress);
    CGFloat progress = ((CGFloat) _lengthOfDownloadedData / (CGFloat)_expectedContentLength);
 
  

	[self.progressTarget progressOfDownloading:progress forElement:element];
	
}

- (BOOL)saveData:(NSData*)data toPath:(NSString*)path
{
    if (path&&[path length]&&data) {        
        NSString* directoryPath = [path stringByDeletingLastPathComponent];
        BOOL isDir = NO;        
        NSError* directoryCreateError = nil;
        if (![[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:&isDir]) {
            if (!isDir) {            
                [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath
                                          withIntermediateDirectories:YES attributes:nil error:&directoryCreateError];             
            }
        }         
        if (!directoryCreateError&&data) {
            
            NSError* writingFileError = nil;
            [data writeToFile:path 
                      options:NSDataWritingFileProtectionNone 
                        error:&writingFileError];
            if (writingFileError) {
                self->_error = writingFileError;
            }
        };
    }
    return NO;
}

- (void)finishprogressDownloading
{
    [self.progressTarget progressOfDownloading:100.0f forElement:element];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection
// See comment in header.
{
    if (_isProgressShown) {
        [self performSelector:@selector(finishprogressDownloading) onThread:_progressWatchingThread 
                   withObject:nil waitUntilDone:NO];
    }
    
    NSString* tempFile = [self.filePath stringByAppendingString:@".temp"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:tempFile]) {
        [[NSFileManager defaultManager] moveItemAtPath:tempFile toPath:self.filePath error:nil];
    } else {
       [self saveData:self->_dataAccumulator toPath:filePath];   
    }      
    [super connectionDidFinishLoading:connection];
 
    if (operationTarget&&[operationTarget respondsToSelector:@selector(endDownloadingPCPageElementOperation:)]) {
        [operationTarget performSelectorOnMainThread:@selector(endDownloadingPCPageElementOperation:) withObject:self waitUntilDone:YES];
    }
}

@end
