//
//  ACNotifyMessageProcesser.h
//  ACIMLib
//
//  Created by 子木 on 2022/8/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ACMessageMo;
@interface ACCommandMessageProcesser : NSObject

- (NSArray *)processNewMessages:(NSArray<ACMessageMo *> *)messageList ignoreAck:(BOOL)ignoreAck readOffset:(long)readOffset;
- (NSArray *)processHistoryMessages:(NSArray<ACMessageMo *> *)messageList setAllRead:(BOOL)setAllRead readOffset:(long)readOffset;

@end

NS_ASSUME_NONNULL_END
