//
//  ACNotifyMessageProcesser.m
//  ACIMLib
//
//  Created by 子木 on 2022/8/1.
//

#import "ACCommandMessageProcesser.h"
#import "ACMessageType.h"
#import "ACBase.h"
#import "ACMessageManager.h"
#import "ACEventBus.h"
#import "ACActionType.h"
#import "ACServerTime.h"
#import "ACDialogIdConverter.h"
#import "ACMessageMo.h"
#import "ACReportLog.h"
#import "ACMessageSerializeSupport.h"


@implementation ACCommandMessageProcesser

- (NSArray *)processNewMessages:(NSArray<ACMessageMo *> *)messageList ignoreAck:(BOOL)ignoreAck readOffset:(long)readOffset {
    
    NSArray *contentArr = [self processRecallCommand:messageList];
//    if (!ignoreAck) {
//        contentArr = [self processAckCommand:contentArr];
//    }
    [self processSystemCommand:contentArr];
    [self updateOutMessageReadStatusWithMessageArr:contentArr lastReadTime:readOffset];
    return contentArr;
}

- (NSArray *)processHistoryMessages:(NSArray<ACMessageMo *> *)messageList setAllRead:(BOOL)setAllRead readOffset:(long)readOffset {
    NSArray *contentArr = [self processRecallCommand:messageList];
    if (setAllRead) {
        [self setMessageAsReadWithMessageArr:contentArr];
    } else {
        [self updateOutMessageReadStatusWithMessageArr:contentArr lastReadTime:readOffset];
    }
    
    return contentArr;
}

- (NSArray *)processRecallCommand:(NSArray *)messageList  {
    NSMutableArray *excludeNotifyMessageArr = [NSMutableArray array];
    
    for (ACMessageMo* message in messageList) {
        
        
        if ([message.Property_ACMessage_objectName isEqualToString: PrivateChatRecallMessage] ||
            [message.Property_ACMessage_objectName isEqualToString: GroupChatRecallMessage]) {
            
            /*
             撤回处理：
             1. 搜索本地数据库，如果存在匹配的原消息，则更改成撤回状态，成功更改的广播撤回通知
             2. 搜索已接收的消息，如果存在，则替换
             */
            
            NSDictionary * tempDict = [message.Property_ACMessage_mediaAttribute ac_jsonValueDecoded];
            long recallMsgRemoteId = [tempDict[@"msgId"] longValue];
            
            
            ACMessageMo *recallMessage;
            BOOL haveChanged = [[ACMessageManager shared] changeLocalMessageAsRecallStatusWithRemoteId:recallMsgRemoteId dialogId:message.Property_ACMessage_dialogIdStr recallTime:message.Property_ACMessage_msgSendTime extra:message.Property_ACMessage_extra finalMessage:&recallMessage];
            if (haveChanged && recallMessage) {
                // 发出消息被撤回通知
                [[ACEventBus globalEventBus] emit:kRecallMessageNotification withArguments:@[recallMessage]];
            }
            
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"%@ = %%lld", [ACMessageMo loadMsgProperty_ACMessage_remoteIdKey]], recallMsgRemoteId];
            ACMessageMo *recallOriginMessage = [excludeNotifyMessageArr filteredArrayUsingPredicate:predicate].firstObject;
            if (recallOriginMessage) {
                if (!recallMessage) {
                    recallMessage = [[ACMessageManager shared] changeMessageAsRecallStatus:recallOriginMessage recallTime:message.Property_ACMessage_msgSendTime extra:message.Property_ACMessage_extra];
                }
                [excludeNotifyMessageArr replaceObjectAtIndex:[excludeNotifyMessageArr indexOfObject:recallOriginMessage] withObject:recallMessage];
            }
            
            if (!recallMessage) {
                // 未能处理的撤回通知消息 直接丢弃
            }
            
            
        } else {
            [excludeNotifyMessageArr addObject:message];
        }
    }
    
    return [excludeNotifyMessageArr copy];
}

