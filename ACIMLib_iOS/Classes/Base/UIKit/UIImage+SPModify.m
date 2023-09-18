//
//  UIImage+SPModify.m
//  SPBase_Example
//
//  Created by 子木 on 2019/6/13.
//  Copyright © 2019 ZiMu-cd. All rights reserved.
//

#import "ACSDImageCodersManager.h"
#import "ACSDWebImageWebPCoderDefine.h"
#import "UIImage+SPModify.h"

@implementation UIImage (SPModify)


- (UIImage *)sp_fixOrientation
{
    // No-op if the orientation is already correct.
    if (self.imageOrientation == UIImageOrientationUp) {
        return self;
    }

    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;

    switch (self.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, self.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;

        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;

        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, self.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;

        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }

    switch (self.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;

        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;

        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }

    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, self.size.width, self.size.height,
                                             CGImageGetBitsPerComponent(self.CGImage), 0,
                                             CGImageGetColorSpace(self.CGImage),
                                             CGImageGetBitmapInfo(self.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (self.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            CGContextDrawImage(ctx, CGRectMake(0, 0, self.size.height, self.size.width), self.CGImage);
            break;

        default:
            CGContextDrawImage(ctx, CGRectMake(0, 0, self.size.width, self.size.height), self.CGImage);
            break;
    }

    // And now we just create a new UIImage from the drawing context.
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);

    return img;
}

- (NSData *)sp_compressWithQuality:(CGFloat)quality {
    return UIImageJPEGRepresentation(self, quality);
}

// 无损压缩图片
- (NSData *)sp_losslessCompress {
    return UIImageJPEGRepresentation(self, 1);
}

// 压缩图片
- (NSData *)sp_compressIntelligently:(ACImageEncodeFormat)encodeFormat finalPixelSize:(CGSize *)finalPixelSize {
    CGFloat area = self.size.width * self.size.height;
    CGFloat maxArea = 1500 * 2000;
    CGFloat pixelRatio = MIN(1, maxArea / area);
    NSMutableDictionary *options = @{
            ACSDImageCoderEncodeMaxFileSize: @(220 * 1024),
            ACSDImageCoderEncodeFirstFrameOnly: @YES,
            ACSDImageCoderEncodeWebPMethod: @2,
        }.mutableCopy;
    CGSize maxPixelSize = self.size;

    if (pixelRatio < 1) {
        maxPixelSize = [self sp_imageNewSizeForLimitArea:pixelRatio * self.size.width * self.size.height];
        options[ACSDImageCoderEncodeMaxPixelSize] = @(maxPixelSize);
    }

    NSData *result = [[ACSDImageCodersManager sharedManager] encodedDataWithImage:self format:encodeFormat == ACImageEncodeFormat_Webp ? ACSDImageFormatWebP : ACSDImageFormatUndefined options:options];
    *finalPixelSize = maxPixelSize;
    return result;
}

- (NSData *)sp_thumbnail:(ACImageEncodeFormat)encodeFormat {
    CGSize maxPixelSize = [self sp_imageNewSizeForLimitArea:200 * 200];
    NSDictionary *options = @{
            ACSDImageCoderEncodeMaxFileSize: @(8 * 1024),
            ACSDImageCoderEncodeFirstFrameOnly: @YES,
            ACSDImageCoderEncodeMaxPixelSize: @(maxPixelSize),
    };
    NSData *result = [[ACSDImageCodersManager sharedManager] encodedDataWithImage:self format:encodeFormat == ACImageEncodeFormat_Webp ? ACSDImageFormatWebP : ACSDImageFormatUndefined options:options];

    return result;
}

- (void)sp_drawInRect:(CGRect)rect withContentMode:(UIViewContentMode)contentMode clipsToBounds:(BOOL)clips {
    CGRect drawRect = SPCGRectFitWithContentMode(rect, self.size, contentMode);

    if (drawRect.size.width == 0 || drawRect.size.height == 0) {
        return;
    }

    if (clips) {
        CGContextRef context = UIGraphicsGetCurrentContext();

        if (context) {
            CGContextSaveGState(context);
            CGContextAddRect(context, rect);
            CGContextClip(context);
            [self drawInRect:drawRect];
            CGContextRestoreGState(context);
        }
    } else {
        [self drawInRect:drawRect];
    }
}

