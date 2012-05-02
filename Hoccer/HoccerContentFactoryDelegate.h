//
//  HoccerContentFactoryDelegate.h
//  Hoccer
//
//  Created by Philip Brechler on 16.03.12.
//  Copyright (c) 2012 Hoccer GmbH. All rights reserved.
//

#import "HoccerContentFactory.h"

@protocol HoccerContentFactoryDelegate
-(void)hoccerContentFactoryHasFinishedDataRepresentation:(NSDictionary *)repr;
-(void)hoccerContentFactoryDidReceiveFile:(NSData *)file forURI:(NSString *)string response:(NSHTTPURLResponse *)response;
@end
