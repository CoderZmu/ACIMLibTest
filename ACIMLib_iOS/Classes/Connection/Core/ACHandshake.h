//
//  ACHandShakeManager.h
//  ACConnection
//
//  Created by 子木 on 2022/6/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ACHandshakeCompletionBlock)(BOOL success, NSString * _Nullable key, NSString * _Nullable iv);

// 运用ECDHE算法完成密钥交互

@interface ACHandshake : NSObject

- (void)start:(ACHandshakeCompletionBlock)completion operationQueue:(dispatch_queue_t)oq;

@end

NS_ASSUME_NONNULL_END
