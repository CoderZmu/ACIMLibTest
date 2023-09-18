/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <UIKit/UIKit.h>
#import <ImageIO/ImageIO.h>

/**
 Provide some common helper methods for building the image decoder/encoder.
 */
@interface ACSDImageCoderHelper : NSObject

#pragma mark - Preferred Rendering Format
/// For coders who use `CGImageCreate`, use the information below to create an effient CGImage which can be render on GPU without Core Animation's extra copy (`CA::Render::copy_image`), which can be debugged using `Color Copied Image` in Xcode Instruments
/// `CGImageCreate`'s `bytesPerRow`, `space`, `bitmapInfo` params should use the information below.
/**
 Return the shared device-dependent RGB color space. This follows The Get Rule.
 Because it's shared, you should not retain or release this object.
 Typically is sRGB for iOS, screen color space (like Color LCD) for macOS.
 
 @return The device-dependent RGB color space
 */
+ (CGColorSpaceRef _Nonnull)colorSpaceGetDeviceRGB CF_RETURNS_NOT_RETAINED;

/**
 Check whether CGImage contains alpha channel.
 
 @param cgImage The CGImage
 @return Return YES if CGImage contains alpha channel, otherwise return NO
 */
+ (BOOL)CGImageContainsAlpha:(_Nonnull CGImageRef)cgImage;

/** Scale the image size based on provided scale size, whether or not to preserve aspect ratio, whether or not to scale up.
 @note For example, if you implements thumnail decoding, pass `shouldScaleUp` to NO to avoid the calculated size larger than image size.
 
 @param imageSize The image size (in pixel or point defined by caller)
 @param scaleSize The scale size (in pixel or point defined by caller)
 @param preserveAspectRatio Whether or not to preserve aspect ratio
 @param shouldScaleUp Whether or not to scale up (or scale down only)
 */
+ (CGSize)scaledSizeWithImageSize:(CGSize)imageSize scaleSize:(CGSize)scaleSize preserveAspectRatio:(BOOL)preserveAspectRatio shouldScaleUp:(BOOL)shouldScaleUp;

/// Calculate the limited image size with the bytes, when using `ACSDImageCoderDecodeScaleDownLimitBytes`. This preserve aspect ratio and never scale up
/// @param imageSize The image size (in pixel or point defined by caller)
/// @param limitBytes The limit bytes
/// @param bytesPerPixel The bytes per pixel
/// @param frameCount The image frame count, 0 means 1 frame as well
+ (CGSize)scaledSizeWithImageSize:(CGSize)imageSize limitBytes:(NSUInteger)limitBytes bytesPerPixel:(NSUInteger)bytesPerPixel frameCount:(NSUInteger)frameCount;

/**
 Convert an iOS orientation to an EXIF image orientation.

 @param imageOrientation iOS orientation
 @return EXIF orientation
 */
+ (CGImagePropertyOrientation)exifOrientationFromImageOrientation:(UIImageOrientation)imageOrientation;

@end
