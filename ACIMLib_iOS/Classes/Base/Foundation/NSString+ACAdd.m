//
//  NSString+SPConversion.m
//  SPBase_Example
//
//  Created by 子木 on 2019/6/13.
//  Copyright © 2019 ZiMu-cd. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "NSData+ACCrypto.h"
#import <CommonCrypto/CommonCrypto.h>
#import "NSString+ACAdd.h"
#import "NSData+ACAdd.h"


@implementation NSString (SPConversion)

- (NSString *)ac_md5String {
    return [[self dataUsingEncoding:NSUTF8StringEncoding] ac_md5String];
}

- (NSString *)ac_base64EncodedString {
    return [[self dataUsingEncoding:NSUTF8StringEncoding] ac_base64EncodedString];
}

+ (NSString *)ac_stringWithBase64EncodedString:(NSString *)base64EncodedString {
    NSData *data = [NSData ac_dataWithBase64EncodedString:base64EncodedString];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (nullable NSString *)ac_stringWithUTF32Char:(UTF32Char)char32 {
    char32 = NSSwapHostIntToLittle(char32);
    return [[NSString alloc] initWithBytes:&char32 length:4 encoding:NSUTF32LittleEndianStringEncoding];
}

+ (NSString *)ac_jsonStringWithJsonObject:(id)jsonObject {
    NSError *err;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject options:NSJSONWritingPrettyPrinted error:&err];
    NSString * str = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    if (err) {

        return nil;
    }
    return str;
}

- (NSString *)ac_stringByURLEncode {
    if ([self respondsToSelector:@selector(stringByAddingPercentEncodingWithAllowedCharacters:)]) {
        /**
         AFNetworking/AFURLRequestSerialization.m
         
         Returns a percent-escaped string following RFC 3986 for a query string key or value.
         RFC 3986 states that the following characters are "reserved" characters.
         - General Delimiters: ":", "#", "[", "]", "@", "?", "/"
         - Sub-Delimiters: "!", "$", "&", "'", "(", ")", "*", "+", ",", ";", "="
         In RFC 3986 - Section 3.4, it states that the "?" and "/" characters should not be escaped to allow
         query strings to include a URL. Therefore, all "reserved" characters with the exception of "?" and "/"
         should be percent-escaped in the query string.
         - parameter string: The string to be percent-escaped.
         - returns: The percent-escaped string.
         */
        static NSString * const kAFCharactersGeneralDelimitersToEncode = @":#[]@"; // does not include "?" or "/" due to RFC 3986 - Section 3.4
        static NSString * const kAFCharactersSubDelimitersToEncode = @"!$&'()*+,;=";
        
        NSMutableCharacterSet * allowedCharacterSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
        [allowedCharacterSet removeCharactersInString:[kAFCharactersGeneralDelimitersToEncode stringByAppendingString:kAFCharactersSubDelimitersToEncode]];
        static NSUInteger const batchSize = 50;
        
        NSUInteger index = 0;
        NSMutableString *escaped = @"".mutableCopy;
        
        while (index < self.length) {
            NSUInteger length = MIN(self.length - index, batchSize);
            NSRange range = NSMakeRange(index, length);
            // To avoid breaking up character sequences such as 👴🏻👮🏽
            range = [self rangeOfComposedCharacterSequencesForRange:range];
            NSString *substring = [self substringWithRange:range];
            NSString *encoded = [substring stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
            [escaped appendString:encoded];
            
            index += range.length;
        }
        return escaped;
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        CFStringEncoding cfEncoding = CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding);
        NSString *encoded = (__bridge_transfer NSString *)
        CFURLCreateStringByAddingPercentEscapes(
                                                kCFAllocatorDefault,
                                                (__bridge CFStringRef)self,
                                                NULL,
                                                CFSTR("!#$&'()*+,/:;=?@[]"),
                                                cfEncoding);
        return encoded;
#pragma clang diagnostic pop
    }
}

- (NSString *)ac_stringByURLDecode {
    if ([self respondsToSelector:@selector(stringByRemovingPercentEncoding)]) {
        return [self stringByRemovingPercentEncoding];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        CFStringEncoding en = CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding);
        NSString *decoded = [self stringByReplacingOccurrencesOfString:@"+"
                                                            withString:@" "];
        decoded = (__bridge_transfer NSString *)
        CFURLCreateStringByReplacingPercentEscapesUsingEncoding(
                                                                NULL,
                                                                (__bridge CFStringRef)decoded,
                                                                CFSTR(""),
                                                                en);
        return decoded;
#pragma clang diagnostic pop
    }
}

