//
//  SGACMessageMoManager.m
//  Sugram
//
//  Created by bu88 on 2017/7/31.
//  Copyright © 2017年 gossip. All rights reserved.
//

#import "ACMessageManager.h"
#import "ACBase.h"
#import "ACDialogManager.h"
#import "ACChatMessageMo.h"
#import "ACDatabase.h"
#import "ACActionType.h"
#import "ACServerTime.h"
#import "ACMessageType.h"
#import "ACMessageSerializeSupport.h"
#import "ACConnectionListenerProtocol.h"
#import "ACFileManager.h"
#import "ACDialogIdConverter.h"
#import "ACAccountManager.h"
#import "ACNetErrorConverter.h"
#import "ACConnectionListenerManager.h"
#import "ACSendMessageStore.h"
#import "ACDeleteChatMessagePacket.h"
#import "ACClearChatHistoryPacket.h"

@interface ACMessageManager ()<ACConnectionListenerProtocol>
@end

@implementation ACMessageManager
SGSingletonM();

- (instancetype)init {
    self = [super init];
    [[ACConnectionListenerManager shared] addListener:self];
    return self;
}

- (void)userDataDidLoad {
    @synchronized (self) {
        ACMessageMoROWID = [[ACDatabase DataBase] selectLatestMsgId];
        ACMessageHistoryROWID = [[ACDatabase DataBase] selectOldestMsgId];
        
        if (ACMessageMoROWID == 0) {
            ACMessageMoROWID = INT32_MAX;
            ACMessageHistoryROWID = ACMessageMoROWID - 1;
        }
    }
}


- (ACMessageMo *)getMessageWithLocalId:(long)localId dilogId:(NSString *)dialogId {
    if (!localId) return nil;
    
    return [[ACDatabase DataBase] selectMessageWithLocalId:localId dilogId:dialogId];
}

- (ACMessageMo *)getMessageWithRemoteId:(long)remoteId dilogId:(NSString *)dialogId{
    return [[ACDatabase DataBase] selectMessageWithRemoteId:remoteId dilogId:dialogId];;
}

- (ACMessageMo *)getMessageWithMsgId:(long)msgId dilogId:(NSString *)dialogId {
    return [[ACDatabase DataBase] selectMessageWithMsgId:msgId dilogId:dialogId];
}

- (ACMessageMo *)getMessageWithMsgId:(long)msgId {
    NSString *dialogId = [[ACDatabase DataBase] selectDialogIdWithMsgId:msgId];
    if (!dialogId.length) return nil;
    return [[ACDatabase DataBase] selectMessageWithMsgId:msgId dilogId:dialogId];
}

- (ACMessageMo *)getMessageWithRemoteId:(long)remoteId {
    NSString *dialogId = [[ACDatabase DataBase] selectDialogIdWithRemoteId:remoteId];
    if (!dialogId.length) return nil;
    return [[ACDatabase DataBase] selectMessageWithRemoteId:remoteId dilogId:dialogId];
}

- (NSArray *)getMessagesWithDialogId:(NSString *)dialogId count:(int)num msgId:(long)msgId isForward:(BOOL)isForward messageTypes:(NSArray *)messageTypes{
    return [[ACDatabase DataBase] selectMessageWithDialogId:dialogId count:num baseMsgId:msgId isForward:isForward messageTypes:messageTypes];
}

- (NSArray *)getMessagesWithDialogId:(NSString *)dialogId count:(int)num recordTime:(long)recordTime isForward:(BOOL)isForward messageTypes:(NSArray *)messageTypes {
    if (isForward && ![[ACDatabase DataBase] isExistMessageWithDialogId:dialogId forSendTime:recordTime]) {
        recordTime = -1;
    }
    return [[ACDatabase DataBase] selectMessageWithDialogId:dialogId count:num baseRecordTime:recordTime isForward:isForward messageTypes:messageTypes];
}

