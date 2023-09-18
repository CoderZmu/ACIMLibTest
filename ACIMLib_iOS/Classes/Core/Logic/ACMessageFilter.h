//
//  ACMessageFilter.h
//  ACIMLib
//
//  Created by 子木 on 2022/8/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACMessageFilter : NSObject

- (NSArray *)filter:(NSArray *)arr;
- (NSArray *)filterSentOutMessages:(NSArray *)arr;
- (NSArray *)filterUndecodeMessage:(NSArray *)arr;
@end

NS_ASSUME_NONNULL_END
