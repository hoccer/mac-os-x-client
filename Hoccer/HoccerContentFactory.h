//
//  HoccerContentFactory.h
//  Hoccer
//
//  Created by Philip Brechler on 16.03.12.
//  Copyright (c) 2012 Hoccer GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Hoccer.h"
#import "HoccerContentFactoryDelegate.h"

@interface HoccerContentFactory : NSObject <HCFileCacheDelegate> {
    NSString *contentMimeType;
    HCFileCache *fileCache;
    id <HoccerContentFactoryDelegate> delegate;
}

@property (retain, nonatomic) id <HoccerContentFactoryDelegate> delegate;


+ (HoccerContentFactory *)sharedContentFactory;
- (void)sendingItemWithFile:(NSURL *)fileString;
- (void)sendingItemWithString:(NSString *)string;
- (void)sendingItemWithvCardString:(NSString *)string;

- (void)receiveFile:(NSString *)file;
- (NSString*) mimeTypeForFileAtPath: (NSString *) path;
@end
