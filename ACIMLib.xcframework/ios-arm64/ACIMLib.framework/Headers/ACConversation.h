//
//  ACConversation.h
//  ACIMLib
//
//  Created by 子木 on 2022/6/20.
//

#import <Foundation/Foundation.h>
#import "ACMessageContent.h"
#import "ACStatusDefine.h"

NS_ASSUME_NONNULL_BEGIN


/*!
 会话类

 @discussion 会话类，包含会话的所有属性。
 */
@interface ACConversation : NSObject

/*!
 会话类型
 */
@property (nonatomic, assign) ACConversationType conversationType;

/*!
 会话 ID
 */
@property (nonatomic, copy) NSString *targetId;


/// 超级群频道Id
@property (nonatomic, copy) NSString *channelId;

/*!
 会话的标题
 */
@property (nonatomic, copy) NSString *conversationTitle;

/*!
 会话中的未读消息数量
 */
@property (nonatomic, assign) int unreadMessageCount;

/*!
 是否置顶，默认值为 NO

 */
@property (nonatomic, assign) BOOL isTop;

/*!
 会话中最后一条消息的接收状态
 */
@property (nonatomic, assign) ACReceivedStatus receivedStatus;

/*!
 会话中最后一条消息的发送状态
 */
@property (nonatomic, assign) ACSentStatus sentStatus;

/*!
 会话中最后一条消息的接收时间（Unix时间戳、毫秒）
 */
@property (nonatomic, assign) long long receivedTime;

/*!
 会话中最后一条消息的发送时间（Unix时间戳、毫秒）
 */
@property (nonatomic, assign) long long sentTime;

/*!
 会话中存在的草稿
 */
@property (nonatomic, copy) NSString *draft;

/*!
 会话中最后一条消息的类型名
 */
@property (nonatomic, copy) NSString *objectName;

/*!
 会话中最后一条消息的发送者用户 ID
 */
@property (nonatomic, assign) long senderUserId;

/*!
 会话中最后一条消息的消息 ID
 */
@property (nonatomic, assign) long lastestMessageId;

/*!
 会话中是否存在被 @ 的消息

 @discussion 在清除会话未读数（clearMessagesUnreadStatus:targetId:）的时候，会将此状态置成 NO。
 */
@property (nonatomic, assign) BOOL hasUnreadMentioned;

/*!
 会话中最后一条消息的内容
 */
@property (nonatomic, strong) ACMessageContent *lastestMessage;

/*!
会话是否是免打扰状态
*/
@property (nonatomic, assign) ACConversationNotificationStatus blockStatus;


/*!
 免打扰级别
 */
@property (nonatomic, assign) ACPushNotificationLevel notificationLevel;

@end


NS_ASSUME_NONNULL_END
