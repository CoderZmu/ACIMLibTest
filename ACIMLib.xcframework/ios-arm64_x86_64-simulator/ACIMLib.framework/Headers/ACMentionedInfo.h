//
//  ACMentionedInfo.h
//  ACIMLib
//
//  Created by 子木 on 2022/8/5.
//

#import <Foundation/Foundation.h>
#import "ACStatusDefine.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 消息中的 @ 提醒信息对象
 */
@interface ACMentionedInfo : NSObject

/*!
 @ 提醒的类型
 */
@property (nonatomic, assign) ACMentionedType type;

/*!
 @ 的用户 ID 列表

 @discussion 如果 type 是 @ 所有人，则可以传 nil
 */
@property (nonatomic, strong) NSArray<NSNumber *> *userIdList;

/*!
 是否 @ 了我
 */
@property (nonatomic, assign) BOOL isMentionedMe;

/*!
 初始化 @ 提醒信息

 @param type       @ 提醒的类型
 @param userIdList @ 的用户 ID 列表

 @return @ 提醒信息的对象
 */
- (instancetype)initWithMentionedType:(ACMentionedType)type
                           userIdList:(NSArray *)userIdList;

@end

NS_ASSUME_NONNULL_END
