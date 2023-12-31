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
 */
#define ACRecallNotificationMessageIdentifier @"RC:RcNtf"

/*!
 撤回通知消息类
 @discussion 撤回通知消息，此消息会进行本地存储，但不计入未读消息数。
 
 @remarks 通知类消息
 */
@interface ACRecallNotificationMessage : ACMessageContent

/*!
 发起撤回操作的用户 ID
 */
@property (nonatomic, assign) long operatorId;

/*!
 撤回的时间（毫秒）
 */
@property (nonatomic, assign) long long recallTime;

/*!
 原消息的消息类型名
 */
@property (nonatomic, copy) NSString *originalObjectName;

/*!
 是否是管理员操作
 */
@property (nonatomic, assign) BOOL isAdmin;

/*!
 撤回的文本消息的内容
*/
@property (nonatomic, copy) NSString *recallContent;

/*!
 撤回动作的时间（毫秒）
*/
@property (nonatomic, assign) long long recallActionTime;

@end


NS_ASSUME_NONNULL_END

