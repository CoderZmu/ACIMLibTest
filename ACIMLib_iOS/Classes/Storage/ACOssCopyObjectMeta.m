//
//  ACOssCopyObjectMeta.m
//  Sugram
//
//  Created by 子木 on 2023/1/11.
//  Copyright © 2023 Sugram. All rights reserved.
//

#import "ACOssCopyObjectMeta.h"

@implementation ACOssCopyObjectMeta

+ (instancetype)instanceWithSourceKey:(NSString *)sourceKey destKey:(NSString *)destKey {
    ACOssCopyObjectMeta *instance = [[ACOssCopyObjectMeta alloc] init];
    instance.sourceKey = sourceKey;
    instance.destKey = destKey;
    return instance;
}
@end
