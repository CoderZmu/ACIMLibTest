//
//  ACIMStatus.m
//  ACIMLib
//
//  Created by 子木 on 2022/8/8.
//

#import "ACIMGlobal.h"

@interface ACIMGlobal()
@property (nonatomic, assign, readwrite) BOOL hasInitialized;
@property (nonatomic, assign, readwrite) BOOL isConnectionExist;
@property (nonatomic, assign, readwrite) BOOL isUserDataInitialized;
@end

@implementation ACIMGlobal

+ (ACIMGlobal *)shared {
    static ACIMGlobal *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ACIMGlobal alloc] init];
    });
    return instance;
}

- (void)setHasInitialized {
    _hasInitialized = YES;
}

- (void)setUserDataInitialized:(BOOL)val {
    _isUserDataInitialized = val;
}

- (void)setHasCreatedConnection:(BOOL)val {
    _isConnectionExist = val;
}

@end
