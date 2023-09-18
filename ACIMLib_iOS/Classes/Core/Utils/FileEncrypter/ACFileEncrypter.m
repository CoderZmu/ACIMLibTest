//
//  ACFileEncrypter.m
//  ACIMLib
//
//  Created by 子木 on 2023/8/21.
//

#import "ACFileEncrypter.h"
#import "ACISAACFunction.h"

@implementation ACFileEncrypter


+ (NSData*)isaac_encrypt:(NSData*)data withKey:(NSString*)key {
    if (key == nil)  return nil;
    NSData *encryptedData;
    @synchronized (self) {
        char *keyCharArr = (char*)[key cStringUsingEncoding:NSASCIIStringEncoding];
        iSeed(keyCharArr, 1);
        char *content = (char*)[data bytes];
        char *result = Vernam(content,(uint32_t)data.length);
        encryptedData = [NSData dataWithBytes:result length:(uint32_t)data.length];
    }
    
    return encryptedData;
}

+ (NSData*)isaac_decrypt:(NSData*)data withKey:(NSString*)key {
    if (key == nil) return nil;
    NSData *clearData;
    @synchronized (self) {
        char *keyCharArr = (char*)[key cStringUsingEncoding:NSASCIIStringEncoding];
        iSeed(keyCharArr, 1);
        char *content =(char*) [data bytes];
        char *result = Vernam(content,(uint32_t)data.length);
        clearData = [NSData dataWithBytes:result length:(uint32_t)data.length];
    }
    return clearData;
}

@end
