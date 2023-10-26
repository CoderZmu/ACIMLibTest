//
//  ACGIFMessage.h
//  ACIMLib
//
//  Created by 子木 on 2022/6/29.
//

#import "ACMediaMessageContent.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 GIF 消息的类型名
 */
#define ACGIFMessageTypeIdentifier @"RC:GIFMsg"
/*!
 GIF 消息
 @discussion  GIF 消息类，此消息会进行存储并计入未读消息数。
 
 @remarks 内容类消息
 */
@interface ACGIFMessage : ACMediaMessageContent

/*!
 GIF 图的大小，单位字节
 */
@property (nonatomic, assign) long long gifDataSize;

/*!
 GIF 图的宽
 */
@property (nonatomic, assign) long width;

/*!
 GIF 图的高

 */
@property (nonatomic, assign) long height;

/*!
 缩略图
 */
@property (nonatomic, strong) NSData *thumbnailData;

/*!
 初始化 GIF 消息

 @param gifImageData    GIF 图的数据
 @param width           GIF 的宽
 @param height          GIF 的高

 @return                GIF 消息对象

 */
+ (instancetype)messageWithGIFImageData:(NSData *)gifImageData width:(long)width height:(long)height;

/*!
 初始化 GIF 消息

 @param gifURI          GIF 的本地路径
 @param width           GIF 的宽
 @param height          GIF 的高

 @return                GIF 消息对象

 */
+ (instancetype)messageWithGIFURI:(NSString *)gifURI width:(long)width height:(long)height;

@end

NS_ASSUME_NONNULL_END
