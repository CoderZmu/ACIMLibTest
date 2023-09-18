/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <UIKit/UIKit.h>
#import "NSData+ACImageContentType.h"

typedef NSString * ACSDImageCoderOption NS_STRING_ENUM;
typedef NSDictionary<ACSDImageCoderOption, id> ACSDImageCoderOptions;
typedef NSMutableDictionary<ACSDImageCoderOption, id> ACSDImageCoderMutableOptions;

#pragma mark - Coder Options
// These options are for image decoding
/**
 A Boolean value indicating whether to decode the first frame only for animated image during decoding. (NSNumber). If not provide, decode animated image if need.
 @note works for `ACSDImageCoder`.
 */
FOUNDATION_EXPORT ACSDImageCoderOption _Nonnull const ACSDImageCoderDecodeFirstFrameOnly;

/**
 A CGFloat value which is greater than or equal to 1.0. This value specify the image scale factor for decoding. If not provide, use 1.0. (NSNumber)
 @note works for `ACSDImageCoder`, `SDProgressiveImageCoder`, `SDAnimatedImageCoder`.
 */
FOUNDATION_EXPORT ACSDImageCoderOption _Nonnull const ACSDImageCoderDecodeScaleFactor;

/**
 A Boolean value indicating whether to keep the original aspect ratio when generating thumbnail images (or bitmap images from vector format).
 Defaults to YES.
 @note works for `ACSDImageCoder`, `SDProgressiveImageCoder`, `SDAnimatedImageCoder`.
 */
FOUNDATION_EXPORT ACSDImageCoderOption _Nonnull const ACSDImageCoderDecodePreserveAspectRatio;

/**
 A CGSize value indicating whether or not to generate the thumbnail images (or bitmap images from vector format). When this value is provided, the decoder will generate a thumbnail image which pixel size is smaller than or equal to (depends the `.preserveAspectRatio`) the value size.
 Defaults to CGSizeZero, which means no thumbnail generation at all.
 @note Supports for animated image as well.
 @note When you pass `.preserveAspectRatio == NO`, the thumbnail image is stretched to match each dimension. When `.preserveAspectRatio == YES`, the thumbnail image's width is limited to pixel size's width, the thumbnail image's height is limited to pixel size's height. For common cases, you can just pass a square size to limit both.
 @note works for `ACSDImageCoder`, `SDProgressiveImageCoder`, `SDAnimatedImageCoder`.
 */
FOUNDATION_EXPORT ACSDImageCoderOption _Nonnull const ACSDImageCoderDecodeThumbnailPixelSize;

/**
 A NSString value indicating the source image's file extension. Example: "jpg", "nef", "tif", don't prefix the dot
 Some image file format share the same data structure but has different tag explanation, like TIFF and NEF/SRW, see https://en.wikipedia.org/wiki/TIFF
 Changing the file extension cause the different image result. The coder (like ImageIO) may use file extension to choose the correct parser
 @note However, different UTType may share the same file extension, like `public.jpeg` and `public.jpeg-2000` both use `.jpg`. If you want detail control, use `TypeIdentifierHint` below
 */
FOUNDATION_EXPORT ACSDImageCoderOption _Nonnull const ACSDImageCoderDecodeFileExtensionHint;

/**
 A NSString value (UTI) indicating the source image's file extension. Example: "public.jpeg-2000", "com.nikon.raw-image", "public.tiff"
 Some image file format share the same data structure but has different tag explanation, like TIFF and NEF/SRW, see https://en.wikipedia.org/wiki/TIFF
 Changing the file extension cause the different image result. The coder (like ImageIO) may use file extension to choose the correct parser
 @note If you provide `TypeIdentifierHint`, the `FileExtensionHint` option above will be ignored (because UTType has high priority)
 @note If you really don't want any hint which effect the image result, pass `NSNull.null` instead
 */
FOUNDATION_EXPORT ACSDImageCoderOption _Nonnull const ACSDImageCoderDecodeTypeIdentifierHint;

