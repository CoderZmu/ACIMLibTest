//
//  ACIMIWMessageContent.h
//  ACIMLib
//
//  Created by 子木 on 2022/6/30.
//

#import "ACMessageContent.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 自定义消息
 */
@interface ACIMIWMessageContent : ACMessageContent
/*!
 消息类型
 */
@property (nonatomic, copy) NSString *messageType;
/*!
 消息字段
 */
@property (nonatomic, strong) NSDictionary<NSString*, NSString*> *mFields;

+ (instancetype)messageWithType:(NSString *)messageType fields:(NSDictionary<NSString*, NSString*> *)fields;

@end



NS_ASSUME_NONNULL_END
