//
//  ACOssCopyObjectMeta.h
//  Sugram
//
//  Created by 子木 on 2023/1/11.
//  Copyright © 2023 Sugram. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACOssCopyObjectMeta : NSObject

@property (nonatomic, copy) NSString *sourceKey;

@property (nonatomic, copy) NSString *destKey;

+ (instancetype)instanceWithSourceKey:(NSString *)sourceKey destKey:(NSString *)destKey;

@end

NS_ASSUME_NONNULL_END
