/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "ACSDImageCoderHelper.h"
#import "ACSDImageFrame.h"
#import "NSData+ACImageContentType.h"
//#import "SDInternalMacros.h"
//#import "SDInternalMacros.h"
#import <Accelerate/Accelerate.h>


@implementation ACSDImageCoderHelper


+ (CGColorSpaceRef)colorSpaceGetDeviceRGB {
    static CGColorSpaceRef colorSpace;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
#if SD_MAC
        NSScreen *mainScreen = nil;
        if (@available(macOS 10.12, *)) {
            mainScreen = [NSScreen mainScreen];
        } else {
            mainScreen = [NSScreen screens].firstObject;
        }
        colorSpace = mainScreen.colorSpace.CGColorSpace;
#else
        colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
#endif
    });
    return colorSpace;
}


+ (BOOL)CGImageContainsAlpha:(CGImageRef)cgImage {
    if (!cgImage) {
        return NO;
    }
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(cgImage);
    BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
                      alphaInfo == kCGImageAlphaNoneSkipFirst ||
                      alphaInfo == kCGImageAlphaNoneSkipLast);
    return hasAlpha;
}

+ (CGSize)scaledSizeWithImageSize:(CGSize)imageSize scaleSize:(CGSize)scaleSize preserveAspectRatio:(BOOL)preserveAspectRatio shouldScaleUp:(BOOL)shouldScaleUp {
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat resultWidth;
    CGFloat resultHeight;
    
    if (width <= 0 || height <= 0 || scaleSize.width <= 0 || scaleSize.height <= 0) {
        // Protect
        resultWidth = width;
        resultHeight = height;
    } else {
        // Scale to fit
        if (preserveAspectRatio) {
            CGFloat pixelRatio = width / height;
            CGFloat scaleRatio = scaleSize.width / scaleSize.height;
            if (pixelRatio > scaleRatio) {
                resultWidth = scaleSize.width;
                resultHeight = ceil(scaleSize.width / pixelRatio);
            } else {
                resultHeight = scaleSize.height;
                resultWidth = ceil(scaleSize.height * pixelRatio);
            }
        } else {
            // Stretch
            resultWidth = scaleSize.width;
            resultHeight = scaleSize.height;
        }
        if (!shouldScaleUp) {
            // Scale down only
            resultWidth = MIN(width, resultWidth);
            resultHeight = MIN(height, resultHeight);
        }
    }
    
    return CGSizeMake(resultWidth, resultHeight);
}

+ (CGSize)scaledSizeWithImageSize:(CGSize)imageSize limitBytes:(NSUInteger)limitBytes bytesPerPixel:(NSUInteger)bytesPerPixel frameCount:(NSUInteger)frameCount {
    if (CGSizeEqualToSize(imageSize, CGSizeZero)) return CGSizeMake(1, 1);
    NSUInteger totalFramePixelSize = limitBytes / bytesPerPixel / (frameCount ?: 1);
    CGFloat ratio = imageSize.height / imageSize.width;
    CGFloat width = sqrt(totalFramePixelSize / ratio);
    CGFloat height = width * ratio;
    width = MAX(1, floor(width));
    height = MAX(1, floor(height));
    CGSize size = CGSizeMake(width, height);
    
    return size;
}


// Convert an iOS orientation to an EXIF image orientation.
+ (CGImagePropertyOrientation)exifOrientationFromImageOrientation:(UIImageOrientation)imageOrientation {
    CGImagePropertyOrientation exifOrientation = kCGImagePropertyOrientationUp;
    switch (imageOrientation) {
        case UIImageOrientationUp:
            exifOrientation = kCGImagePropertyOrientationUp;
            break;
        case UIImageOrientationDown:
            exifOrientation = kCGImagePropertyOrientationDown;
            break;
        case UIImageOrientationLeft:
            exifOrientation = kCGImagePropertyOrientationLeft;
            break;
        case UIImageOrientationRight:
            exifOrientation = kCGImagePropertyOrientationRight;
            break;
        case UIImageOrientationUpMirrored:
            exifOrientation = kCGImagePropertyOrientationUpMirrored;
            break;
        case UIImageOrientationDownMirrored:
            exifOrientation = kCGImagePropertyOrientationDownMirrored;
            break;
        case UIImageOrientationLeftMirrored:
            exifOrientation = kCGImagePropertyOrientationLeftMirrored;
            break;
        case UIImageOrientationRightMirrored:
            exifOrientation = kCGImagePropertyOrientationRightMirrored;
            break;
        default:
            break;
    }
    return exifOrientation;
}

@end
