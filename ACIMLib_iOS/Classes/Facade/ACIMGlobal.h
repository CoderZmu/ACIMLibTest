//
//  ACIMStatus.h
//  ACIMLib
//
//  Created by 子木 on 2022/8/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACIMGlobal : NSObject

@property (nonatomic, assign, readonly) BOOL hasInitialized;
@property (nonatomic, assign, readonly) BOOL isConnectionExist;
@property (nonatomic, assign, readonly) BOOL isUserDataInitialized;

+ (ACIMGlobal *)shared;

- (void)setHasInitialized;
- (void)setUserDataInitialized:(BOOL)val;
- (void)setHasCreatedConnection:(BOOL)val;

@end

NS_ASSUME_NONNULL_END
