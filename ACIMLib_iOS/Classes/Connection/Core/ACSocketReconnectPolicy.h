//
//  ACSocketReconnectPolicy.h
//  ACIMLib
//
//  Created by 子木 on 2022/6/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACSocketReconnectPolicy : NSObject

- (void)reconnect:(void(^)(void))callback;

- (void)cancel;

@end

NS_ASSUME_NONNULL_END
