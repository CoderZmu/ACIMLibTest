//
//  ACRequestResender.h
//  ACIMLib
//
//  Created by 子木 on 2022/11/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACSocketPacketResender : NSObject

+ (ACSocketPacketResender *)shared;
@end

NS_ASSUME_NONNULL_END
