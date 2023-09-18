//
//  ACGIFMessage+Private.m
//  ACIMLib
//
//  Created by 子木 on 2023/9/18.
//

#import "ACGIFMessage+Private.h"
#import <objc/runtime.h>

@implementation ACGIFMessage (Private)

- (void)setGifData:(NSData *)gifData {
    objc_setAssociatedObject(self, @selector(gifData), gifData, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSData *)gifData {
    return objc_getAssociatedObject(self, _cmd);;
}
@end
