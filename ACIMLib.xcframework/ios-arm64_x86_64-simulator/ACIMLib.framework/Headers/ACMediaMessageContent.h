//
//  ACMediaMessageContent.h
//  ACIMLib
//
//  Created by 子木 on 2022/6/17.
//

#import "ACMessageContent.h"

NS_ASSUME_NONNULL_BEGIN

/**
 媒体类型消息的父类

 @discussion
 SDK 中所有媒体类型消息（图片、文件等）均继承此类。
 */
@interface ACMediaMessageContent : ACMessageContent

/**
 媒体内容的本地路径（此属性必须有值）
 */
@property (nonatomic, copy) NSString *localPath;

/**
 媒体内容上传服务器后的网络地址（上传成功后 SDK 会为该属性赋值）
 */
@property (nonatomic, copy) NSString *remoteUrl;

/*
 媒体内容加密key
 */
@property (nonatomic, copy) NSString *encryptKey;

/**
 媒体内容的文件名（如不传使用 SDK 中 downloadMediaMessage 方法下载后会默认生成一个名称）
 */
@property (nonatomic, copy) NSString *name;

@end

NS_ASSUME_NONNULL_END
