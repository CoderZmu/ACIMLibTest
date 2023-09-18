//
//  ACMessageMediaLocalUrlFetcher.h
//  ACIMLib
//
//  Created by 子木 on 2023/8/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ACMessage;
@interface ACMessageMediaLocalPathFetcher : NSObject

+ (NSString *)mediaPathForMediaMessage:(ACMessage *)message;
@end

NS_ASSUME_NONNULL_END
