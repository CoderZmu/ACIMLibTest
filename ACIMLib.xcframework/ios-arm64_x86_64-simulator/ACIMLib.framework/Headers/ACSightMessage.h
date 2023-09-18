//
//  ACSightMessage.h
//  ACIMLib
//
//  Created by 子木 on 2022/6/28.
//

#import <UIKit/UIKit.h>
#import "ACMediaMessageContent.h"

NS_ASSUME_NONNULL_BEGIN


/*!
 *  \~chinese
 小视频消息的类型名
 
 *  \~english
 The type name of the small video message.
 */
#define ACSightMessageTypeIdentifier @"RC:SightMsg"
@class AVAsset;
/**
 *  \~chinese
 小视频消息类

 @discussion 小视频消息类，此消息会进行存储并计入未读消息数。
 
 @remarks 内容类消息
 
 *  \~english
 Small video message class.

 @ discussion small video message class, which is stored and counted as unread messages.
  
  @ remarks content class message.
 */
@interface ACSightMessage : ACMediaMessageContent

/**
 *  \~chinese
 视频时长，以秒为单位
 
 *  \~english
 Video duration (in seconds)
 */
@property (nonatomic, assign) NSUInteger duration;

/**
 *  \~chinese
 文件大小
 
 *  \~english
 File size
 */
@property (nonatomic, assign) long long size;

/*!
 *  \~chinese
 缩略图
 
 *  \~english
 Thumbnail image
 */
@property (nonatomic, strong) NSData *thumbnailData;

/**
 *  \~chinese
 创建小视频消息的便利构造方法

 @param path 视频文件本地路径
 @param thunmnailData 视频首帧缩略图
 @param duration 视频时长， 以秒为单位
 @return 视频消息实例变量

 */
+ (instancetype)messageWithLocalPath:(NSString *)path thumbnail:(NSData * _Nullable )thunmnailData duration:(NSUInteger)duration;

@end

NS_ASSUME_NONNULL_END