- (NSArray *)getMessagesV2WithDialogId:(NSString *)dialogId count:(int)num recordTime:(long)recordTime isForward:(BOOL)isForward  {
    
    if (isForward) {
        // DESC
        return [[ACDatabase DataBase] selectPreviousMessageWithDialogId:dialogId count:num baseRecordTime:recordTime minTime:-1] ;
    } else {
        // ASC
        return [[[[ACDatabase DataBase] selectNextMessageWithDialogId:dialogId count:num baseRecordTime:recordTime maxTime:-1] reverseObjectEnumerator] allObjects];
    }
}

- (void)updateMessage:(ACMessageMo *)message {
    if (!message.Property_ACMessage_msgId) return;
    [[ACDatabase DataBase] updateMessage:message];
}

- (NSArray *)storeAndFilterMessageList:(NSArray *)messageList isOldMessage:(BOOL)isOldMessage {
    NSMutableArray *retArray = [NSMutableArray array];
    NSMutableArray *saveMessageArray = [NSMutableArray array];
    
    [messageList enumerateObjectsUsingBlock:^(ACMessageMo * _Nonnull message, NSUInteger idx, BOOL * _Nonnull stop) {
    
        // 非存储类消息处理
        if (![[ACMessageSerializeSupport shared] messageShouldPersisted:message.Property_ACMessage_objectName]) {
            if (isOldMessage || !message.Property_ACMessage_localId || ![[ACSendMessageStore shared] has:message.Property_ACMessage_localId]) {
                [retArray addObject:message];
            }
            if (!isOldMessage && message.Property_ACMessage_localId) {
                // 移除本端发送队列中的消息
                [[ACSendMessageStore shared] remove:message.Property_ACMessage_localId];
            }
            return;
        }
        
        
        // 发出的消息
        if (message.Property_ACMessage_localId) {
            if (!isOldMessage) {
                // 移除本端发送队列中的消息
                [[ACSendMessageStore shared] remove:message.Property_ACMessage_localId];
            }
            
            ACMessageMo *oldMessage = [[ACDatabase DataBase] selectMessageWithLocalId:message.Property_ACMessage_localId dilogId:message.Property_ACMessage_dialogIdStr];
 
            if (oldMessage) {
                message.Property_ACMessage_msgId = oldMessage.Property_ACMessage_msgId;
                message.Property_ACMessage_mediaAttribute = oldMessage.Property_ACMessage_mediaAttribute;
                message.Property_ACMessage_deliveryState = ACMessageSuccessed;
                
                [saveMessageArray addObject:message];
                if (isOldMessage) {
                    [retArray addObject:message];
                }
                return;
            }
            
        }
        
        
        if ([[ACDatabase DataBase] isExistMessageWithDialogId:message.Property_ACMessage_dialogIdStr forRemoteId:message.Property_ACMessage_remoteId]) {
            if (isOldMessage) {
                [retArray addObject:message];
            }
            return;
        }
        
        message.Property_ACMessage_msgId = isOldMessage ? [self generateHistoryMessageRowId] : [self generateMessageRowId];
        [saveMessageArray addObject:message];
        [retArray addObject:message];
    }];
    
    if (saveMessageArray.count) {
        [[ACDatabase DataBase] updateMessageArr:saveMessageArray];
    }
   
    return retArray.copy;
}


- (void)deleteMessageWithMsgIds:(NSArray *)msgIds dialogId:(NSString *)dialogId {
    NSArray<NSDictionary *> *msgList = [[ACDatabase DataBase] selectMessageBriefInfosWithDialogId:dialogId forMsgIdList:msgIds];
    NSMutableArray *mediaMsgIds = [NSMutableArray array];
    NSMutableArray *remoteIds = [NSMutableArray array];
    for (NSDictionary *obj in msgList) {
        if ([obj[@"isOut"] boolValue] && [obj[@"mediaFlag"] boolValue]) {
            [mediaMsgIds addObject:obj[@"msgId"]];
        }
        [remoteIds addObject:obj[@"remoteId"]];
    }
    
    [[ACDatabase DataBase] deleteMessageWithMsgIds:msgIds dialogId:dialogId];
    if (mediaMsgIds.count) {
        [ACFileManager deleteMsgMediaFilesWithKeys:mediaMsgIds target:dialogId];
    }
    if (remoteIds.count) {
        ACDeleteChatMessagePacket *packet = [[ACDeleteChatMessagePacket alloc] initWithDialogId:dialogId messageRemoteIdList:remoteIds];
        packet.openQoS = YES;
        [packet sendWithSuccessBlockEmptyParameter:nil failure:nil];
    }
    
}

