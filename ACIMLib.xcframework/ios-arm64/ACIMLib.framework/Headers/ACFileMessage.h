//
//  ACFileMessage.h
//  ACIMLib
//
//  Created by 子木 on 2022/6/28.
//

#import "ACMediaMessageContent.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 文件消息的类型名
 */
#define ACFileMessageTypeIdentifier @"RC:FileMsg"
/*!
 文件消息类
 
 @discussion 文件消息类，此消息会进行存储并计入未读消息数。
 
 @remarks 内容类消息
 */
@interface ACFileMessage : ACMediaMessageContent


/*!
 文件大小，单位为 Byte
 */
@property (nonatomic, assign) long long size;

/*!
 文件类型
 */
@property (nonatomic, copy) NSString *type;

/*!
 文件的网络地址
 */
@property (nonatomic, readonly) NSString *fileUrl;

/*!
 初始化文件消息

 @param localPath 文件的本地路径
 @return          文件消息对象
 
 */
+ (instancetype)messageWithFile:(NSString *)localPath;

@end

NS_ASSUME_NONNULL_END
