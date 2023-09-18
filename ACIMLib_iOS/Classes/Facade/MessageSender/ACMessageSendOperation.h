//
//  ACMessageSendOperation.h
//  ACIMLib
//
//  Created by 子木 on 2022/7/6.
//

#import <Foundation/Foundation.h>
#import "ACStatusDefine.h"
#import "ACMessageMo.h"
#import "ACMessageContent.h"
#import "ACMessagePushConfig.h"
#import "ACSendMessageConfig.h"
#import "ACMessageSendPreprocessor.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^ACUploadMediaProgressBlock)(int progress, ACMessage *message);
typedef void (^ACSendMessageSuccessBlock)(ACMessage *message);
typedef void (^ACSendMessageErrorBlock)(ACErrorCode errorCode, ACMessage *message);

@class ACMessage;

@interface ACMessageSendOperation : NSOperation

- (instancetype)initWithMessage:(ACMessage *)message
                            toUserIdList:(NSArray *)userIdList
                              sendConfig:(ACSendMessageConfig *)sendConfig
                            preprocessor:(id<ACMessageSendPreprocessor>)preprocessor
                                   error:(NSError **)error;

- (BOOL)cancelSendMessage;

- (void)setSuccessBlock:(ACSendMessageSuccessBlock)successBlock errorBlock:(ACSendMessageErrorBlock)errorBlock progressBlock:(ACUploadMediaProgressBlock)progressBlock;

- (ACMessage *)getSentMessage;
- (long)getMsgId;
- (NSString *)getDialogId;


- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

@end

NS_ASSUME_NONNULL_END