- (CGSize)sp_imageNewSizeForLimitArea:(CGFloat)maxArea {
    CGFloat currentArea = self.size.width * self.size.height;

    if (currentArea <= maxArea) {
        return self.size;
    }

    CGFloat scaleFactor = sqrtf(maxArea / currentArea);
    CGFloat newWidth = self.size.width * scaleFactor;
    CGFloat newHeight = self.size.height * scaleFactor;
    CGSize newSize = CGSizeMake(ceilf(newWidth), ceilf(newHeight));
    return newSize;
}

- (UIImage *)sp_imageByResizeToSize:(CGSize)size {
    if (size.width <= 0 || size.height <= 0) {
        return nil;
    }

    UIGraphicsBeginImageContextWithOptions(size, NO, self.scale);
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)sp_resizeImageLimitArea:(CGFloat)maxArea {
    CGFloat currentArea = self.size.width * self.size.height;

    if (currentArea <= maxArea) {
        return self;
    }

    CGFloat scaleFactor = sqrtf(maxArea / currentArea);
    CGFloat newWidth = self.size.width * scaleFactor;
    CGFloat newHeight = self.size.height * scaleFactor;
    CGSize newSize = CGSizeMake(newWidth, newHeight);
    return [self sp_imageByResizeToSize:newSize];
}

- (UIImage *)sp_imageScaleToMaxSize:(CGSize)maxSize {
    if (self.size.width <= maxSize.width && self.size.height <= maxSize.height) {
        return self;
    }

    CGSize scaleSize = maxSize;

    if (self.size.width / self.size.height > scaleSize.width / scaleSize.height) {
        scaleSize.width = maxSize.width;
        scaleSize.height = maxSize.width * self.size.height / self.size.width;
    } else {
        scaleSize.height = maxSize.height;
        scaleSize.width = maxSize.height * self.size.width / self.size.height;
    }

    scaleSize.width = ceil(scaleSize.width);
    scaleSize.height = ceil(scaleSize.height);
    return [self sp_imageByResizeToSize:scaleSize];
}

- (UIImage *)sp_imageByResizeToSize:(CGSize)size contentMode:(UIViewContentMode)contentMode {
    if (size.width <= 0 || size.height <= 0) {
        return nil;
    }

    UIGraphicsBeginImageContextWithOptions(size, NO, self.scale);
    [self sp_drawInRect:CGRectMake(0, 0, size.width, size.height) withContentMode:contentMode clipsToBounds:NO];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)sp_imageByRoundCornerRadius:(CGFloat)radius {
    return [self sp_imageByRoundCornerRadius:radius borderWidth:0 borderColor:nil];
}

- (UIImage *)sp_imageByRoundCornerRadius:(CGFloat)radius
                             borderWidth:(CGFloat)borderWidth
                             borderColor:(UIColor *)borderColor {
    return [self sp_imageByRoundCornerRadius:radius
                                     corners:UIRectCornerAllCorners
                                 borderWidth:borderWidth
                                 borderColor:borderColor
                              borderLineJoin:kCGLineJoinMiter];
}

