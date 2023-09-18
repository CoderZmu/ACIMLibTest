//
//  ACPackageBuilder.h
//  ACConnection
//
//  Created by 子木 on 2022/6/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACPacketBuilder : NSObject

+ (NSData *)buildProtocolPackageWithCommandId:(int32_t)commandId payload:(NSData *)payload;
@end

NS_ASSUME_NONNULL_END