/**
 A BOOL value indicating whether to use lazy-decoding. Defaults to NO on animated image coder, but defaults to YES on static image coder.
 CGImageRef, this image object typically support lazy-decoding, via the `CGDataProviderCreateDirectAccess` or `CGDataProviderCreateSequential`
 Which allows you to provide a lazy-called callback to access bitmap buffer, so that you can achieve lazy-decoding when consumer actually need bitmap buffer
 UIKit on iOS use heavy on this and ImageIO codec prefers to lazy-decoding for common Hardware-Accelerate format like JPEG/PNG/HEIC
 But however, the consumer may access bitmap buffer when running on main queue, like CoreAnimation layer render image. So this is a trade-off
 You can force us to disable the lazy-decoding and always allocate bitmap buffer on RAM, but this may have higher ratio of OOM (out of memory)
 @note The default value is NO for animated image coder (means `animatedImageFrameAtIndex:`)
 @note The default value is YES for static image coder (means `decodedImageWithData:`)
 @note works for `ACSDImageCoder`, `SDProgressiveImageCoder`, `SDAnimatedImageCoder`.
 */
FOUNDATION_EXPORT ACSDImageCoderOption _Nonnull const ACSDImageCoderDecodeUseLazyDecoding;

/**
 A NSUInteger value to provide the limit bytes during decoding. This can help to avoid OOM on large frame count animated image or large pixel static image when you don't know how much RAM it occupied before decoding
 The decoder will do these logic based on limit bytes:
 1. Get the total frame count (static image means 1)
 2. Calculate the `framePixelSize` width/height to `sqrt(limitBytes / frameCount / bytesPerPixel)`, keeping aspect ratio (at least 1x1)
 3. If the `framePixelSize < originalImagePixelSize`, then do thumbnail decoding (see `ACSDImageCoderDecodeThumbnailPixelSize`) use the `framePixelSize` and `preseveAspectRatio = YES`
 4. Else, use the full pixel decoding (small than limit bytes)
 5. Whatever result, this does not effect the animated/static behavior of image. So even if you set `limitBytes = 1 && frameCount = 100`, we will stll create animated image with each frame `1x1` pixel size.
 @note You can use the logic from `+[ACSDImageCoder scaledSizeWithImageSize:limitBytes:bytesPerPixel:frameCount:]`
 @note This option has higher priority than `.decodeThumbnailPixelSize`
 */
FOUNDATION_EXPORT ACSDImageCoderOption _Nonnull const ACSDImageCoderDecodeScaleDownLimitBytes;

// These options are for image encoding
/**
 A Boolean value indicating whether to encode the first frame only for animated image during encoding. (NSNumber). If not provide, encode animated image if need.
 @note works for `ACSDImageCoder`.
 */
FOUNDATION_EXPORT ACSDImageCoderOption _Nonnull const ACSDImageCoderEncodeFirstFrameOnly;
/**
 A double value between 0.0-1.0 indicating the encode compression quality to produce the image data. 1.0 resulting in no compression and 0.0 resulting in the maximum compression possible. If not provide, use 1.0. (NSNumber)
 @note works for `ACSDImageCoder`
 */
FOUNDATION_EXPORT ACSDImageCoderOption _Nonnull const ACSDImageCoderEncodeCompressionQuality;

/**
 A UIColor(NSColor) value to used for non-alpha image encoding when the input image has alpha channel, the background color will be used to compose the alpha one. If not provide, use white color.
 @note works for `ACSDImageCoder`
 */
FOUNDATION_EXPORT ACSDImageCoderOption _Nonnull const ACSDImageCoderEncodeBackgroundColor;

/**
 A CGSize value indicating the max image resolution in pixels during encoding. For vector image, this also effect the output vector data information about width and height. The encoder will not generate the encoded image larger than this limit. Note it always use the aspect ratio of input image..
 Defaults to CGSizeZero, which means no max size limit at all.
 @note Supports for animated image as well.
 @note The output image's width is limited to pixel size's width, the output image's height is limited to pixel size's height. For common cases, you can just pass a square size to limit both.
 @note works for `ACSDImageCoder`
 */
FOUNDATION_EXPORT ACSDImageCoderOption _Nonnull const ACSDImageCoderEncodeMaxPixelSize;

