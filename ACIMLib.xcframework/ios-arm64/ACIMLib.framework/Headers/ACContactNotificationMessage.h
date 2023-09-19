//
//  ACContactNotificationMessage.h
//  ACIMLib
//
//  Created by 子木 on 2022/7/1.
//


#import "ACMessageContent.h"

/*!
 好友请求消息的类型名
 *  \~english
 The type name of the friend request message.
 */
#define ACContactNotificationMessageIdentifier @"RC:ContactNtf"

/*!
 请求添加好友
 *  \~english
 Request to add friends.
 */
#define ContactNotificationMessage_ContactOperationRequest @"Request"

/*!
 同意添加好友的请求
 *  \~english
 Agree to the request to add friends.
 */
#define ContactNotificationMessage_ContactOperationAcceptResponse @"AcceptResponse"

/*!
 拒绝添加好友的请求
 *  \~english
 Reject the request to add friends
 */
#define ContactNotificationMessage_ContactOperationRejectResponse @"RejectResponse"

/*!
 好友请求消息类

 @discussion 好友请求消息类，此消息会进行存储，但不计入未读消息数。
 
 @remarks 通知类消息
 
 *  \~english
 Friend request message class.

 @ discussion friend request message class, this message is stored, but does not count as the number of unread messages.
  
  @ remarks notification message
 */
@interface ACContactNotificationMessage : ACMessageContent

/*!
 好友请求的当前操作名

 @discussion
 好友请求当前的操作名称，您可以使用预定义好的操作名，也可以是您自己定义的任何操作名。
 预定义的操作名：ContactNotificationMessage_ContactOperationRequest、ContactNotificationMessage_ContactOperationAcceptResponse、ContactNotificationMessage_ContactOperationRejectResponse。
 
 *  \~english
 The current operation name of the friend request.

 @ discussion
 Friends request the name of the current operation. You can use a predefined operation name or any operation name that you define yourself.
  Predefined operation names: ContactNotificationMessage_ContactOperationRequest, ContactNotificationMessage_ContactOperationAcceptResponse, ContactNotificationMessage_ContactOperationRejectResponse.
 */
@property (nonatomic, copy) NSString *operation;

/*!
 当前操作发起用户的用户 ID
 *  \~english
 User ID of the user who initiated the current operation
 */
@property (nonatomic, copy) NSString *sourceUserId;

/*!
 当前操作目标用户的用户 ID
 *  \~english
 The user ID of the target user for the current operation
 */
@property (nonatomic, copy) NSString *targetUserId;

/*!
 当前操作的消息内容

 @discussion 当前操作的消息内容，如同意、拒绝的理由等。
 
 *  \~english
 Message content of the current operation.

 @ discussion The message content of the current operation, such as consent, reasons for rejection, etc.
 */
@property (nonatomic, copy) NSString *message;

/*!
 初始化好友请求消息

 @param operation       好友请求当前的操作名
 @param sourceUserId    当前操作发起用户的用户 ID
 @param targetUserId    当前操作目标用户的用户 ID
 @param message         当前操作的消息内容
 @param extra           当前操作的附加信息
 @return                好友请求消息对象

 @discussion SDK不介入您的好友关系，所有的好友关系都由您的服务器自己维护。
 所以好友请求的操作名和消息内容、扩展信息您均可以自己定制，只要您发送方和接收方针对具体字段内容做好 UI 显示即可。

 */
+ (instancetype)notificationWithOperation:(NSString *)operation
                             sourceUserId:(NSString *)sourceUserId
                             targetUserId:(NSString *)targetUserId
                                  message:(NSString *)message
                                    extra:(NSString *)extra;

@end
