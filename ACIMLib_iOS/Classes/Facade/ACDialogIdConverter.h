//
//  ACDialogIdConverter.h
//  ACIMLib
//
//  Created by 子木 on 2022/7/2.
//

#import <Foundation/Foundation.h>
#import "ACStatusDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACConversationTypeTargetInfo : NSObject

@property (nonatomic, assign) ACConversationType type;
@property (nonatomic, assign) long targetId;
@property (nonatomic, assign) NSString *channel;

+ (instancetype)instanceWithType:(ACConversationType)type targetId:(long)targetId;

@end

@interface ACDialogIdConverter : NSObject

+ (NSString *)getSgDialogIdWithConversationType:(ACConversationType)type targetId:(long)targetId;
+ (NSString *)getSgDialogIdWithConversationType:(ACConversationType)type targetId:(long)targetId channelId:(nullable NSString *)channelId;
+ (BOOL)isGroupType:(NSString *)dialogId;
+ (BOOL)isSuperGroupType:(NSString *)dialogId;
+ (BOOL)isSupported:(ACConversationType)type;
+ (ACConversationTypeTargetInfo *)getRCConversationInfoWithDialogId:(NSString *)dialogId;

@end

NS_ASSUME_NONNULL_END
