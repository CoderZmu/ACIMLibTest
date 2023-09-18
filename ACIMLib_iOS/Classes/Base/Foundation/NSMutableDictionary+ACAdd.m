//
//  NSMutableDictionary+SPNullSafe.m
//  SPCategory_Example
//
//  Created by 子木 on 2019/10/21.
//  
//

#import "NSMutableDictionary+ACAdd.h"

@implementation NSMutableDictionary (ACAdd)

- (void)ac_setSafeObject:(id)anObject forKey:(id <NSCopying>)aKey {
    if (anObject && aKey) {
        [self setObject:anObject forKey:aKey];
    }
}

@end
