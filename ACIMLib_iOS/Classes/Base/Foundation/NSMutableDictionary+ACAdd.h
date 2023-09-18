//
//  NSMutableDictionary+SPNullSafe.h
//  SPCategory_Example
//
//  Created by 子木 on 2019/10/21.
//  
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableDictionary (ACAdd)
- (void)ac_setSafeObject:(id)anObject forKey:(id <NSCopying>)aKey;

@end

NS_ASSUME_NONNULL_END
