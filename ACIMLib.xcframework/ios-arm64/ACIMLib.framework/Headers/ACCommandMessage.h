//
//  ACCommandMessage.h
//  ACIMLib
//
//  Created by 子木 on 2022/7/1.
//

#import "ACMessageContent.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 命令消息的类型名
 */
#define ACCommandMessageIdentifier @"RC:CmdMsg"

/*!
 命令消息类

 @discussion 命令消息类，此消息不存储不计入未读消息数。
 与 ACCommandNotificationMessage 的区别是，此消息不存储，也不会在界面上显示。
 
 @remarks 通知类消息
 */
@interface ACCommandMessage : ACMessageContent


/*!
命令的名称
*/
@property (nonatomic, copy) NSString *name;

/*!
 命令的扩展数据

 @discussion 命令的扩展数据，可以为任意字符串，如存放您定义的json数据。
 */
@property (nonatomic, copy) NSString *data;

/*!
 初始化命令消息

 @param name    命令的名称
 @param data    命令的扩展数据
 @return        命令消息对象
 */
+ (instancetype)messageWithName:(NSString *)name data:(NSString *)data;


@end

NS_ASSUME_NONNULL_END
