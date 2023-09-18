//
//  ACMessageSendPreprocessor.h
//  ACIMLib
//
//  Created by 子木 on 2022/6/30.
//

#import <Foundation/Foundation.h>
#import "ACMessageContent.h"
#import "ACStatusDefine.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACMessageSendPreprocessor <NSObject>

@required

- (ACErrorCode)preprocess:(ACMessageContent *)messageContent dialogId:(NSString *)target msgId:(long)msgId;

@optional
- (void)compress:(ACMessageContent *)messageContent dialogId:(NSString *)target msgId:(long)msgId complete:(void(^)(ACErrorCode code))completeBlock;

@end

@interface ACImageMessageSendPreprocessor : NSObject<ACMessageSendPreprocessor>

@end

@interface ACFileMessageSendPreprocessor : NSObject<ACMessageSendPreprocessor>

@end

@interface ACVideoMessageSendPreprocessor : NSObject<ACMessageSendPreprocessor>

@end

@interface ACGifMessageSendPreprocessor : NSObject<ACMessageSendPreprocessor>

@end

@interface ACHQVoiceMessageSendPreprocessor : NSObject<ACMessageSendPreprocessor>

@end

@interface ACGenericMediaMessageSendPreprocessor : NSObject<ACMessageSendPreprocessor>

@end
NS_ASSUME_NONNULL_END