/*
- (NSArray *)processAckCommand:(NSArray *)messageList {
    NSMutableArray *excludeNotifyMessageArr = [NSMutableArray array];
    for (ACMessageMo* message in messageList) {
        
        switch (message.Property_ACMessage_mediaConstructor) {
                // 已到达对方手机回执 通知
            case SGSendPrivateChatArrivalAck: {
                NSDictionary * tempDict = [message.Property_ACMessage_mediaAttribute ac_jsonValueDecoded];
                [[ACMessageManager shared] updateMessageAckWithDialogId:tempDict[@"destId"] msgIds:tempDict[@"msgIdList"] withMessageReadType:ACMessageReadTypeReceived time:message.Property_ACMessage_msgSendTime];
                [self updateMessages:excludeNotifyMessageArr status:ACMessageReadTypeReceived inRemoteIds:tempDict[@"msgIdList"] atTime:message.Property_ACMessage_msgSendTime];
                continue;
                
            }
                break;
                
                // 消息已读回执 通知
            case SGSendPrivateChatReadAck: {
                NSDictionary * tempDict = [message.Property_ACMessage_mediaAttribute ac_jsonValueDecoded];
                [[ACMessageManager shared] updateMessageAckWithDialogId:tempDict[@"destId"] msgIds:tempDict[@"msgIdList"] withMessageReadType:ACMessageReadTypeReaded time:message.Property_ACMessage_msgSendTime];
                [self updateMessages:excludeNotifyMessageArr status:ACMessageReadTypeReaded inRemoteIds:tempDict[@"msgIdList"] atTime:message.Property_ACMessage_msgSendTime];
            }
                break;
                
                // 群消息已送达群员通知
            case SGSendGroupChatArrivalAck :{
                NSDictionary * tempDict = [message.Property_ACMessage_mediaAttribute ac_jsonValueDecoded];
                [[ACMessageManager shared] updateMessageAckWithDialogId:tempDict[@"groupId"] msgIds:tempDict[@"msgIdList"] withMessageReadType:ACMessageReadTypeReceived time:message.Property_ACMessage_msgSendTime];
                [self updateMessages:excludeNotifyMessageArr status:ACMessageReadTypeReceived inRemoteIds:tempDict[@"msgIdList"] atTime:message.Property_ACMessage_msgSendTime];
            } break;
                
                
            case GroupChatAckNotification: {
                
            } break;
                
                
                
            default:
                [excludeNotifyMessageArr addObject:message];
                break;
        }
        
    }
    
    return [excludeNotifyMessageArr copy];
}
 */

- (NSArray *)processSystemCommand:(NSArray *)messageList {

    for (ACMessageMo* message in messageList) {
        // 上传日志
        // TODO:
//        if (message.Property_ACMessage_mediaConstructor == ACReportLogNotification) {
//            [ACReportLog report];
//            break;
//        }
      
    }
    
    return messageList;
}

- (void)updateMessages:(NSArray *)messageArr status:(ACMessageReadType)status inRemoteIds:(NSArray *)remoteIds atTime:(long)time {
        for (ACMessageMo *message in messageArr) {
            if ([remoteIds containsObject:@(message.Property_ACMessage_remoteId)]) {
                message.Property_ACMessage_readType = status;
                if (status == ACMessageReadTypeReceived) {
                    message.Property_ACMessage_msgReceiveTime = time;
                }
            }
        }
}


- (void)setMessageAsReadWithMessageArr:(NSArray *)messageArr {
    for (ACMessageMo* message in messageArr) {
        if ([[ACMessageSerializeSupport shared] isHQVoiceMessage:message.Property_ACMessage_objectName]) {
            message.Property_ACMessage_readType = ACMessageReadTypeListened;
        } else {
            message.Property_ACMessage_readType = ACMessageReadTypeReaded;
        }
        message.Property_ACMessage_msgReceiveTime = [ACServerTime getServerMSTime];
    }
}

- (void)updateOutMessageReadStatusWithMessageArr:(NSArray *)messageArr lastReadTime:(long)lastReadTime {
    [messageArr enumerateObjectsUsingBlock:^(ACMessageMo *message, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!message.Property_ACMessage_isOut) {
            if (message.Property_ACMessage_msgSendTime <= lastReadTime) {
                message.Property_ACMessage_readType = ACMessageReadTypeReaded;
            } else {
                message.Property_ACMessage_readType = ACMessageReadTypeReceived;
            }
            message.Property_ACMessage_msgReceiveTime = [ACServerTime getServerMSTime];
        }
    }];
}

@end
