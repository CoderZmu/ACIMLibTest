//
//  ACMessageSerializeGlobalHelper.h
//  ACIMLib
//
//  Created by 子木 on 2022/6/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ACMessageMo;
@interface ACMessageSerializeSupport : NSObject

+ (ACMessageSerializeSupport *)shared;

- (void)registerMessageContentClass:(Class)contentClass;

- (Class)getMessageContentClass:(NSString *)objectName;

- (NSString *)getMessageType:(ACMessageMo *)messageMo;
- (NSArray *)getSearchableWords:(ACMessageMo *)messageMo;

- (BOOL)messageShouldPersisted:(NSString *)objectName;
- (BOOL)messageShouldCounted:(NSString *)objectName;
- (BOOL)isStatusMessage:(NSString *)objectName;
- (BOOL)isSupported:(NSString *)objectName;

- (BOOL)isHQVoiceMessage:(NSString *)objectName;
- (NSString *)recallNotificationMessageType;
- (NSString *)changeMessageContentAsRecallStatus:(ACMessageMo *)originalMessage recallTime:(long)recallTime;
@end

NS_ASSUME_NONNULL_END
