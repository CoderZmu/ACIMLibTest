//
//  NSNumber+ACAdd.m
//  ACIMLib
//
//  Created by 子木 on 2022/6/13.
//

#import "NSNumber+ACAdd.h"

@implementation NSNumber (ACAdd)

- (int32_t)ac_int32Value
{
    return (int32_t)[self intValue];
}

- (int64_t)ac_int64Value
{
    return (int64_t)[self longLongValue];
}

@end