- (id)ac_jsonValueDecoded {
    return [[self ac_dataValue] ac_jsonValueDecoded];
}

- (NSData *)ac_dataValue {
    return [self dataUsingEncoding:NSUTF8StringEncoding];
}



- (NSString*)ac_aes128_encrypt:(NSString *)key
{
    NSData* encryptedData = [[self dataUsingEncoding:NSUTF8StringEncoding] ac_aes128_encrypt:key];
    
    return [encryptedData ac_base64EncodedString];
}
- (NSString*)ac_aes128_decrypt:(NSString *)key
{
    NSData* encryptedData = [NSData ac_dataWithBase64EncodedString: self];
    NSData* decryptData = [encryptedData ac_aes128_decrypt:key];
    return [[NSString alloc] initWithData:decryptData encoding:NSUTF8StringEncoding];
}


-(NSData*)ac_aes128_encrypted_data:(NSString *)key withIV:(NSString*)iv
{
    int32_t error = 0;
    return [[self dataUsingEncoding:NSUTF8StringEncoding] dataEncryptedUsingAlgorithm:kCCAlgorithmAES128 key:key initializationVector:iv options:kCCOptionPKCS7Padding error:&error];

}


+ (NSString*)ac_aes128_decrypted_stringFromData:(NSData *)data withKey:(NSString *)key withIV:(NSString*)iv {
    NSData* resultData = [data decryptedDataUsingAlgorithm:kCCAlgorithmAES128 key:key initializationVector:iv options:kCCOptionPKCS7Padding error:nil];
    return [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
}


/**
 *  是否为空字符串
 *
 *  @return YES：是 NO：否
 */
- (BOOL)isBlankString{
    if (self == nil) {
        return YES;
    }
    if (![self isKindOfClass:[NSString class]]) {
        return YES;
    }
    if (self == NULL) {
        return YES;
    }
    if ([self isKindOfClass:[NSNull class]]) {
        return YES;
    }
    if ([[self trim] length] == 0) {
        return YES;
    }
    return NO;
}


+ (BOOL)ac_isValidString:(NSString *)str {
    if (![str isKindOfClass:NSString.class]) return NO;
    return [[str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] > 0;
}


- (NSString *)trim{
    NSString *result = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return result;
}

- (NSString *)ac_englishString {
    
    NSMutableString *str = [self mutableCopy];
    CFStringTransform(( CFMutableStringRef)str, NULL, kCFStringTransformMandarinLatin, NO);
    CFStringTransform((CFMutableStringRef)str, NULL, kCFStringTransformStripDiacritics, NO);
    return [str stringByReplacingOccurrencesOfString:@" " withString:@""];
}

- (NSString *)ac_letter {
    if ([self.ac_englishString isEqualToString:@""]) {
        
    }else if (self.length != 0) {

        char c = [self characterAtIndex:0];
        if (!isalpha(c)) {
            c = '#';
        }
        return [[NSString stringWithFormat:@"%c", c] uppercaseString];

    }
    return @" ";
}

-(NSData*)hexData
{
    NSInteger len = [self length] / 2; // Target length
    unsigned char *buf = malloc(len);
    unsigned char *whole_byte = buf;
    
    char byte_chars[3] = {'\0','\0','\0'};
    for ( int i=0; i < [self length] / 2; i++) {
        byte_chars[0] = [self characterAtIndex:i*2];
        byte_chars[1] = [self characterAtIndex:i*2+1];
        *whole_byte = strtol(byte_chars, NULL, 16);
        whole_byte++;
    }
    NSData *data = [NSData dataWithBytes:buf length:len];
    free( buf );
    return data;
}

- (NSString *)ac_firstCharUpper
{
    if (self.length == 0) return self;
    NSMutableString *string = [NSMutableString string];
    [string appendString:[NSString stringWithFormat:@"%c", [self characterAtIndex:0]].uppercaseString];
    if (self.length >= 2) [string appendString:[self substringFromIndex:1]];
    return string;
}


- (long)longValue {
    return (long)[self longLongValue];
}

@end
