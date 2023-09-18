//
//  ACSocketManager+Request.m
//  ACConnection
//
//  Created by 子木 on 2022/6/13.
//

#import "ACSocketManager+Request.h"
#import "ACSocketServer.h"

@implementation ACSocketManager (Request)


- (void)sendRequest:(int32_t)commandId
                 data:(NSData *)data
              timeout:(NSTimeInterval)timeout
              success:(ACSocketSuccessBlock)success
            failure:(ACSocketFailureBlock)failure {
    [self.socketServer sendRequest:commandId data:data timeout:timeout success:success failure:failure];
}

- (void)sendReq:(NSData*)data withTimeout:(NSTimeInterval)timeout withUrl:(int32_t)url responseBlock:(ACDataResultBlock)block {
    [self sendRequest:url data:data timeout:timeout success:^(NSData *response) {
        block(response, -1, [NSError errorWithDomain:@"success" code:0 userInfo:nil]);
    } failure:^(NSError *error, NSInteger code) {
        block(nil, -1, error);
    }];
}

@end
