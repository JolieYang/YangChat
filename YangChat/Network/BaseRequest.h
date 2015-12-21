//
//  BaseRequest.h
//  YangChat
//
//  Created by Jolie on 15/12/20.
//  Copyright (c) 2015年 Jolie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BaseRequest : NSObject

@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *echo;

@end
