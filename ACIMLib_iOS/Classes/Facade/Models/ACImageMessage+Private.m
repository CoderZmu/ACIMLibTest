//
//  ACImageMessage+Private.m
//  ACIMLib
//
//  Created by 子木 on 2023/9/18.
//

#import "ACImageMessage+Private.h"
#import <objc/runtime.h>

@implementation ACImageMessage (Private)

- (void)setOriginalImage:(UIImage *)originalImage {
    objc_setAssociatedObject(self, @selector(originalImage), originalImage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIImage *)originalImage {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setOriginalImageData:(NSData *)originalImageData {
    objc_setAssociatedObject(self, @selector(originalImageData), originalImageData, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSData *)originalImageData {
    return objc_getAssociatedObject(self, _cmd);
}


@end
