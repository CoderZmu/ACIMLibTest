//
//  ACHistoryMessageOption.h
//  ACIMLib
//
//  Created by 子木 on 2022/8/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 拉取顺序
 ACHistoryMessageOrderDesc - 降序
 ACHistoryMessageOrderAsc - 升序
 */
typedef enum : NSUInteger {
    ACHistoryMessageOrderDesc = 0,
    ACHistoryMessageOrderAsc,
} ACHistoryMessageOrder;

@interface ACHistoryMessageOption : NSObject

/**
 起始的消息发送时间戳，毫秒
 默认 0  
 */
@property (nonatomic, assign) long long recordTime;

/**
 需要获取的消息数量， 0 < count <= 20
 超级群可以传入 100
 默认 0
 */
@property (nonatomic, assign) NSInteger count;

/**
 拉取顺序
 ACHistoryMessageOrderDesc： 降序，结合传入的时间戳参数，获取 recordtime 之前的消息
 ACHistoryMessageOrderAsc： 升序，结合传入的时间戳参数，获取 recordtime 之后的消息
 默认降序
 */
@property (nonatomic, assign) ACHistoryMessageOrder order;

@end

NS_ASSUME_NONNULL_END
