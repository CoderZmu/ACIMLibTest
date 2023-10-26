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
 小视频消息的类型名
 */
#define ACSightMessageTypeIdentifier @"RC:SightMsg"
@class AVAsset;
/**
 小视频消息类

 @discussion 小视频消息类，此消息会进行存储并计入未读消息数。
 
 @remarks 内容类消息
 */
@interface ACSightMessage : ACMediaMessageContent

/**
 视频时长，以秒为单位
 */
@property (nonatomic, assign) NSUInteger duration;

/**
 文件大小
 */
@property (nonatomic, assign) long long size;

/*!
 缩略图
 */
@property (nonatomic, strong) NSData *thumbnailData;

/**
 创建小视频消息的便利构造方法

 @param path 视频文件本地路径
 @param thunmnailData 视频首帧缩略图
 @param duration 视频时长， 以秒为单位
 @return 视频消息实例变量

 */
+ (instancetype)messageWithLocalPath:(NSString *)path thumbnail:(NSData * _Nullable )thunmnailData duration:(NSUInteger)duration;

@end

NS_ASSUME_NONNULL_END
