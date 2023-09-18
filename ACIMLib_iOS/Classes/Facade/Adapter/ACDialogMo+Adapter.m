//
//  ACDialogMo+Bridge.m
//  ACIMLib
//
//  Created by 子木 on 2022/6/20.
//

#import "ACDialogMo+Adapter.h"
#import "ACMessageMo+Adapter.h"
#import "ACMessageManager.h"
#import "ACDialogManager.h"
#import "ACDialogIdConverter.h"

@implementation ACDialogMo (Adapter)

- (ACConversation *)toRCConversation {
    ACConversation *conversation = [[ACConversation alloc] init];
    ACConversationTypeTargetInfo *info = [ACDialogIdConverter getRCConversationInfoWithDialogId:self.Property_ACDialogs_dialogId];
    conversation.targetId = info.targetId;
    conversation.conversationType = info.type;
    conversation.channelId = info.channel;
    conversation.conversationTitle = self.Property_ACDialogs_dialogTitle;
    conversation.isTop = self.Property_ACDialogs_stickyFlag;
    conversation.draft = self.Property_ACDialogs_draftText;
    conversation.blockStatus = self.Property_ACDialogs_muteFlag ? DO_NOT_DISTURB : NOTIFY;
    conversation.sentTime = self.Property_ACDialogs_updateTime;
    
    // 设置会话未读数
    conversation.unreadMessageCount = (int)[[ACDialogManager sharedDialogManger] getDialogUnreadCount:self.Property_ACDialogs_dialogId];
    if (conversation.unreadMessageCount) {
        conversation.hasUnreadMentioned = [[ACDialogManager sharedDialogManger]  hasUnreadMentioned:self.Property_ACDialogs_dialogId];
    }
    
    ACMessage *latestMessage = [[[ACDialogManager sharedDialogManger] getLatestMessageForDialog:self] toRCMessage];
    if (latestMessage) {
        conversation.receivedStatus = latestMessage.receivedStatus;
        conversation.sentStatus = latestMessage.sentStatus;
        conversation.receivedTime = latestMessage.receivedTime;
        conversation.objectName = latestMessage.objectName;
        conversation.senderUserId = latestMessage.senderUserId;
        conversation.lastestMessageId = latestMessage.messageId;
        conversation.lastestMessage = latestMessage.content;
    }
    

    return conversation;
}

@end
