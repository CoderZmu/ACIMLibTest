//
//  NSData+SP.h
//  SPBase_Example
//
//  Created by 子木 on 2019/6/13.
//  Copyright © 2019 ZiMu-cd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (ACAdd)

// md5加密
- (NSString *)ac_md5String;

// 对应的hex字符串
- (NSString *)ac_hexString;

// 根据给定的16进制字符串创建data对象
+ (NSData *)ac_dataWithHexString:(NSString *)hexStr;

// base64编码二进制
- (NSString *)ac_base64EncodedString;

// 解码给定的base64编码字符串
+ (NSData *)ac_dataWithBase64EncodedString:(NSString *)base64EncodedString;

// 解码已得到NSArray或者NSDictionary对象
- (id)ac_jsonValueDecoded;

- (NSData*)ac_aes128_encrypt:(NSString *)key;
- (NSData*)ac_aes128_decrypt:(NSString *)key;

-(NSData *)ac_aes256_encrypt:(NSString *)key;
-(NSData *)ac_aes256_decrypt:(NSString *)key;

- (NSString *)ac_imageType;

@end

NS_ASSUME_NONNULL_END
