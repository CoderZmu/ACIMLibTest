/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Fabrice Aneche
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "NSData+ACImageContentType.h"
#import <MobileCoreServices/MobileCoreServices.h>
//#import "ACSDImageIOAnimatedCoderInternal.h"

#define kSVGTagEnd @"</svg>"

@implementation NSData (ACImageContentType)

+ (ACSDImageFormat)acsd_imageFormatForImageData:(nullable NSData *)data {
    if (!data) {
        return ACSDImageFormatUndefined;
    }
    
    // File signatures table: http://www.garykessler.net/library/file_sigs.html
    uint8_t c;
    [data getBytes:&c length:1];
    switch (c) {
        case 0xFF:
            return ACSDImageFormatJPEG;
        case 0x89:
            return ACSDImageFormatPNG;
        case 0x47:
            return ACSDImageFormatGIF;
        case 0x49:
        case 0x4D:
            return ACSDImageFormatTIFF;
        case 0x42:
            return ACSDImageFormatBMP;
        case 0x52: {
            if (data.length >= 12) {
                //RIFF....WEBP
                NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, 12)] encoding:NSASCIIStringEncoding];
                if ([testString hasPrefix:@"RIFF"] && [testString hasSuffix:@"WEBP"]) {
                    return ACSDImageFormatWebP;
                }
            }
            break;
        }
        case 0x00: {
            if (data.length >= 12) {
                //....ftypheic ....ftypheix ....ftyphevc ....ftyphevx
                NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(4, 8)] encoding:NSASCIIStringEncoding];
                if ([testString isEqualToString:@"ftypheic"]
                    || [testString isEqualToString:@"ftypheix"]
                    || [testString isEqualToString:@"ftyphevc"]
                    || [testString isEqualToString:@"ftyphevx"]) {
                    return ACSDImageFormatHEIC;
                }
                //....ftypmif1 ....ftypmsf1
                if ([testString isEqualToString:@"ftypmif1"] || [testString isEqualToString:@"ftypmsf1"]) {
                    return ACSDImageFormatHEIF;
                }
            }
            break;
        }
        case 0x25: {
            if (data.length >= 4) {
                //%PDF
                NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(1, 3)] encoding:NSASCIIStringEncoding];
                if ([testString isEqualToString:@"PDF"]) {
                    return ACSDImageFormatPDF;
                }
            }
        }
        case 0x3C: {
            // Check end with SVG tag
            if ([data rangeOfData:[kSVGTagEnd dataUsingEncoding:NSUTF8StringEncoding] options:NSDataSearchBackwards range: NSMakeRange(data.length - MIN(100, data.length), MIN(100, data.length))].location != NSNotFound) {
                return ACSDImageFormatSVG;
            }
        }
    }
    return ACSDImageFormatUndefined;
}

+ (nonnull CFStringRef)acsd_UTTypeFromImageFormat:(ACSDImageFormat)format {
    CFStringRef UTType;
    switch (format) {
        case ACSDImageFormatJPEG:
            UTType = kACSDUTTypeJPEG;
            break;
        case ACSDImageFormatPNG:
            UTType = kACSDUTTypePNG;
            break;
        case ACSDImageFormatGIF:
            UTType = kACSDUTTypeGIF;
            break;
        case ACSDImageFormatTIFF:
            UTType = kACSDUTTypeTIFF;
            break;
        case ACSDImageFormatWebP:
            UTType = kACSDUTTypeWebP;
            break;
        case ACSDImageFormatHEIC:
            UTType = kACSDUTTypeHEIC;
            break;
        case ACSDImageFormatHEIF:
            UTType = kACSDUTTypeHEIF;
            break;
        case ACSDImageFormatPDF:
            UTType = kACSDUTTypePDF;
            break;
        case ACSDImageFormatSVG:
            UTType = kACSDUTTypeSVG;
            break;
        case ACSDImageFormatBMP:
            UTType = kACSDUTTypeBMP;
            break;
        case ACSDImageFormatRAW:
            UTType = kACSDUTTypeRAW;
            break;
        default:
            // default is kUTTypeImage abstract type
            UTType = kACSDUTTypeImage;
            break;
    }
    return UTType;
}

+ (ACSDImageFormat)acsd_imageFormatFromUTType:(CFStringRef)uttype {
    if (!uttype) {
        return ACSDImageFormatUndefined;
    }
    ACSDImageFormat imageFormat;
    if (CFStringCompare(uttype, kACSDUTTypeJPEG, 0) == kCFCompareEqualTo) {
        imageFormat = ACSDImageFormatJPEG;
    } else if (CFStringCompare(uttype, kACSDUTTypePNG, 0) == kCFCompareEqualTo) {
        imageFormat = ACSDImageFormatPNG;
    } else if (CFStringCompare(uttype, kACSDUTTypeGIF, 0) == kCFCompareEqualTo) {
        imageFormat = ACSDImageFormatGIF;
    } else if (CFStringCompare(uttype, kACSDUTTypeTIFF, 0) == kCFCompareEqualTo) {
        imageFormat = ACSDImageFormatTIFF;
    } else if (CFStringCompare(uttype, kACSDUTTypeWebP, 0) == kCFCompareEqualTo) {
        imageFormat = ACSDImageFormatWebP;
    } else if (CFStringCompare(uttype, kACSDUTTypeHEIC, 0) == kCFCompareEqualTo) {
        imageFormat = ACSDImageFormatHEIC;
    } else if (CFStringCompare(uttype, kACSDUTTypeHEIF, 0) == kCFCompareEqualTo) {
        imageFormat = ACSDImageFormatHEIF;
    } else if (CFStringCompare(uttype, kACSDUTTypePDF, 0) == kCFCompareEqualTo) {
        imageFormat = ACSDImageFormatPDF;
    } else if (CFStringCompare(uttype, kACSDUTTypeSVG, 0) == kCFCompareEqualTo) {
        imageFormat = ACSDImageFormatSVG;
    } else if (CFStringCompare(uttype, kACSDUTTypeBMP, 0) == kCFCompareEqualTo) {
        imageFormat = ACSDImageFormatBMP;
    } else if (UTTypeConformsTo(uttype, kACSDUTTypeRAW)) {
        imageFormat = ACSDImageFormatRAW;
    } else {
        imageFormat = ACSDImageFormatUndefined;
    }
    return imageFormat;
}

@end
