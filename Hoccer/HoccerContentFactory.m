//
//  HoccerContentFactory.m
//  Hoccer
//
//  Created by Philip Brechler on 16.03.12.
//  Copyright (c) 2012 Hoccer GmbH. All rights reserved.
//

#import "HoccerContentFactory.h"
#import "NSString+URLHelper.h"
#import "NSFileManager+FileHelper.h"
#import "HoccerPreviewObject.h"
#import <Quartz/Quartz.h>

@implementation HoccerContentFactory
@synthesize delegate;

+ (HoccerContentFactory *)sharedContentFactory
{
    static HoccerContentFactory *sharedContentFactory;
    
    @synchronized(self)
    {
        if (!sharedContentFactory){
            sharedContentFactory = [[HoccerContentFactory alloc] init];
        }
        return sharedContentFactory;
    }
}

- (void)sendingItemWithFile:(NSURL *)fileString {
    if (!fileCache) {
        fileCache = [[HCFileCache alloc]initWithApiKey:API_KEY secret:SECRET sandboxed:USES_SANDBOX];
        fileCache.delegate = self;
    }
    NSString *filePath = [fileString path];
    contentMimeType = [self mimeTypeForFileAtPath:filePath];
    [fileCache cacheData:[NSData dataWithContentsOfURL:fileString] withFilename:[fileString.pathComponents lastObject] forTimeInterval:300];
}

- (void)sendingItemWithString:(NSString *)string {
    contentMimeType = @"text/plain";
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	[dict setObject:contentMimeType forKey:@"type"];
    [dict setObject:string  forKey:@"content"];
    
    NSDictionary *content = [NSDictionary dictionaryWithObjectsAndKeys: 
							 [NSArray arrayWithObject:dict], @"data", nil];
    
    [delegate hoccerContentFactoryHasFinishedDataRepresentation:content];
}

- (void)sendingItemWithvCardString:(NSString *)string {
    contentMimeType = @"text/x-vcard";
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	[dict setObject:contentMimeType forKey:@"type"];
    [dict setObject:string  forKey:@"content"];
    
    NSDictionary *content = [NSDictionary dictionaryWithObjectsAndKeys: 
							 [NSArray arrayWithObject:dict], @"data", nil];
    
    [delegate hoccerContentFactoryHasFinishedDataRepresentation:content];
}

- (void)receiveFile:(NSString *)file {
    if (!fileCache) {
        fileCache = [[HCFileCache alloc]initWithApiKey:API_KEY secret:SECRET sandboxed:USES_SANDBOX];
        fileCache.delegate = self;
    }
    [fileCache load:file];
}
- (void)fileCache:(HCFileCache *)fileCache didUploadFileToURI:(NSString *)path {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	[dict setObject:contentMimeType forKey:@"type"];
    NSString *string = path;
	[dict setObject:[string stringByRemovingQuery] forKey:@"uri"];
    
    NSDictionary *content = [NSDictionary dictionaryWithObjectsAndKeys: 
							 [NSArray arrayWithObject:dict], @"data", nil];
    
    [delegate hoccerContentFactoryHasFinishedDataRepresentation:content];
}

- (void)fileCache:(HCFileCache *)fileCache didReceiveResponse:(NSHTTPURLResponse *)response withDownloadedData:(NSData *)data forURI:(NSString *)uri {
    if (response.statusCode == 200){
        [delegate hoccerContentFactoryDidReceiveFile:data forURI:uri response:response];
    }
}

- (NSString*) mimeTypeForFileAtPath: (NSString *) path {
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return nil;
    }

    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)[path pathExtension], NULL);
    CFStringRef mimeType = UTTypeCopyPreferredTagWithClass (UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
    if (!mimeType) {
        return @"application/octet-stream";
    }
    return [NSMakeCollectable((NSString *)mimeType) autorelease];
}
@end