- (void)clearMessageWithDialogId:(NSString *)dialogId beforeSentTime:(long)sentTime clearRemote:(BOOL)clearRemote complete:(void(^)(ACErrorCode code))completeBlock {

    void (^clearLocalBlock)(void) = ^{
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            if (sentTime <= 0) {
                BOOL delResult = [[ACDatabase DataBase] deleteMessageWithDialogId:dialogId];
                if (delResult) {
                    [[ACDialogManager sharedDialogManger] clearAllMessagesUnreadStatusWithDialog:dialogId clearRemote:NO];
                    [ACFileManager deleteAllMsgMediaFilesForTarget:dialogId];
                    [[ACDialogManager sharedDialogManger] flushDialogUpdateTimeByLatestMessageSentTime:dialogId];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    !completeBlock ?: completeBlock(delResult ? AC_SUCCESS : DATABASE_ERROR);
                });
                return;
            }
            
            
            NSArray *mediaMsgIds = [[ACDatabase DataBase] selectOutMediaMessageIdsWithDialogId:dialogId beforeTimeSend:sentTime];
            BOOL delResult = [[ACDatabase DataBase] deleteMessageWithDialogId:dialogId beforeTime:sentTime];
            if (delResult) {
                [[ACDialogManager sharedDialogManger] clearMessagesUnreadStatusWithDialog:dialogId tillTime:sentTime clearRemote:NO];
                if (mediaMsgIds.count) {
                    [ACFileManager deleteMsgMediaFilesWithKeys:mediaMsgIds target:dialogId];
                }
            }
     
            dispatch_async(dispatch_get_main_queue(), ^{
                completeBlock(delResult);
            });
        });
    };
    
    if (clearRemote) {
        [[[ACClearChatHistoryPacket alloc] initWithDialogId:dialogId groupFlag:[ACDialogIdConverter isGroupType:dialogId] offset:sentTime == 0 ? (long)INT32_MAX * 1000 : sentTime] sendWithSuccessBlockEmptyParameter:^{
            clearLocalBlock();
        } failure:^(NSError * _Nonnull error, NSInteger errorCode) {
            dispatch_async(dispatch_get_main_queue(), ^{
                !completeBlock ?: completeBlock([ACNetErrorConverter toAcErrorCodeEnumProperty:errorCode]);
            });
        }];
    } else {
        clearLocalBlock();
    }
    
    
}

- (ACMessageMo *)getFirstUnreadMessageWithDilogId:(NSString *)dialogId {
    long lastReadTime = [[ACDialogManager sharedDialogManger] getDialogLastReadTime:dialogId];
    return [[ACDatabase DataBase] selectFirstUnreadMessage:dialogId afterTime:lastReadTime];
}


- (NSArray *)getUnreadMentionedMessagesWithDialogId:(NSString *)dialogId {
    long lastReadTime = [[ACDialogManager sharedDialogManger] getDialogLastReadTime:dialogId];
    return [[ACDatabase DataBase] selectUnreadMentionedMessagesWithDialogId:dialogId afterTime:lastReadTime count:10];
}


- (BOOL)changeLocalMessageAsRecallStatusWithRemoteId:(long)remoteId dialogId:(NSString *)dialogId recallTime:(long)recallTime extra:(NSString *)extra finalMessage:(ACMessageMo **)finalMessage  {
    if (!recallTime) recallTime = [ACServerTime getServerMSTime];
    ACMessageMo *mo = [self getMessageWithRemoteId:remoteId dilogId:dialogId ];
    if (!mo) return NO;
    
    if ([mo.Property_ACMessage_objectName isEqualToString:[[ACMessageSerializeSupport shared] recallNotificationMessageType]]) {
        return NO;
    }
    
    mo = [self changeMessageAsRecallStatus:mo recallTime:recallTime extra:extra];
    if (finalMessage) *finalMessage = mo;
    [[ACDatabase DataBase] updateMessage:mo];
    return YES;
}

