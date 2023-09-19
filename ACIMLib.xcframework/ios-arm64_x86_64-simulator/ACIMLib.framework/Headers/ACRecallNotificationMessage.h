//
//  ACRecallNotificationMessage.h
//  ACIMLib
//
//  Created by 子木 on 2022/6/22.
//

#import "ACMessageContent.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 撤回通知消息的类型名
 
 *  \~english
 The type name of the recall notification message
 */
#define ACRecallNotificationMessageIdentifier @"RC:RcNtf"

/*!
 撤回通知消息类
 @discussion 撤回通知消息，此消息会进行本地存储，但不计入未读消息数。
 
 @remarks 通知类消息
 
 *  \~english
 Recall notification message class
 @ discussion Recall notification message, which is stored locally, but does not count as the number of unread messages.
  
  @ remarks notification message
 */
@interface ACRecallNotificationMessage : ACMessageContent

/*!
 发起撤回操作的用户 ID
 
 *  \~english
 ID of the user who initiates the recall operation
 */
@property (nonatomic, assign) long operatorId;

/*!
 撤回的时间（毫秒）
 
 *  \~english
 Time to recall (milliseconds)
 */
@property (nonatomic, assign) long long recallTime;

/*!
 原消息的消息类型名
 
 *  \~english
 Message type name of the original message
 */
@property (nonatomic, copy) NSString *originalObjectName;

/*!
 是否是管理员操作
 
 *  \~english
 Whether it is an administrator operation
 */
@property (nonatomic, assign) BOOL isAdmin;

/*!
 撤回的文本消息的内容
 
 *  \~english
 The contents of the recalled text message
*/
@property (nonatomic, copy) NSString *recallContent;

/*!
 撤回动作的时间（毫秒）
 
 *  \~english
 Time to recall the action (milliseconds).
*/
@property (nonatomic, assign) long long recallActionTime;

@end


NS_ASSUME_NONNULL_END

