//
//  ACHQVoiceMessage.h
//  ACIMLib
//
//  Created by 子木 on 2022/6/29.
//

#import "ACMediaMessageContent.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 高清语音消息类型名
 */
#define ACHQVoiceMessageTypeIdentifier @"RC:HQVCMsg"

/*!
 高清语音消息类
 
 @discussion 高清语音消息类，此消息会进行存储并计入未读消息数。
 
 @remarks 内容类消息
 */
@interface ACHQVoiceMessage : ACMediaMessageContent

/*!
 语音消息的时长，以秒为单位
 */
@property (nonatomic, assign) long duration;

/*!
 初始化高清语音消息

 @param localPath 语音的本地路径
 @param duration   语音时长，以秒为单位

 @return          语音消息对象

 */
+ (instancetype)messageWithPath:(NSString *)localPath duration:(long)duration;

@end

NS_ASSUME_NONNULL_END