/**
 A NSUInteger value specify the max output data bytes size after encoding. Some lossy format like JPEG/HEIF supports the hint for codec to automatically reduce the quality and match the file size you want. Note this option will override the `ACSDImageCoderEncodeCompressionQuality`, because now the quality is decided by the encoder. (NSNumber)
 @note This is a hint, no guarantee for output size because of compression algorithm limit. And this options does not works for vector images.
 @note works for `ACSDImageCoder`
 */
FOUNDATION_EXPORT ACSDImageCoderOption _Nonnull const ACSDImageCoderEncodeMaxFileSize;

/**
 A Boolean value indicating the encoding format should contains a thumbnail image into the output data. Only some of image format (like JPEG/HEIF/AVIF) support this behavior. The embed thumbnail will be used during next time thumbnail decoding (provided `.thumbnailPixelSize`), which is faster than full image thumbnail decoding. (NSNumber)
 Defaults to NO, which does not embed any thumbnail.
 @note The thumbnail image's pixel size is not defined, the encoder can choose the proper pixel size which is suitable for encoding quality.
 @note works for `ACSDImageCoder`
 */
FOUNDATION_EXPORT ACSDImageCoderOption _Nonnull const ACSDImageCoderEncodeEmbedThumbnail;

/**
 A SDWebImageContext object which hold the original context options from top-level API. (SDWebImageContext)
 This option is ignored for all built-in coders and take no effect.
 But this may be useful for some custom coders, because some business logic may dependent on things other than image or image data information only.
 Only the unknown context from top-level API (See SDWebImageDefine.h) may be passed in during image loading.
 See `SDWebImageContext` for more detailed information.
 @warning Deprecated. This does nothing from 5.14.0. Use `SDWebImageContextImageDecodeOptions` to pass additional information in top-level API, and use `ACSDImageCoderOptions` to retrieve options from coder.
 */
FOUNDATION_EXPORT ACSDImageCoderOption _Nonnull const ACSDImageCoderWebImageContext API_DEPRECATED("No longer supported. Use SDWebImageContextDecodeOptions in loader API to provide options. Use ACSDImageCoderOptions in coder API to retrieve options.", macos(10.10, 10.10), ios(8.0, 8.0), tvos(9.0, 9.0), watchos(2.0, 2.0));

#pragma mark - Coder
/**
 This is the image coder protocol to provide custom image decoding/encoding.
 These methods are all required to implement.
 @note Pay attention that these methods are not called from main queue.
 */
@protocol ACSDImageCoder <NSObject>

#pragma mark - Encoding

/**
 Returns YES if this coder can encode some image. Otherwise, it should be passed to another coder.
 For custom coder which introduce new image format, you'd better define a new `ACSDImageFormat` using like this. If you're creating public coder plugin for new image format, also update `https://github.com/rs/SDWebImage/wiki/Coder-Plugin-List` to avoid same value been defined twice.
 * @code
 static const ACSDImageFormat ACSDImageFormatHEIF = 10;
 * @endcode
 
 @param format The image format
 @return YES if this coder can encode the image, NO otherwise
 */
- (BOOL)canEncodeToFormat:(ACSDImageFormat)format NS_SWIFT_NAME(canEncode(to:));

/**
 Encode the image to image data.
 @note This protocol may supports encode animated image frames. You can use `+[ACSDImageCoderHelper framesFromAnimatedImage:]` to assemble an animated image with frames. But this consume time is not always reversible. In 5.15.0, we introduce `encodedDataWithFrames` API for better animated image encoding. Use that instead.
 @note Which means, this just forward to `encodedDataWithFrames([ACSDImageFrame(image: image, duration: 0], image.acsd_imageLoopCount))`

 @param image The image to be encoded
 @param format The image format to encode, you should note `ACSDImageFormatUndefined` format is also  possible
 @param options A dictionary containing any encoding options. Pass @{ACSDImageCoderEncodeCompressionQuality: @(1)} to specify compression quality.
 @return The encoded image data
 */
- (nullable NSData *)encodedDataWithImage:(nullable UIImage *)image
                                   format:(ACSDImageFormat)format
                                  options:(nullable ACSDImageCoderOptions *)options;

@end
