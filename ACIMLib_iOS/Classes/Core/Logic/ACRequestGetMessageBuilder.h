//
//  SGRequestGetMessageBuilder.h
//  Sugram
//
//  Created by gossip on 16/12/3.
//  Copyright © 2016年 gossip. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AcpbGlobalStructure.pbobjc.h"

@class SGraphObjectNode;
@class SGraphListNode;
@class ACMessageMo;


@interface ACRequestGetMessageBuilder : NSObject

+ (ACRequestGetMessageBuilder*)builder;

+ (void)loadNewMessageWithSeqNo:(long)seqNo;

+ (BOOL)isOfflineMessagesLoaded;

@end


typedef void (^ACGetMessageSuccessBlock)(int64_t offset, int64_t seqno);
typedef void (^ACGetMessageErrorBlock)(NSInteger code);


@interface ACGetMessageOperation: NSOperation

- (instancetype)initWithReqOffSet:(long)offSet rowCount:(int)rowCount isLoadOffLineMsg:(BOOL)isLoadOffLineMsg;

- (void)setSuccessBlock:(ACGetMessageSuccessBlock)successBlock errorBlock:(ACGetMessageErrorBlock)errorBlock;

@end
