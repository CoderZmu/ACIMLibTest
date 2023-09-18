//
//  ACSuperGroupNewMessageProcesser.m
//  ACIMLib
//
//  Created by 子木 on 2022/8/2.
//

#import "ACSuperGroupNewMessageProcesser.h"
#import "ACServerMessageDataParser.h"
#import "ACDialogManager.h"
#import "ACMessageFilter.h"
#import "ACMessageManager.h"
#import "ACEventBus.h"
#import "ACActionType.h"
#import "ACCommandMessageProcesser.h"
#import "AcpbSupergroupchat.pbobjc.h"
#import "ACSuperGroupOfflineMessageService.h"


@implementation ACSuperGroupNewMessageProcesser


+ (void)onReceiveNewMessageData:(NSData *)data {
    ACPBSendSuperGroupMessageResp *resp = [ACPBSendSuperGroupMessageResp parseFromData:data error:nil];
    if (!resp) return;
    
    [resp.msg.dialogMessageArray sortUsingComparator:^NSComparisonResult(ACPBDialogMessage *obj1, ACPBDialogMessage *obj2) {
        if (obj1.seqno <= obj2.seqno) return NSOrderedAscending;
        return NSOrderedDescending;
    }];
    [self parseMsgDict:resp];
}



+ (void)parseMsgDict:(ACPBSendSuperGroupMessageResp *)resp {
    NSDictionary<NSString*, ACPBDialogMessageList*> *originMsgDict = @{resp.dialogKey: resp.msg};
    [[ACServerMessageDataParser new] parse:originMsgDict callback:^(BOOL done, NSDictionary<NSString *,NSArray<ACMessageMo *> *> * _Nonnull msgMaps) {
        
        NSString *dialogId = msgMaps.allKeys.firstObject;
        if (!dialogId.length) return;
        NSArray<ACMessageMo *> *orignalMsgArr = msgMaps[dialogId];
        if (!orignalMsgArr.count) return;
        

        ACMessageFilter *filter = [ACMessageFilter new];
        NSArray *contentArr = [filter filter:[[ACCommandMessageProcesser new] processNewMessages:orignalMsgArr ignoreAck:YES readOffset:[[ACDialogManager sharedDialogManger] getDialogLastReadTime:dialogId]]];
        
        NSArray *newMessages = [[ACMessageManager shared] storeAndFilterMessageList:contentArr isOldMessage:NO];
        
        if (newMessages.count) {
            [[ACEventBus globalEventBus] emit:kReceiveNewMessagesNotification withArguments:@[@{dialogId: newMessages}, @NO]];
            [[ACDialogManager sharedDialogManger] addRemoteDialogsInfoIfNotExist:@[dialogId]];
            [[ACDialogManager sharedDialogManger] flushDialogUpdateTimeByLatestMessageSentTime:dialogId];
        }
        
        if ([[ACSuperGroupOfflineMessageService shared] isOfflineMessagesLoaded]) {
            [[ACDialogManager sharedDialogManger] updateSgLastReceiveRecordTime:dialogId time:orignalMsgArr.lastObject.Property_ACMessage_msgSendTime];
        } 
    }];
}


@end
