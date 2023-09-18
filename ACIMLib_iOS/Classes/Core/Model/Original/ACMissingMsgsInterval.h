//
//  ACMissingMsgsInterval.h
//  ACIMLib
//
//  Created by 子木 on 2022/8/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACMissingMsgsInterval : NSObject<NSCopying>

@property (nonatomic, assign) long left;
@property (nonatomic, assign) long right;

- (instancetype)initWithLeft:(long)left right:(long)right;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

@end

NS_ASSUME_NONNULL_END
