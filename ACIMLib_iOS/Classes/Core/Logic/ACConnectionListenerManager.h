//
//  ACConnectionListenerManager.h
//  ACIMLib
//
//  Created by 子木 on 2022/7/1.
//

#import <Foundation/Foundation.h>
#import "ACConnectionListenerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACConnectionListenerManager : NSObject<ACConnectionListenerProtocol>

+ (ACConnectionListenerManager *)shared;
- (void)addListener:(id<ACConnectionListenerProtocol>)listener;

@end

NS_ASSUME_NONNULL_END
