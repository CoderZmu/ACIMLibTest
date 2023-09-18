//
//  ACSocketManager+Request.h
//  ACConnection
//
//  Created by 子木 on 2022/6/13.
//

#import "ACSocketManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACSocketManager (Request)

- (void)sendRequest:(int32_t)commandId
                 data:(NSData *)data
              timeout:(NSTimeInterval)timeout
              success:(ACSocketSuccessBlock)success
            failure:(ACSocketFailureBlock)failure;

- (void)sendReq:(nullable NSData*)data withTimeout:(NSTimeInterval)timeout withUrl:(int32_t)url responseBlock:(ACDataResultBlock)block;

@end

NS_ASSUME_NONNULL_END
