//
//  ACMessageSenderManager.h
//  ACIMLib
//
//  Created by 子木 on 2022/6/28.
//

#import <Foundation/Foundation.h>
#import "ACStatusDefine.h"
#import "ACMessagePushConfig.h"
#import "ACSendMessageConfig.h"

NS_ASSUME_NONNULL_BEGIN

@class ACMessage,ACMessageContent;
@interface ACMessageSenderManager : NSObject

+ (ACMessageSenderManager *)shared;

- (ACMessage *)sendMessage:(ACMessage *)message
              toUserIdList:(NSArray *)userIdList
                sendConfig:(ACSendMessageConfig *)sendConfig
                  progress:(void (^)(int progress, ACMessage *message))progressBlock
                   success:(void (^)(ACMessage * message))successBlock
                     error:(void (^)(ACErrorCode nErrorCode, ACMessage * message))errorBlock;

- (BOOL)cancelSendMediaMessage:(long)messageId;
@end

NS_ASSUME_NONNULL_END
