//
//  YCWebSocketOperationManager.h
//  YangChat
//
//  Created by Jolie on 15/12/20.
//  Copyright (c) 2015年 Jolie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseRequest.h"

@interface YCWebSocketOperationManager : NSObject

+ (YCWebSocketOperationManager *)sharedManager;
typedef void (^SuccessBlock)(NSDictionary *result, NSString *message);
typedef void (^ErrorBlock)(NSString *code, NSString *message);

@property (nonatomic, strong)void (^receiveMessage)(NSDictionary *dict, NSString *message);

- (void)send:(BaseRequest *)request success:(void (^)(NSDictionary * result,NSString *message))successBlock error:(void(^)(NSString *code, NSString *message))errorBlock;




@end
