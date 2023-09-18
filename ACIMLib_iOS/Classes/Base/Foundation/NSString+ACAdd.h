//
//  NSString+SPConversion.h
//  SPBase_Example
//
//  Created by 子木 on 2019/6/13.
//  Copyright © 2019 ZiMu-cd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (ACAdd)

- (NSString *)ac_md5String;

- (NSString *)ac_base64EncodedString;

+ (NSString *)ac_stringWithBase64EncodedString:(NSString *)base64EncodedString;

+ (nullable NSString *)ac_stringWithUTF32Char:(UTF32Char)char32;

+ (NSString *)ac_jsonStringWithJsonObject:(id)jsonObject;

- (NSString *)ac_stringByURLEncode;

- (NSString *)ac_stringByURLDecode;

- (id)ac_jsonValueDecoded;

- (NSData *)ac_dataValue;

- (NSString*)ac_aes128_encrypt:(NSString *)key;
- (NSString*)ac_aes128_decrypt:(NSString *)key;


- (NSData*)ac_aes128_encrypted_data:(NSString *)key withIV:(NSString*)iv;
+ (NSString*)ac_aes128_decrypted_stringFromData:(NSData *)data withKey:(NSString *)key withIV:(NSString*)iv;

- (NSString *)ac_englishString;
- (NSString *)ac_letter;

+ (BOOL)ac_isValidString:(NSString *)str;

- (NSString *)ac_firstCharUpper;
@end

NS_ASSUME_NONNULL_END
