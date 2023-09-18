/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "ACSDImageCodersManager.h"
#import "ACSDImageIOCoder.h"
#import "ACSDImageWebPCoder.h"

@interface ACSDImageCodersManager ()

@property (nonatomic, strong, nonnull) NSMutableArray<id<ACSDImageCoder>> *imageCoders;

@end

@implementation ACSDImageCodersManager

+ (nonnull instancetype)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        // initialize with default coders
        _imageCoders = [NSMutableArray arrayWithArray:@[[ACSDImageIOCoder sharedCoder], [ACSDImageWebPCoder sharedCoder]]];
    }
    return self;
}

- (NSArray<id<ACSDImageCoder>> *)coders {
    NSArray<id<ACSDImageCoder>> *coders = [_imageCoders copy];
    return coders;
}


#pragma mark - ACSDImageCoder

- (BOOL)canEncodeToFormat:(ACSDImageFormat)format {
    NSArray<id<ACSDImageCoder>> *coders = self.coders;
    for (id<ACSDImageCoder> coder in coders.reverseObjectEnumerator) {
        if ([coder canEncodeToFormat:format]) {
            return YES;
        }
    }
    return NO;
}

- (NSData *)encodedDataWithImage:(UIImage *)image format:(ACSDImageFormat)format options:(nullable ACSDImageCoderOptions *)options {
    if (!image) {
        return nil;
    }
    NSArray<id<ACSDImageCoder>> *coders = self.coders;
    for (id<ACSDImageCoder> coder in coders.reverseObjectEnumerator) {
        if ([coder canEncodeToFormat:format]) {
            return [coder encodedDataWithImage:image format:format options:options];
        }
    }
    return nil;
}

@end
