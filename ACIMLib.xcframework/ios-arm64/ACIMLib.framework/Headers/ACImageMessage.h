//
//  ACImageMessage.h
//  ACIMLib
//
//  Created by 子木 on 2022/6/17.
//


#import <UIKit/UIKit.h>
#import "ACMediaMessageContent.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 图片消息的类型名
 */
#define ACImageMessageTypeIdentifier @"RC:ImgMsg"

/*!
 图片消息类

 @discussion 图片消息类，此消息会进行存储并计入未读消息数。
 
 @discussion 如果想发送原图，请设置属性 full 为 YES。
 
 @remarks 内容类消息
 */
@interface ACImageMessage : ACMediaMessageContent

/*!
 图片消息的 URL 地址

 @discussion 发送方此字段为图片的本地路径，接收方此字段为网络 URL 地址。
 
 @attention
 不再允许外部赋值，为只读属性
 本地地址使用 localPath， 远端地址使用 remoteUrl
 */
@property (nonatomic, copy, readonly) NSString *imageUrl;
/*!
 图片消息的缩略图数据
 */
@property (nonatomic, strong) NSData *thumbnailData;

/*!
 是否发送原图

 @discussion 在发送图片的时候，是否发送原图，默认值为 NO。
 */
@property (nonatomic, getter=isFull) BOOL full;


/*!
 图片的宽
 */
@property (nonatomic, assign) long width;

/*!
 图片的高
 */
@property (nonatomic, assign) long height;



/*!
 初始化图片消息

 @discussion 如果想发送原图，请设置属性 full 为 YES。
 
 @param image   原始图片
 @return        图片消息对象
 */
+ (instancetype)messageWithImage:(UIImage *)image;

/*!
 初始化图片消息
 
 @discussion 如果想发送原图，请设置属性 full 为 YES。

 @param imageURI    图片的本地路径
 @return            图片消息对象
 */
+ (instancetype)messageWithImageURI:(NSString *)imageURI;

/*!
 初始化图片消息
 
 @discussion 如果想发送原图，请设置属性 full 为 YES。

 @param imageData    图片的原始数据
 @return            图片消息对象
 */
+ (instancetype)messageWithImageData:(NSData *)imageData;


@end

NS_ASSUME_NONNULL_END
