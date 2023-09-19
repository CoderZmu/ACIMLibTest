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
 
 *  \~english
 Conversation class.

 @ discussion Conversation class, which contains all the properties of the conversation.
 */
@interface ACConversation : NSObject

/*!
 会话类型
 *  \~english
 Conversation type
 */
@property (nonatomic, assign) ACConversationType conversationType;

/*!
 会话 ID
 *  \~english
 Conversation ID
 */
@property (nonatomic, copy) NSString *targetId;


/// 超级群频道Id
@property (nonatomic, copy) NSString *channelId;

/*!
 会话的标题
 *  \~english
 Title of the conversation
 */
@property (nonatomic, copy) NSString *conversationTitle;

/*!
 会话中的未读消息数量
 *  \~english
 Number of unread messages in the conversation
 */
@property (nonatomic, assign) int unreadMessageCount;

/*!
 是否置顶，默认值为 NO
 
 *  \~english
 Whether to set the top. default value is NO.

 */
@property (nonatomic, assign) BOOL isTop;

/*!
 会话中最后一条消息的接收状态
 *  \~english
 The receiving status of the last message in the conversation
 */
@property (nonatomic, assign) ACReceivedStatus receivedStatus;

/*!
 会话中最后一条消息的发送状态
 *  \~english
 The sending status of the last message in the conversation
 */
@property (nonatomic, assign) ACSentStatus sentStatus;

/*!
 会话中最后一条消息的接收时间（Unix时间戳、毫秒）
 *  \~english
 Time of receipt of the last message in the conversation (Unix timestamp, milliseconds)
 */
@property (nonatomic, assign) long long receivedTime;

/*!
 会话中最后一条消息的发送时间（Unix时间戳、毫秒）
 *
 *  \~english
 Time when the last message in the conversation is sent (Unix timestamp, milliseconds)
 */
@property (nonatomic, assign) long long sentTime;

/*!
 会话中存在的草稿
 *  \~english
 Drafts that exist in the conversation
 */
@property (nonatomic, copy) NSString *draft;

/*!
 会话中最后一条消息的类型名
 *  \~english
 The type name of the last message in the conversation
 */
@property (nonatomic, copy) NSString *objectName;

/*!
 会话中最后一条消息的发送者用户 ID
 *  \~english
 User ID, the sender of the last message in the conversation.
 */
@property (nonatomic, assign) long senderUserId;

/*!
 会话中最后一条消息的消息 ID
 *  \~english
 Message ID of the last message in the conversation.
 */
@property (nonatomic, assign) long lastestMessageId;

/*!
 会话中是否存在被 @ 的消息

 @discussion 在清除会话未读数（clearMessagesUnreadStatus:targetId:）的时候，会将此状态置成 NO。
 
 *  \~english
 Whether there is a @ message in the conversation.

 @ discussion set this state to NO when clearing the conversation unread (clearMessagesUnreadStatus:targetId:).
 */
@property (nonatomic, assign) BOOL hasUnreadMentioned;

/*!
 会话中最后一条消息的内容
 *  \~english
 The content of the last message in the conversation
 */
@property (nonatomic, strong) ACMessageContent *lastestMessage;

/*!
会话是否是免打扰状态
 
 *  \~english
 Whether the conversation is in a do not Disturb state.
*/
@property (nonatomic, assign) ACConversationNotificationStatus blockStatus;


/*!
 免打扰级别
 */
@property (nonatomic, assign) ACPushNotificationLevel notificationLevel;

@end


NS_ASSUME_NONNULL_END
