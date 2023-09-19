//
//  ACTextMessage.h
//  ACIMLib
//
//  Created by 子木 on 2022/6/17.
//

#import "ACMessageContent.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 文本消息的类型名
 
 *  \~english
 The type name of the text message
 */
#define ACTextMessageTypeIdentifier @"RC:TxtMsg"

/*!
 文本消息类

 @discussion 文本消息类，此消息会进行存储并计入未读消息数。
 
 @remarks 内容类消息
 
 *  \~english
 Text message class.

 @ discussion Text message class, which is stored and counted as unread messages.
  
  @ remarks content class message.
 */
@interface ACTextMessage : ACMessageContent

/*!
 文本消息的内容
 
 *  \~english
 The content of a text message
 */
@property (nonatomic, copy) NSString *content;

/*!
 初始化文本消息

 @param content 文本消息的内容
 @return        文本消息对象
 
 */
+ (instancetype)messageWithContent:(NSString *)content;

@end

NS_ASSUME_NONNULL_END
