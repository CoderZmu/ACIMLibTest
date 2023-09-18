//
//  ACSecretKey.h
//  Sugram
//
//  Created by gossip2 on 16/12/17.
//  Copyright © 2016年 gossip. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACDialogSecretKeyMo.h"

@interface ACSecretKey : NSObject
+(ACSecretKey*)instance;
-(NSString*)dbSecretKey;
- (BOOL)hasLoadedSecretKeyForDialogID:(NSString *)dialogID;
-(NSString*)getDialogSecretKeyByDialogID:(NSString *)dialogID;
- (ACDialogSecretKeyMo*)getDialogAesKeyWithDialogID:(NSString *)dialogID;

// 获取会话AES密钥（如果存在本地有的key和需要请求的key，则会先回调本地有的key，然后请求key并回调请求的key）
-(void)getDialogAesKeyWithDialogIDArr:(NSArray<NSString*>*)dialogIDArr withCompletion:(void(^)(NSDictionary*, BOOL remote))completion;

- (void)loadDialogAesKeysWithDidlogIDs:(NSArray *)dialogIDs withCompletion:(void (^)(NSDictionary *))completion;
@end
