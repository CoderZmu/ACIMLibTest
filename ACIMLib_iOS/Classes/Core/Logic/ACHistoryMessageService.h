//
//  ACHistoryMessageService.h
//  ACIMLib
//
//  Created by 子木 on 2022/8/2.
//

#import <Foundation/Foundation.h>
#import "ACStatusDefine.h"
#import "ACHistoryMessageOption.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACHistoryMessageService : NSObject

+ (ACHistoryMessageService *)shared;

- (void)getMessages:(ACConversationType)conversationType
           targetId:(long)targetId
          channelId:(NSString *)channelId
             option:(ACHistoryMessageOption *)option
           complete:(void (^)(NSArray *messages, ACErrorCode code))complete;

@end



@class ACMessage;

typedef void (^ACGetHistoryMessageCompleteBlock)(NSArray<ACMessage *> *messages, ACErrorCode code);

@interface ACGetHistoryMessageOperation: NSOperation

- (instancetype)init:(ACConversationType)conversationType
            targetId:(long)targetId
           channelId:(NSString *)channelId
              option:(ACHistoryMessageOption *)option
       completeBlock:(ACGetHistoryMessageCompleteBlock)completeBlock;

@end
NS_ASSUME_NONNULL_END