// 将消息体改为撤回消息
- (ACMessageMo *)changeMessageAsRecallStatus:(ACMessageMo *)message recallTime:(long)recallTime extra:(NSString *)extra {
    if ([message.Property_ACMessage_objectName isEqualToString:[[ACMessageSerializeSupport shared] recallNotificationMessageType]]) {
        return message;
    }
    
    message.Property_ACMessage_mediaAttribute = [[ACMessageSerializeSupport shared] changeMessageContentAsRecallStatus:message recallTime:recallTime];
    message.Property_ACMessage_objectName = [[ACMessageSerializeSupport shared] recallNotificationMessageType];
    message.Property_ACMessage_mediaFlag = false;
    message.Property_ACMessage_extra = extra;
    return message;
}


- (void)updateMessageAckWithDialogId:(NSString *)dialogId msgIds:(NSArray *)msgIds withMessageReadType:(ACMessageReadType)readType time:(long)time {

    if (!msgIds.count) return;
    
    NSMutableDictionary *readTypeDic = [NSMutableDictionary dictionary];

    for (NSNumber *msgId in msgIds) {
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        [d ac_setSafeObject:@(readType) forKey:@"readType"];
        [d ac_setSafeObject:@(time) forKey:@"time"];
        readTypeDic[msgId] = d;
    }

    [[ACDatabase DataBase] updateMessageReadType:readTypeDic dialogId:dialogId];
    
}


- (NSArray<ACMessageMo *> *)searchMessagesWithDialogId:(NSString *)dialogId
                                             keyword:(NSString *)keyword
                                               count:(int)count
                                           recordTime:(long long)recordTime {
    if (!keyword.length || count <= 0) return @[];
    return [[ACDatabase DataBase] selectMessagesWithDialogId:dialogId keyword:keyword count:MIN(100, count) baseRecordTime:recordTime];
}




- (NSArray *)reverseObjectEnumerator:(NSArray *)messages {
    return [[[NSMutableArray arrayWithArray:messages] reverseObjectEnumerator] allObjects];
}

- (ACMessageMo *)generateBaseMessage:(NSString *)dialogId {
    
    ACMessageMo *message = [[ACMessageMo alloc] init];
    message.Property_ACMessage_msgSendTime = [self getMessageSentTime];
    message.Property_ACMessage_isOut = true;
    message.Property_ACMessage_dialogIdStr = dialogId;
    message.Property_ACMessage_localId = [self getMessageLocalId];
    message.Property_ACMessage_srcUin = [ACAccountManager shared].user.Property_SGUser_uin;
    message.Property_ACMessage_groupFlag = [ACDialogIdConverter isGroupType:dialogId];
    message.Property_ACMessage_decode = YES;
    message.Property_ACMessage_msgId = [self generateMsgId];
    message.Property_ACMessage_isLocal = YES;
    return message;
}


- (long)generateMsgId {
    return [self generateMessageRowId];
}


long ACMessageMoROWID = 0;
- (long)generateMessageRowId {
    @synchronized (self) {
        ACMessageMoROWID++;
    }
    return ACMessageMoROWID;
}

long ACMessageHistoryROWID = 0;
- (long)generateHistoryMessageRowId {
    long retVal;
    @synchronized (self) {
        ACMessageHistoryROWID--;
        retVal = ACMessageHistoryROWID;
    }
    return retVal;
}

static long UniqueLocalId = 1;
- (long)getMessageLocalId {
    long retVal;
    @synchronized (self) {
        UniqueLocalId++;
        int64_t time = [ACServerTime getServerMSTime] * 10;
        if (UniqueLocalId < time) {
            UniqueLocalId = time;
        }
        retVal = UniqueLocalId;
    }
 
    return retVal;
    
}

static long UniqueSentTime = 1;
- (long)getMessageSentTime {
    long retVal;
    @synchronized (self) {
        UniqueSentTime++;
        int64_t time = [ACServerTime getServerMSTime];
        if (UniqueSentTime < time) {
            UniqueSentTime = time;
        }
        retVal = UniqueSentTime;
    }
 
    return retVal;
    
}


@end
