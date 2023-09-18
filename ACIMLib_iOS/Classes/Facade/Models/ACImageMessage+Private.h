//
//  ACImageMessage+Private.h
//  ACIMLib
//
//  Created by 子木 on 2023/9/18.
//

#import "ACImageMessage.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACImageMessage (Private)

/*!
 图片消息的原始图片信息
 发送成功之前该字段是可用的
 发送成功之后基于减少内存的考虑，该字段不再保存原始数据
 发送成功之后请优先使用 localPath 与 remoteUrl 进行展示
 */
@property (nonatomic, strong, nullable) NSData *originalImageData;

@property (nonatomic, strong, nullable) UIImage *originalImage;

@end

NS_ASSUME_NONNULL_END
