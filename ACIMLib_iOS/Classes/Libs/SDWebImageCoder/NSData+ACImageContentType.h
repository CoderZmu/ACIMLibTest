/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Fabrice Aneche
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>

#define kACSDUTTypeHEIC  ((__bridge CFStringRef)@"public.heic")
#define kACSDUTTypeHEIF  ((__bridge CFStringRef)@"public.heif")
// HEIC Sequence (Animated Image)
#define kACSDUTTypeHEICS ((__bridge CFStringRef)@"public.heics")
// kACSDUTTypeWebP seems not defined in public UTI framework, Apple use the hardcode string, we define them :)
#define kACSDUTTypeWebP  ((__bridge CFStringRef)@"org.webmproject.webp")

#define kACSDUTTypeImage ((__bridge CFStringRef)@"public.image")
#define kACSDUTTypeJPEG  ((__bridge CFStringRef)@"public.jpeg")
#define kACSDUTTypePNG   ((__bridge CFStringRef)@"public.png")
#define kACSDUTTypeTIFF  ((__bridge CFStringRef)@"public.tiff")
#define kACSDUTTypeSVG   ((__bridge CFStringRef)@"public.svg-image")
#define kACSDUTTypeGIF   ((__bridge CFStringRef)@"com.compuserve.gif")
#define kACSDUTTypePDF   ((__bridge CFStringRef)@"com.adobe.pdf")
#define kACSDUTTypeBMP   ((__bridge CFStringRef)@"com.microsoft.bmp")
#define kACSDUTTypeRAW   ((__bridge CFStringRef)@"public.camera-raw-image")
/**
 You can use switch case like normal enum. It's also recommended to add a default case. You should not assume anything about the raw value.
 For custom coder plugin, it can also extern the enum for supported format. See `ACSDImageCoder` for more detailed information.
 */
typedef NSInteger ACSDImageFormat NS_TYPED_EXTENSIBLE_ENUM;
static const ACSDImageFormat ACSDImageFormatUndefined = -1;
static const ACSDImageFormat ACSDImageFormatJPEG      = 0;
static const ACSDImageFormat ACSDImageFormatPNG       = 1;
static const ACSDImageFormat ACSDImageFormatGIF       = 2;
static const ACSDImageFormat ACSDImageFormatTIFF      = 3;
static const ACSDImageFormat ACSDImageFormatWebP      = 4;
static const ACSDImageFormat ACSDImageFormatHEIC      = 5;
static const ACSDImageFormat ACSDImageFormatHEIF      = 6;
static const ACSDImageFormat ACSDImageFormatPDF       = 7;
static const ACSDImageFormat ACSDImageFormatSVG       = 8;
static const ACSDImageFormat ACSDImageFormatBMP       = 9;
static const ACSDImageFormat ACSDImageFormatRAW       = 10;

/**
 NSData category about the image content type and UTI.
 */
@interface NSData (ACImageContentType)

/**
 *  Return image format
 *
 *  @param data the input image data
 *
 *  @return the image format as `ACSDImageFormat` (enum)
 */
+ (ACSDImageFormat)acsd_imageFormatForImageData:(nullable NSData *)data;

/**
 *  Convert ACSDImageFormat to UTType
 *
 *  @param format Format as ACSDImageFormat
 *  @return The UTType as CFStringRef
 *  @note For unknown format, `kACSDUTTypeImage` abstract type will return
 */
+ (nonnull CFStringRef)acsd_UTTypeFromImageFormat:(ACSDImageFormat)format CF_RETURNS_NOT_RETAINED NS_SWIFT_NAME(acsd_UTType(from:));

/**
 *  Convert UTType to ACSDImageFormat
 *
 *  @param uttype The UTType as CFStringRef
 *  @return The Format as ACSDImageFormat
 *  @note For unknown type, `ACSDImageFormatUndefined` will return
 */
+ (ACSDImageFormat)acsd_imageFormatFromUTType:(nonnull CFStringRef)uttype;

@end
