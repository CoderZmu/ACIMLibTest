//
//  ACMessageMo+Bridge.m
//  ACIMLib
//
//  Created by 子木 on 2022/6/20.
//

#import "ACMessageMo+Adapter.h"
#import "ACBase.h"
#import "ACAccountManager.h"
#import "ACDialogMo.h"
#import "ACDialogManager.h"
#import "ACMessageType.h"
#import "ACMessageHeader.h"
#import "ACFileManager.h"
#import "ACMessageSerializeSupport.h"
#import "ACDialogIdConverter.h"
#import "ACIMConfig.h"
#import "ACMessageMediaLocalPathFetcher.h"

@implementation ACMessageMo (Adapter)

- (ACMessage *)toRCMessage {
    ACMessage *message = [ACMessage new];
    ACConversationTypeTargetInfo *info = [ACDialogIdConverter getRCConversationInfoWithDialogId:self.Property_ACMessage_dialogIdStr];
    message.conversationType = info.type;
    message.targetId = info.targetId;
    message.channelId = info.channel;
    message.messageId = self.Property_ACMessage_msgId;
    message.messageDirection = self.Property_ACMessage_isOut ? MessageDirection_SEND : MessageDirection_RECEIVE;
    message.senderUserId = self.Property_ACMessage_srcUin;
    message.receivedStatus = [self recievedStatus];
    message.sentStatus = [self sentStatus];
    message.sentTime = self.Property_ACMessage_msgSendTime;
    message.receivedTime = self.Property_ACMessage_msgReceiveTime;
    message.objectName = [self messageType];
    message.content = [self messageContent];
    message.messageUId = (long)self.Property_ACMessage_remoteId;
    message.extra = self.Property_ACMessage_extra;
    message.isOffLine = self.Property_ACMessage_isOffline;
    message.expansionDic = [self.Property_ACMessage_expansionStr ac_jsonValueDecoded];
    
    if ([message.content isKindOfClass:ACMediaMessageContent.class]) {
        ACMediaMessageContent *mediaContent = (ACMediaMessageContent *)message.content;
        if (mediaContent.remoteUrl.length) {
            // 拼上域名
//            if (![mediaContent.remoteUrl hasPrefix:@"http"]) {
//                mediaContent.remoteUrl = [[ACIMConfig getFileDownloadURLString] stringByAppendingString:mediaContent.remoteUrl];
//            }
        }
        
        NSString *localPath = [ACMessageMediaLocalPathFetcher mediaPathForMediaMessage:message];
        if ([[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
            mediaContent.localPath = localPath;
        } else if (message.sentStatus == SentStatus_SENDING) {
        }
        
    }
    return message;
}

- (ACReceivedStatus)recievedStatus {
    if (self.Property_ACMessage_isOut) {
        return ReceivedStatus_READ;
    }
    
    switch (self.Property_ACMessage_readType) {
        case ACMessageReadTypeListened:
            return ReceivedStatus_LISTENED;
        case ACMessageReadTypeReaded:
            return ReceivedStatus_READ;
        default:
            return ReceivedStatus_UNREAD;
    }
}


- (ACSentStatus)sentStatus {
    
    if (self.Property_ACMessage_isOut) {
        if (self.Property_ACMessage_readType == ACMessageReadTypeReceived) {
            return SentStatus_RECEIVED;
        }
        if (self.Property_ACMessage_readType == ACMessageReadTypeReaded || self.Property_ACMessage_readType == ACMessageReadTypeListened) {
            return SentStatus_READ;
        }
        if (self.Property_ACMessage_readType == ACMessageReadTypeDestroyed) {
            return SentStatus_DESTROYED;
        }
        
        if (self.Property_ACMessage_deliveryState == ACMessagePending || self.Property_ACMessage_deliveryState == ACMessageDelivering) {
            return SentStatus_SENDING;
        }
        if (self.Property_ACMessage_deliveryState == ACMessageSuccessed) {
            return SentStatus_SENT;
        }
        if (self.Property_ACMessage_deliveryState == ACMessageFailure) {
            return SentStatus_FAILED;
        }
    
        return SentStatus_INVALID;
    } else {
    
        return SentStatus_SENT;
        
    }
    
}


- (ACMessageContent *)messageContent {
    Class contentCls = [[ACMessageSerializeSupport shared] getMessageContentClass:self.Property_ACMessage_objectName];
    ACMessageContent *content = [[contentCls alloc] init];
    [content decodeWithData:[self.Property_ACMessage_mediaAttribute ac_jsonValueDecoded]];

    if (self.Property_ACMessage_atFlag) {
        ACMentionedInfo *mentionedInfo = [[ACMentionedInfo alloc] init];
        mentionedInfo.isMentionedMe = YES;
        content.mentionedInfo = mentionedInfo;
    }
    
    return content;
}



- (void)setMessageStatusWithRCSentStatus:(ACSentStatus)sentStatus {
    if (!self.Property_ACMessage_isOut) return;
    
    self.Property_ACMessage_readType = ACMessageReadTypeSended;
    switch (sentStatus) {
        case SentStatus_SENDING: {
            self.Property_ACMessage_deliveryState = ACMessageDelivering;
        }
            break;
        case SentStatus_FAILED: {
            self.Property_ACMessage_deliveryState = ACMessageFailure;
        }break;
        case SentStatus_SENT: {
            self.Property_ACMessage_deliveryState = ACMessageSuccessed;
        }break;
        case SentStatus_RECEIVED: {
            self.Property_ACMessage_readType = ACMessageReadTypeReceived;
        }break;
        case SentStatus_READ: {
            self.Property_ACMessage_readType = ACMessageReadTypeReaded;
        } break;
        case SentStatus_DESTROYED:
            self.Property_ACMessage_readType = ACMessageReadTypeDestroyed;
        default:
            break;
    }
}


- (void)setMessageStatusWithRCReceiveStatus:(ACReceivedStatus)receivedStatus {
    if (self.Property_ACMessage_isOut) return;
    switch (receivedStatus) {
        case ReceivedStatus_UNREAD: {
            self.Property_ACMessage_readType = ACMessageReadTypeReceived;
        }
            break;
        case ReceivedStatus_READ: {
            self.Property_ACMessage_readType = ACMessageReadTypeReaded;
        } break;
        case ReceivedStatus_LISTENED: {
            if ([self.Property_ACMessage_objectName isEqualToString:ACHQVoiceMessageTypeIdentifier]) {
                self.Property_ACMessage_readType = ACMessageReadTypeListened;
            }
        } break;
    }
}


@end

