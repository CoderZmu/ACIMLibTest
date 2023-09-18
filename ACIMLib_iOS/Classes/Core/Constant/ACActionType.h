//
//  ACActionType.h
//  ACIMLib
//
//  Created by 子木 on 2022/6/14.
//

#ifndef ACActionType_h
#define ACActionType_h

#define kReceiveNewMessagesNotification @"/ac/receiveNewMessages" //消息撤回的通知
#define kRecallMessageNotification @"/ac/recallMessage" //消息撤回的通知
#define kSuperGroupConversationListDidSyncNoti @"/ac/superGroupConversationListDidSync" // 超级群会话列表与会话最后一条消息同步完成
#define kConversationListDidSyncNoti @"/ac/conversationListDidSync" // 单聊和普通群组最后一条消息同步完成
#define kServerTimeDidSyncNoti @"/ac/serverTimeDidSync" // 服务器时间同步完成
#define kGroupInfoChange @"/sg/groupInfoChange"


#endif /* ACActionType_h */
