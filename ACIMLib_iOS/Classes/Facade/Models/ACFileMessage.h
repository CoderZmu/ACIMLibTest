//
//  ACFileMessage.h
//  ACIMLib
//
//  Created by 子木 on 2022/6/28.
//

#import "ACMediaMessageContent.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 *  \~chinese
 文件消息的类型名
 
 *  \~english
 The type name of the file message
 */
#define ACFileMessageTypeIdentifier @"RC:FileMsg"
/*!
 *  \~chinese
 文件消息类
 
 @discussion 文件消息类，此消息会进行存储并计入未读消息数。
 
 @remarks 内容类消息
 
 *  \~english
 File message class.

 @ discussion file message class, which is stored and counted as unread messages.
  
  @ remarks content class message.
 */
@interface ACFileMessage : ACMediaMessageContent


/*!
 *  \~chinese
 文件大小，单位为 Byte
 
 *  \~english
 File size in Byte
 */
@property (nonatomic, assign) long long size;

/*!
 *  \~chinese
 文件类型
 
 *  \~english
 File type
 */
@property (nonatomic, copy) NSString *type;

/*!
 *  \~chinese
 文件的网络地址
 
 *  \~english
 The network address of the file
 */
@property (nonatomic, readonly) NSString *fileUrl;

/*!
 *  \~chinese
 初始化文件消息

 @param localPath 文件的本地路径
 @return          文件消息对象
 
 */
+ (instancetype)messageWithFile:(NSString *)localPath;

@end

NS_ASSUME_NONNULL_END
