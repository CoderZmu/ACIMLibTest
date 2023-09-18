//
//  ACSocketPacketMo.h
//  ACIMLib
//
//  Created by 子木 on 2022/11/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACRetriedPacketMo : NSObject
@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, assign) int32_t url;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, assign) int times;
@end

NS_ASSUME_NONNULL_END
