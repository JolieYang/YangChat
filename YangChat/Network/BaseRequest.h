//
//  BaseRequest.h
//  YangChat
//  todo 多层对象转字典v2
//  Created by Jolie on 15/12/20.
//  Copyright (c) 2015年 Jolie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YYModel.h"

@interface BaseRequest : NSObject

@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *echo;

@end

// 测试


@interface Login_request : BaseRequest

@property (nonatomic, strong) NSString *a;
@property (nonatomic, strong) NSString *obj;
@property (nonatomic, strong) NSString *act;
@property (nonatomic, strong) NSString *pid;
@property (nonatomic, strong) NSString *clientType;
@end
