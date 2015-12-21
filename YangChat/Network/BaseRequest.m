//
//  BaseRequest.m
//  YangChat
//
//  Created by Jolie on 15/12/20.
//  Copyright (c) 2015年 Jolie. All rights reserved.
//

#import "BaseRequest.h"

@implementation BaseRequest

-(id)init {
    self = [super init];
    if (self) {
        NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
        self.echo = [NSString stringWithFormat:@"%.0f", interval];
//        self.type = [NSString stringWithUTF8String:object_getClassName(self)];
        NSArray *methods = [[NSString stringWithUTF8String:object_getClassName(self)] componentsSeparatedByString:@"_"];
        if (methods.count > 0) {
            self.type = [methods[0] lowercaseString];
        }
    }
    
    return self;
}

@end
