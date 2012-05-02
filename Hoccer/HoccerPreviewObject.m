//
//  HoccerObject.m
//  Hoccer
//
//  Created by Philip Brechler on 15.03.12.
//  Copyright (c) 2012 Hoccer GmbH. All rights reserved.
//

#import "HoccerPreviewObject.h"

@implementation HoccerPreviewObject

@synthesize filePath;
@synthesize timeTag;

- (NSURL *)previewItemURL {
    return [NSURL fileURLWithPath:self.filePath];
}
- (NSString *)previewItemTitle {
    return [self.filePath lastPathComponent];
}

- (void)setFilePath:(NSString *)path andTimeTag:(NSDate *)date {
    self.filePath = [path copy];
    self.timeTag = [date copy];
}
@end
