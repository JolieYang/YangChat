//
//  YCWebSocketOperationManager.m
//  YangChat
//
//  Created by Jolie on 15/12/20.
//  Copyright (c) 2015年 Jolie. All rights reserved.
//

#import "YCWebSocketOperationManager.h"
#import "UtilsMacro.h"
#import "SRWebSocket.h"
#define SOCKET_URL @"ws://121.42.62.246:21941/chat"

@interface YCWebSocketOperationManager()<SRWebSocketDelegate>

@end

@implementation YCWebSocketOperationManager{
    SRWebSocket *_webSocket;
    NSMutableDictionary *_successBlocks;
    NSMutableDictionary *_errorBlocks;
}

- (id)init {
    if ([super init]) {
        _successBlocks = [[NSMutableDictionary alloc] init];
        _errorBlocks = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

+ (YCWebSocketOperationManager *)sharedManager {
    static YCWebSocketOperationManager *sharedManager = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (void)connectSocket {
    if (_webSocket == nil) {
        _webSocket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:SOCKET_URL]];
        _webSocket.delegate = self;
        [_webSocket open];
    }
}

- (void)closeSocket {
    if (_webSocket) {
        _webSocket.delegate = nil;
        [_webSocket closeWithCode:SRStatusCodeNormal reason:@"closeByUser"];
        _webSocket = nil;
    }
}

- (void)reconnectSocket {
    _webSocket.delegate = nil;
    [_webSocket close];
    
    _webSocket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:SOCKET_URL]];
    _webSocket.delegate = self;
    [_webSocket open];
}

// SR_OPEN 状态为open 时才能发送数据
- (void)send:(BaseRequest *)request success:(void (^)(NSDictionary * result,NSString *message))successBlock error:(void(^)(NSString *code, NSString *message))errorBlock {
    if (_webSocket.readyState == SR_OPEN) {
        if (successBlock) {
            [_successBlocks setObject:successBlock forKey:request.echo];
        }
        if (errorBlock) {
            [_errorBlocks setObject:errorBlock forKey:request.echo];
        }
        
        
    }
    else if (_webSocket.readyState == SR_CONNECTING) {
        WS(weakSelf);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"1");
            [weakSelf send:request success:successBlock error:errorBlock];
            NSLog(@"2");
            return;
        });
        return;
    }
    else if (_webSocket.readyState == SR_CLOSED || _webSocket.readyState == SR_CLOSING) {
        errorBlock(@"-1", @"网络不给力");
        return;
    }
    NSLog(@"3");
    
    
    
}

#pragma --mark SRWebSocketDelegate
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSLog(@"websocket didReceiveMessage--收到消息");
    NSRange range = [message rangeOfString:@"{"];
    if (range.length > 0 && range.location > 0) {
        message = [message substringFromIndex:range.location];
    }
    NSData *returnData = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:returnData options:NSJSONReadingMutableContainers error:nil]; // 转换json数据
    NSString *code = [dict objectForKey:@"code"];
    NSString *msg = [dict objectForKey:@"msg"];
    NSString *echo= [dict objectForKey:@"echo"];
    NSDictionary *data = [dict objectForKey:@"data"];
    
    if (echo) {
        if ([code isEqualToString:@"SUCCEED"]) {
            SuccessBlock successBlock = [_successBlocks objectForKey:echo];
            if (successBlock) {
                successBlock(data,msg);
                [_successBlocks removeObjectForKey:echo];
            }
        }
        else {
            ErrorBlock errorBlock = [_errorBlocks objectForKey:echo];
            if (errorBlock) {
                errorBlock(code, msg);
                [_errorBlocks removeObjectForKey:echo];
            }
        }
        
        // 收到私聊消息
        if ([[dict objectForKey:@"type"] isEqualToString:@"send_to_one"]) {
            if (_receiveMessage) {
                _receiveMessage(dict, msg);
            }
        }
        
        
    }
    return;
}

#pragma --mark SRWebSocketDelegate @optional
- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    NSLog(@"websocket did open--连接上了");
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    NSLog(@"websocket didFailWithError--连接失败");
    _webSocket = nil;
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    NSLog(@"websocket did closeWithCode--连接关闭");
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload {
    NSLog(@"websocket didReceivePong");
}




    

@end
