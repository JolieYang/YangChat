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
#import <objc/runtime.h>
#import "YYModel.h"
//#define SOCKET_URL @"ws://121.42.62.246:21941/chat"
#define SOCKET_URL @"ws://121.40.16.113:51717/yjs"

@interface YCWebSocketOperationManager()<SRWebSocketDelegate>

@property (nonatomic, strong) NSMutableDictionary *successBlocks;
@property (nonatomic, strong) NSMutableDictionary *errorBlocks;
@end

@implementation YCWebSocketOperationManager{
    SRWebSocket *_webSocket;
//    NSMutableDictionary *_successBlocks;
//    NSMutableDictionary *_errorBlocks;
}

- (id)init {
    if ([super init]) {
        _successBlocks = [[NSMutableDictionary alloc] init];
        _errorBlocks = [[NSMutableDictionary alloc] init];
        [self connectSocket];
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
    NSLog(@"begin connect");
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
        NSLog(@"send 3");
        if (successBlock) {
            [_successBlocks setObject:successBlock forKey:request.echo];
            NSLog(@"send successBlock");
        }
        if (errorBlock) {
            [_errorBlocks setObject:errorBlock forKey:request.echo];
            NSLog(@"send errorBlock");
        }
        
        NSData *jsonData = [request yy_modelToJSONData];
        NSString *reqString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSLog(@"rose show reqString %@", reqString);
        reqString = [[[reqString stringByReplacingOccurrencesOfString:@"\n" withString:@""]stringByReplacingOccurrencesOfString:@" " withString:@""]stringByAppendingString:@"\n"];
        NSLog(@"rose show reqString %@", reqString);
        [_webSocket send:reqString];
        
    }
    else if (_webSocket.readyState == SR_CONNECTING) {
        WS(weakSelf);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"send 1");
            [weakSelf send:request success:successBlock error:errorBlock];
            NSLog(@"send 2");
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
    NSLog(@"websocket didReceiveMessage--收到消息 %@", message);
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


// 对象转字典
- (NSDictionary *)dictionaryRepresentation {
    unsigned int count = 0;
    objc_property_t *properties = class_copyPropertyList([self class], &count);// 获取注册类的属性列表
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:count];
    NSDictionary *keyValueMap = [self attributeMapDictionary];
    
    for (int i = 0; i < count; i++) {
        NSString *key = [NSString stringWithUTF8String:property_getName(properties[i])];
        id value = [self valueForKey:key];
        key = [keyValueMap objectForKey:key];
        // only ad it to dictionary if it is not nil
        if (key && value) {
            [dict setObject:value forKey:key];
        }
    }
    free(properties);
    return dict;
}

- (NSDictionary *)attributeMapDictionary {
    return nil;//  字典中键名与对象属性名一样
}

// 字典转对象
- (id)initWithDict:(NSDictionary *)aDict {
    self = [super init];
    
    if (self) {
        [self setAttributesDictionary:aDict];
    }
    
    return self;
}

// 建立映射关系
- (void)setAttributesDictionary:(NSDictionary *)aDict {
    // 获取映射字典
    NSDictionary *mapDict = [self attributeMapDictionary];
    
    if (mapDict == nil) {// 默认映射字典
        NSMutableDictionary *tmpDict = [NSMutableDictionary dictionaryWithCapacity:aDict.count];
        for (NSString *key in aDict) {
            [tmpDict setObject:key forKey:key];
        }
        mapDict = tmpDict;
    }
    
    NSEnumerator *keyEnumerator = [mapDict keyEnumerator];// 遍历映射字典,获取所有的键值,objectEnumerator得到里面的对象
    id attributeName = nil;
    while (attributeName = [keyEnumerator nextObject]) {// 遍历输出键值
        SEL setter = [self _getSetterWithAttributeName:attributeName];// 获得属性的setter
        if ([self respondsToSelector:setter]) {// 判断自己是否有相应的方法或检查是否响应指定的消息
            NSString *aDictKey = [mapDict objectForKey:attributeName]; // 获取mapDict的值，即获取传入字典的键
            id aDictValue = [aDict objectForKey:aDictKey];// 获取传入字典的值, 即赋给属性的值
            
            [self performSelectorOnMainThread:setter withObject:aDictValue waitUntilDone:[NSThread isMainThread]];
        }
    }
}
- (SEL)_getSetterWithAttributeName: (NSString *)attributeName {
    NSString *firstAlpha = [[attributeName substringToIndex:1] uppercaseString];
    NSString *otherAlpha = [attributeName substringFromIndex:1];
    NSString *setterMethodName = [NSString stringWithFormat:@"set%@%@:" , firstAlpha, otherAlpha];
    return NSSelectorFromString(setterMethodName);
}

@end