- (UIImage *)sp_imageByRoundCornerRadius:(CGFloat)radius
                                 corners:(UIRectCorner)corners
                             borderWidth:(CGFloat)borderWidth
                             borderColor:(UIColor *)borderColor
                          borderLineJoin:(CGLineJoin)borderLineJoin {
    if (corners != UIRectCornerAllCorners) {
        UIRectCorner tmp = 0;

        if (corners & UIRectCornerTopLeft) {
            tmp |= UIRectCornerBottomLeft;
        }

        if (corners & UIRectCornerTopRight) {
            tmp |= UIRectCornerBottomRight;
        }

        if (corners & UIRectCornerBottomLeft) {
            tmp |= UIRectCornerTopLeft;
        }

        if (corners & UIRectCornerBottomRight) {
            tmp |= UIRectCornerTopRight;
        }

        corners = tmp;
    }

    UIGraphicsBeginImageContextWithOptions(self.size, NO, self.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
    CGContextScaleCTM(context, 1, -1);
    CGContextTranslateCTM(context, 0, -rect.size.height);

    CGFloat minSize = MIN(self.size.width, self.size.height);

    if (borderWidth < minSize / 2) {
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(rect, borderWidth, borderWidth) byRoundingCorners:corners cornerRadii:CGSizeMake(radius, borderWidth)];
        [path closePath];

        CGContextSaveGState(context);
        [path addClip];
        CGContextDrawImage(context, rect, self.CGImage);
        CGContextRestoreGState(context);
    }

    if (borderColor && borderWidth < minSize / 2 && borderWidth > 0) {
        CGFloat strokeInset = (floor(borderWidth * self.scale) + 0.5) / self.scale;
        CGRect strokeRect = CGRectInset(rect, strokeInset, strokeInset);
        CGFloat strokeRadius = radius > self.scale / 2 ? radius - self.scale / 2 : 0;
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:strokeRect byRoundingCorners:corners cornerRadii:CGSizeMake(strokeRadius, borderWidth)];
        [path closePath];

        path.lineWidth = borderWidth;
        path.lineJoinStyle = borderLineJoin;
        [borderColor setStroke];
        [path stroke];
    }

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

CGRect SPCGRectFitWithContentMode(CGRect rect, CGSize size, UIViewContentMode mode) {
    rect = CGRectStandardize(rect);
    size.width = size.width < 0 ? -size.width : size.width;
    size.height = size.height < 0 ? -size.height : size.height;
    CGPoint center = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    switch (mode) {
        case UIViewContentModeScaleAspectFit:
        case UIViewContentModeScaleAspectFill: {
            if (rect.size.width < 0.01 || rect.size.height < 0.01 ||
                size.width < 0.01 || size.height < 0.01) {
                rect.origin = center;
                rect.size = CGSizeZero;
            } else {
                CGFloat scale;

                if (mode == UIViewContentModeScaleAspectFit) {
                    if (size.width / size.height < rect.size.width / rect.size.height) {
                        scale = rect.size.height / size.height;
                    } else {
                        scale = rect.size.width / size.width;
                    }
                } else {
                    if (size.width / size.height < rect.size.width / rect.size.height) {
                        scale = rect.size.width / size.width;
                    } else {
                        scale = rect.size.height / size.height;
                    }
                }

                size.width *= scale;
                size.height *= scale;
                rect.size = size;
                rect.origin = CGPointMake(center.x - size.width * 0.5, center.y - size.height * 0.5);
            }
        } break;

        case UIViewContentModeCenter: {
            rect.size = size;
            rect.origin = CGPointMake(center.x - size.width * 0.5, center.y - size.height * 0.5);
        } break;

        case UIViewContentModeTop: {
            rect.origin.x = center.x - size.width * 0.5;
            rect.size = size;
        } break;

        case UIViewContentModeBottom: {
            rect.origin.x = center.x - size.width * 0.5;
            rect.origin.y += rect.size.height - size.height;
            rect.size = size;
        } break;

        case UIViewContentModeLeft: {
            rect.origin.y = center.y - size.height * 0.5;
            rect.size = size;
        } break;

        case UIViewContentModeRight: {
            rect.origin.y = center.y - size.height * 0.5;
            rect.origin.x += rect.size.width - size.width;
            rect.size = size;
        } break;

        case UIViewContentModeTopLeft: {
            rect.size = size;
        } break;

        case UIViewContentModeTopRight: {
            rect.origin.x += rect.size.width - size.width;
            rect.size = size;
        } break;

        case UIViewContentModeBottomLeft: {
            rect.origin.y += rect.size.height - size.height;
            rect.size = size;
        } break;

        case UIViewContentModeBottomRight: {
            rect.origin.x += rect.size.width - size.width;
            rect.origin.y += rect.size.height - size.height;
            rect.size = size;
        } break;

        case UIViewContentModeScaleToFill:
        case UIViewContentModeRedraw:
        default: {
            rect = rect;
        }
    }
    return rect;
}

@end
