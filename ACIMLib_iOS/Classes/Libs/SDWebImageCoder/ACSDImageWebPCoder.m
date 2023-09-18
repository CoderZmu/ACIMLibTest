#import "ACSDImageWebPCoder.h"
@implementation ACSDImageWebPCoder
@end

///*
// * This file is part of the SDWebImage package.
// * (c) Olivier Poitrey <rs@dailymotion.com>
// *
// * For the full copyright and license information, please view the LICENSE
// * file that was distributed with this source code.
// */
//
//#import "ACSDImageWebPCoder.h"
//#import "ACSDWebImageWebPCoderDefine.h"
//#import "ACSDImageCoderHelper.h"
//#import <Accelerate/Accelerate.h>
//#import <os/lock.h>
//#import <libkern/OSAtomic.h>
//
//#if __has_include("webp/decode.h") && __has_include("webp/encode.h") && __has_include("webp/demux.h") && __has_include("webp/mux.h")
//#import "webp/decode.h"
//#import "webp/encode.h"
//#import "webp/demux.h"
//#import "webp/mux.h"
//#elif __has_include(<libwebp/decode.h>) && __has_include(<libwebp/encode.h>) && __has_include(<libwebp/demux.h>) && __has_include(<libwebp/mux.h>)
//#import <libwebp/decode.h>
//#import <libwebp/encode.h>
//#import <libwebp/demux.h>
//#import <libwebp/mux.h>
//#else
//@import libwebp;
//#endif
//
//@implementation ACSDImageWebPCoder
//
//+ (instancetype)sharedCoder {
//    static ACSDImageWebPCoder *coder;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        coder = [[ACSDImageWebPCoder alloc] init];
//    });
//    return coder;
//}
//
//#pragma mark - Encode
//- (BOOL)canEncodeToFormat:(ACSDImageFormat)format {
//    return (format == ACSDImageFormatWebP);
//}
//
//- (NSData *)encodedDataWithImage:(UIImage *)image format:(ACSDImageFormat)format options:(nullable ACSDImageCoderOptions *)options {
//    if (!image) {
//        return nil;
//    }
//    CGImageRef imageRef = image.CGImage;
//    if (!imageRef) {
//        // Earily return, supports CGImage only
//        return nil;
//    }
//    
//    ;
//    
//    double compressionQuality = 1;
//    if (options[ACSDImageCoderEncodeCompressionQuality]) {
//        compressionQuality = [options[ACSDImageCoderEncodeCompressionQuality] doubleValue];
//    }
//    CGSize maxPixelSize = CGSizeZero;
//    NSValue *maxPixelSizeValue = options[ACSDImageCoderEncodeMaxPixelSize];
//    if (maxPixelSizeValue != nil) {
//#if SD_MAC
//        maxPixelSize = maxPixelSizeValue.sizeValue;
//#else
//        maxPixelSize = maxPixelSizeValue.CGSizeValue;
//#endif
//    }
//    NSUInteger maxFileSize = 0;
//    if (options[ACSDImageCoderEncodeMaxFileSize]) {
//        maxFileSize = [options[ACSDImageCoderEncodeMaxFileSize] unsignedIntegerValue];
//    }
//    
//    NSData *data = [self acsd_encodedWebpDataWithImage:imageRef
//                                             quality:compressionQuality
//                                        maxPixelSize:maxPixelSize
//                                         maxFileSize:maxFileSize
//                                             options:options];
//    
//    
//    return data;
//}
//
//- (nullable NSData *)acsd_encodedWebpDataWithImage:(nullable CGImageRef)imageRef
//                                         quality:(double)quality
//                                    maxPixelSize:(CGSize)maxPixelSize
//                                     maxFileSize:(NSUInteger)maxFileSize
//                                         options:(nullable ACSDImageCoderOptions *)options
//{
//    NSData *webpData;
//    if (!imageRef) {
//        return nil;
//    }
//    
//    size_t width = CGImageGetWidth(imageRef);
//    size_t height = CGImageGetHeight(imageRef);
//    if (width == 0 || width > WEBP_MAX_DIMENSION) {
//        return nil;
//    }
//    if (height == 0 || height > WEBP_MAX_DIMENSION) {
//        return nil;
//    }
//    
//    size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
//    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
//    CGImageAlphaInfo alphaInfo = bitmapInfo & kCGBitmapAlphaInfoMask;
//    CGBitmapInfo byteOrderInfo = bitmapInfo & kCGBitmapByteOrderMask;
//    BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
//                      alphaInfo == kCGImageAlphaNoneSkipFirst ||
//                      alphaInfo == kCGImageAlphaNoneSkipLast);
//    BOOL byteOrderNormal = NO;
//    switch (byteOrderInfo) {
//        case kCGBitmapByteOrderDefault: {
//            byteOrderNormal = YES;
//        } break;
//        case kCGBitmapByteOrder32Little: {
//        } break;
//        case kCGBitmapByteOrder32Big: {
//            byteOrderNormal = YES;
//        } break;
//        default: break;
//    }
//    // If we can not get bitmap buffer, early return
//    CGDataProviderRef dataProvider = CGImageGetDataProvider(imageRef);
//    if (!dataProvider) {
//        return nil;
//    }
//    
//    uint8_t *rgba = NULL; // RGBA Buffer managed by CFData, don't call `free` on it, instead call `CFRelease` on `dataRef`
//    // We could not assume that input CGImage's color mode is always RGB888/RGBA8888. Convert all other cases to target color mode using vImage
//    vImage_CGImageFormat destFormat = {
//        .bitsPerComponent = 8,
//        .bitsPerPixel = hasAlpha ? 32 : 24,
//        .colorSpace = [ACSDImageCoderHelper colorSpaceGetDeviceRGB],
//        .bitmapInfo = hasAlpha ? kCGImageAlphaLast | kCGBitmapByteOrderDefault : kCGImageAlphaNone | kCGBitmapByteOrderDefault // RGB888/RGBA8888 (Non-premultiplied to works for libwebp)
//    };
//    vImage_Buffer dest;
//    vImage_Error error = vImageBuffer_InitWithCGImage(&dest, &destFormat, NULL, imageRef, kvImageNoFlags);
//    if (error != kvImageNoError) {
//        return nil;
//    }
//    rgba = dest.data;
//    bytesPerRow = dest.rowBytes;
//    
//    float qualityFactor = quality * 100; // WebP quality is 0-100
//    // Encode RGB888/RGBA8888 buffer to WebP data
//    // Using the libwebp advanced API: https://developers.google.com/speed/webp/docs/api#advanced_encoding_api
//    WebPConfig config;
//    WebPPicture picture;
//    WebPMemoryWriter writer;
//    
//    if (!WebPConfigPreset(&config, WEBP_PRESET_DEFAULT, qualityFactor) ||
//        !WebPPictureInit(&picture)) {
//        // shouldn't happen, except if system installation is broken
//        free(dest.data);
//        return nil;
//    }
//
//    [self updateWebPOptionsToConfig:&config maxFileSize:maxFileSize options:options];
//    picture.use_argb = 0; // Lossy encoding use YUV for internel bitstream
//    picture.width = (int)width;
//    picture.height = (int)height;
//    picture.writer = WebPMemoryWrite; // Output in memory data buffer
//    picture.custom_ptr = &writer;
//    WebPMemoryWriterInit(&writer);
//    
//    int result;
//    if (hasAlpha) {
//        result = WebPPictureImportRGBA(&picture, rgba, (int)bytesPerRow);
//    } else {
//        result = WebPPictureImportRGB(&picture, rgba, (int)bytesPerRow);
//    }
//    if (!result) {
//        WebPMemoryWriterClear(&writer);
//        free(dest.data);
//        return nil;
//    }
//    
//    // Check if need to scale pixel size
//    CGSize scaledSize = [ACSDImageCoderHelper scaledSizeWithImageSize:CGSizeMake(width, height) scaleSize:maxPixelSize preserveAspectRatio:YES shouldScaleUp:NO];
//    if (!CGSizeEqualToSize(scaledSize, CGSizeMake(width, height))) {
//        result = WebPPictureRescale(&picture, scaledSize.width, scaledSize.height);
//        if (!result) {
//            WebPMemoryWriterClear(&writer);
//            WebPPictureFree(&picture);
//            free(dest.data);
//            return nil;
//        }
//    }
//    
//    result = WebPEncode(&config, &picture);
//    WebPPictureFree(&picture);
//    free(dest.data);
//    
//    if (result) {
//        // success
//        webpData = [NSData dataWithBytes:writer.mem length:writer.size];
//    } else {
//        // failed
//        webpData = nil;
//    }
//    WebPMemoryWriterClear(&writer);
//    
//    return webpData;
//}
//
//- (void) updateWebPOptionsToConfig:(WebPConfig * _Nonnull)config
//                       maxFileSize:(NSUInteger)maxFileSize
//                           options:(nullable ACSDImageCoderOptions *)options {
//
//    config->target_size = (int)maxFileSize; // Max filesize for output, 0 means use quality instead
//    config->pass = maxFileSize > 0 ? 6 : 1; // Use 6 passes for file size limited encoding, which is the default value of `cwebp` command line
//    config->lossless = 0; // Disable lossless encoding (If we need, can add new Encoding Options in future version)
//    
//    config->method = GetIntValueForKey(options, ACSDImageCoderEncodeWebPMethod, config->method);
//    config->pass = GetIntValueForKey(options, ACSDImageCoderEncodeWebPPass, config->pass);
//    config->preprocessing = GetIntValueForKey(options, ACSDImageCoderEncodeWebPPreprocessing, config->preprocessing);
//    config->thread_level = GetIntValueForKey(options, ACSDImageCoderEncodeWebPThreadLevel, 1);
//    config->low_memory = GetIntValueForKey(options, ACSDImageCoderEncodeWebPLowMemory, config->low_memory);
//    config->target_PSNR = GetFloatValueForKey(options, ACSDImageCoderEncodeWebPTargetPSNR, config->target_PSNR);
//    config->segments = GetIntValueForKey(options, ACSDImageCoderEncodeWebPSegments, config->segments);
//    config->sns_strength = GetIntValueForKey(options, ACSDImageCoderEncodeWebPSnsStrength, config->sns_strength);
//    config->filter_strength = GetIntValueForKey(options, ACSDImageCoderEncodeWebPFilterStrength, config->filter_strength);
//    config->filter_sharpness = GetIntValueForKey(options, ACSDImageCoderEncodeWebPFilterSharpness, config->filter_sharpness);
//    config->filter_type = GetIntValueForKey(options, ACSDImageCoderEncodeWebPFilterType, config->filter_type);
//    config->autofilter = GetIntValueForKey(options, ACSDImageCoderEncodeWebPAutofilter, config->autofilter);
//    config->alpha_compression = GetIntValueForKey(options, ACSDImageCoderEncodeWebPAlphaCompression, config->alpha_compression);
//    config->alpha_filtering = GetIntValueForKey(options, ACSDImageCoderEncodeWebPAlphaFiltering, config->alpha_filtering);
//    config->alpha_quality = GetIntValueForKey(options, ACSDImageCoderEncodeWebPAlphaQuality, config->alpha_quality);
//    config->show_compressed = GetIntValueForKey(options, ACSDImageCoderEncodeWebPShowCompressed, config->show_compressed);
//    config->partitions = GetIntValueForKey(options, ACSDImageCoderEncodeWebPPartitions, config->partitions);
//    config->partition_limit = GetIntValueForKey(options, ACSDImageCoderEncodeWebPPartitionLimit, config->partition_limit);
//    config->use_sharp_yuv = GetIntValueForKey(options, ACSDImageCoderEncodeWebPUseSharpYuv, config->use_sharp_yuv);
//}
//
//
//static int GetIntValueForKey(NSDictionary * _Nonnull dictionary, NSString * _Nonnull key, int defaultValue) {
//    id value = [dictionary objectForKey:key];
//    if (value != nil) {
//        if ([value isKindOfClass: [NSNumber class]]) {
//            return [value intValue];
//        }
//    }
//    return defaultValue;
//}
//
//static float GetFloatValueForKey(NSDictionary * _Nonnull dictionary, NSString * _Nonnull key, float defaultValue) {
//    id value = [dictionary objectForKey:key];
//    if (value != nil) {
//        if ([value isKindOfClass: [NSNumber class]]) {
//            return [value floatValue];
//        }
//    }
//    return defaultValue;
//}
//
//
//@end
