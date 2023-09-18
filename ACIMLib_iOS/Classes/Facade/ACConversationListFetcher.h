//
//  ACConversationListFetcher.h
//  ACIMLib
//
//  Created by 子木 on 2022/9/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ACConversation;
@interface ACConversationListFetcher : NSObject

- (NSArray *)getConversationList:(NSArray *)conversationTypeList;
- (NSArray *)getConversationList:(NSArray *)conversationTypeList count:(int)count startTime:(long long)startTime;
- (NSArray<ACConversation *> *)getTopConversationList:(NSArray *)conversationTypeList;
- (NSArray<ACConversation *> *)getBlockedConversationList:(NSArray *)conversationTypeList;

@end

NS_ASSUME_NONNULL_END
