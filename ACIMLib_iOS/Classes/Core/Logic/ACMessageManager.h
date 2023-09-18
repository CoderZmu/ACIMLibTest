//
//  SGACMessageMoManager.h
//  Sugram
//
//  Created by bu88 on 2017/7/31.
//  Copyright © 2017年 gossip. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACBase.h"
#import "ACMessageMo.h"
#import "ACChatMessageMo.h"
#import "ACDialogMo.h"
#import "ACStatusDefine.h"

@interface ACMessageManager : NSObject
ACSingletonH();

- (ACMessageMo *)getMessageWithLocalId:(long)localId dilogId:(NSString *)dialogId;
- (ACMessageMo *)getMessageWithRemoteId:(long)remoteId dilogId:(NSString *)dialogId;
- (ACMessageMo *)getMessageWithMsgId:(long)msgId dilogId:(NSString *)dialogId;
- (ACMessageMo *)getMessageWithMsgId:(long)msgId;
- (ACMessageMo *)getMessageWithRemoteId:(long)remoteId;

- (NSArray *)getMessagesWithDialogId:(NSString *)dialogId count:(int)num msgId:(long)msgId isForward:(BOOL)isForward messageTypes:(NSArray *)messageTypes;
- (NSArray *)getMessagesWithDialogId:(NSString *)dialogId count:(int)num recordTime:(long)recordTime isForward:(BOOL)isForward messageTypes:(NSArray *)messageTypes;
- (NSArray *)getMessagesV2WithDialogId:(NSString *)dialogId count:(int)num recordTime:(long)recordTime isForward:(BOOL)isForward;

- (void)updateMessage:(ACMessageMo *)message;

- (NSArray *)storeAndFilterMessageList:(NSArray *)messageList isOldMessage:(BOOL)isOldMessage;

- (void)deleteMessageWithMsgIds:(NSArray *)msgIds dialogId:(NSString *)dialogId;

- (void)clearMessageWithDialogId:(NSString *)dialogId beforeSentTime:(long)sentTime clearRemote:(BOOL)clearRemote complete:(void(^)(ACErrorCode code))completeBlock;

- (ACMessageMo *)getFirstUnreadMessageWithDilogId:(NSString *)dialogId;
- (NSArray *)getUnreadMentionedMessagesWithDialogId:(NSString *)dialogId;

- (BOOL)changeLocalMessageAsRecallStatusWithRemoteId:(long)remoteId dialogId:(NSString *)dialogId recallTime:(long)recallTime extra:(NSString *)extra finalMessage:(ACMessageMo **)finalMessage;
- (ACMessageMo *)changeMessageAsRecallStatus:(ACMessageMo *)message recallTime:(long)recallTime  extra:(NSString *)extra;

- (void)updateMessageAckWithDialogId:(NSString *)dialogId msgIds:(NSArray *)msgIds withMessageReadType:(ACMessageReadType)readType time:(long)time;

- (NSArray<ACMessageMo *> *)searchMessagesWithDialogId:(NSString *)dialogId
                                             keyword:(NSString *)keyword
                                               count:(int)count
                                           recordTime:(long long)recordTime;

- (ACMessageMo *)generateBaseMessage:(NSString *)dialogId;

@end
