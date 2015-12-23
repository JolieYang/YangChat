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

// 测试
@interface clientInfo : NSObject

@property (nonatomic, strong) NSString *clientType;
@property (nonatomic, strong) NSString *userId;

@end

@interface Login_request : BaseRequest

@property (nonatomic, strong) NSString *a;
@property (nonatomic, strong) NSString *obj;
@property (nonatomic, strong) NSString *act;
@property (nonatomic, strong) NSString *pid;
@property (nonatomic, strong) clientInfo *client_info;

@end
