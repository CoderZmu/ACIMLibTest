//
//  ACMediaMessageContent+Private.m
//  ACIMLib
//
//  Created by 子木 on 2023/9/13.
//

#import "ACMediaMessageContent+Private.h"
#import <objc/runtime.h>

@implementation ACMediaMessageContent (Private)

- (void)setTmpOriginalLocalPath:(NSString *)tmpOriginalLocalPath {
    objc_setAssociatedObject(self, @selector(tmpOriginalLocalPath), tmpOriginalLocalPath, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)tmpOriginalLocalPath {
    return objc_getAssociatedObject(self, _cmd);
}

@end
