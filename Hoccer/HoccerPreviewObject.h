//
//  HoccerObject.h
//  Hoccer
//
//  Created by Philip Brechler on 15.03.12.
//  Copyright (c) 2012 Hoccer GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Quartz/Quartz.h>

@interface HoccerPreviewObject : NSObject <QLPreviewItem> {
    NSString *filePath;
    NSDate *timeTag;
}
   
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) NSDate *timeTag;

- (NSURL *)previewItemURL;
- (NSString *)previewItemTitle;

- (void)setFilePath:(NSString *)path andTimeTag:(NSDate *)date;
@end
