//
//  ACHandShakeManager.m
//  ACConnection
//
//  Created by 子木 on 2022/6/10.
//

#import <CommonCrypto/CommonDigest.h>
#import "ACHandshake.h"
#import "ACGMEllipticCurveCrypto.h"
#import "ACRsa.h"
#import "AcpbBase.pbobjc.h"
#import "ACSocketServer.h"
#import "ACLogger.h"
#import "NSData+ACCrypto.h"
#import "ACSocketHeader.h"

static NSArray * PublicRSAKeys;

@interface ACHandshake()
@property (nonatomic, strong) NSString *privateEccKey;
@property (nonatomic, assign) int publicKeyIndex;

@property (nonatomic, strong) NSString *serverPublicEccKey;
@property (nonatomic, strong) NSString *serverNonce;

@property (nonatomic, strong) NSString *serverAESKey;
@property (nonatomic, strong) NSString *serverAESIv;

@property (nonatomic, copy) ACHandshakeCompletionBlock completionBlock;

@property (nonatomic, strong)   dispatch_queue_t operationQueue;
@end


@implementation ACHandshake

+ (void)initialize {
    PublicRSAKeys = @[@"MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAgJZhxBi0tsK4lIwTMqaYFw4SABdK6Tt1FDNDz4i2vQimJMXItCQx6sbxn/vjbZ/WX9HEXGx/CUpLfhAaYf25DRQPHgHjTDtbYLLxB6Ut8FEmxJg2JGQFQjk4jgGVuMc9P1vOCq48/z7sYw90soFf6z33MjmeMN4g1ZnSj4LoeAYMpx0PJmjNVFTGS0V3j1nuBXT8W4mHwzexeWZ+4MoKXVogT0tqR2ad3F7YZ+QJYVDAtoMoRXVbXShnRm3X0wysvvc6dpo1T1QQNkvG2kyZkp+POjcNSqhYmIvJPOxNhlgF/OU/xz10LxcCJocc8H4c+/yyLMTBPMgzUAAIBQH/CQIDAQAB",
                      @"MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAgpvhrbX3S8Lnqol36/av1QcWoUNdBcs7lujwhg2UnKKF9r19dXt/Qnfcyy09jrA1l9avMhsUjUxOuhAvw961Swz8UYR0EY4Sn0vfNO5veAU2mG4H5uMcwQh32IFJcraU+6+MgtNZzlpQd3etgOxnKFa3tea/Pf2ztYclzCureniaPW4i+qF/WMyBLahHvDK+aCAcgsPpOG5963O35+7iMvfQl6Ln3PPypckZwbWgsPlq7eNKDz9gzkOSnPaqKta0Z9XSNCE1zFxFotD+xRqzPs6kR/5+ScuWRGNKUbpp430pbPLl9CUI8V0EbCPsH2OiS/KxRZPlIhvpbY9jpLTHSQIDAQAB",
                      @"MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvM4N/EU5YSgvZY80PLtH3aAI8b0DCWL93ckxRvSnwyd6oMh8gm8ODQPW39/mDsDuFW+nTl6yf61P3/5uz4lsS3DtoZt+ZK9IBweRVfBbA83nWcRca5+BQK7m5ocBeNeyTfyVqtLXnn7NGFpTEpUAxH4EVT8d2VNzwZPlFFdsR7/rj5YVG3MN92rpMehNix7JiekasGyB4Ln9sbirTo5lxodDz4X7/9/TtjxxqPVtb8H3luzxqIFSsyfaQNZyzSybGGQksNKVDh1vg3xGL3K9UuxFM3HKtN0vDKJVSLtD3bLoTAr6S/zJM7IqnBwLOoC+Ooz6oyL2yGWskUaqPqpmVQIDAQAB",
                      @"MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAhmDq4cw5p2SQe9OIYze5depcG9xiljVHL3V06tUJPmSGI6Ti7Odmmd5j3g54pGP00tKoY54d9zfwvioG6+0GSwNBvaNry7oqJ84Q5YLcDgyZCKvDRh8rqnWNuyUpmMIUodBU67P2h5ETt7h89IrPJvnhFTuJwxDX9/FJO4Xs4lkKplT+SGHqPtaTtHZ2huja6X1NQtjktVf2w176M+ZPAD1GTZHB3E1UhukjeU/jhyjQ3zRAJW0nRs4EHbHnMXfHnYE7dEe2v0/bRgqX+hscDPF/3QMCHqToFEFd+frs1AUvgueUcn1SWm5N9YZ/RhxjbOdl2aicvZf0M1UTy7uIlwIDAQAB",
                      @"MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAgsWn0zUb4gwcTjFjwFRu8C2He/inslXSvNzNf6YcWstCr/9UbORdPl5UPlh1qVgwXLCTckQYrBeZIXy163okJZI+mZOAzkHSKBMIlGIqDEf52F6FO0ykscw/+t16A8Kw0XULyZvOu6GndnrAbPbW10CSJKiybZn7MEYlLTAEEDM8von8IuUzQUAxh7G9xR8//QmUzMWe3qy80Zn+a9aC679dMSzlRHyiylscHMHmHoLQhLKmhUheP8X1buc5pI38S2gUrQ/uk83ejrJ43zsmRqRCCeVr9qv4K9CvdyhhEwXVa+CN2meHHrj5Va3Al9bc6jhb0REQUj4gzmS/pN0MBQIDAQAB",];

}

- (void)start:(ACHandshakeCompletionBlock)completion operationQueue:(dispatch_queue_t)oq {

    self.completionBlock = completion;
    self.operationQueue = oq;
    [ACLogger info:@"start handshake"];
    // 生成ecc密钥对
    ACGMEllipticCurveCrypto *crypto = [ACGMEllipticCurveCrypto generateKeyPairForCurve:ACGMEllipticCurveSecp256r1];
    
    NSString *publicEccKey = crypto.publicKeyBase64;
    _privateEccKey = crypto.privateKeyBase64;
    
    // 选取rsa公钥
    _publicKeyIndex = arc4random() % [PublicRSAKeys count];
    NSTimeInterval milisecondedDate = [[NSDate date] timeIntervalSince1970] * 1000;
    long timestamp = [@(milisecondedDate) longValue];
    
    NSString *alphabet = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXZY0123456789";
    NSMutableString *s = [NSMutableString stringWithCapacity:10];
    for (NSUInteger i = 0U; i < 10; i++) {
        u_int32_t r = arc4random() % [alphabet length];
        unichar c = [alphabet characterAtIndex:r];
        [s appendFormat:@"%C", c];
    }
    
    NSString *nonce = [s copy];
    NSMutableString *ms = [[NSMutableString alloc] init];
    [ms appendString:publicEccKey];
    [ms appendString: [NSString stringWithFormat:@"%ld", timestamp]];
    [ms appendString: [NSString stringWithFormat:@"%d", _publicKeyIndex]];
    [ms appendString: nonce];
    
    // 计算 sha256(param)
    NSData *data = [ms dataUsingEncoding:NSUTF8StringEncoding];
    NSData *hash = ACSha256(data);
    NSString *hashString = [self hexStringFromData:hash];
    
    // 计算 rsa(nonce+param ,key)
    NSString *pubKey = PublicRSAKeys[_publicKeyIndex];
    NSString *clearMessage = [NSString stringWithFormat:@"%@%@%@", nonce, @"|", hashString];
    NSString *sign = [ACRsa encryptString:clearMessage publicKey:pubKey];
    
    ACPBHandshakeReq *hands = [[ACPBHandshakeReq alloc]init];
    hands.pubKey = publicEccKey;
    hands.timestamp = timestamp;
    hands.pubkeyIndex = _publicKeyIndex;
    hands.sign = sign;
    
    __weak __typeof__(self) weakSelf = self;
    [[ACSocketServer shareSocketServer] sendRequest:ACCommand_HandShake data:[hands data] timeout:6 success:^(NSData * _Nonnull response) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        dispatch_async(self.operationQueue, ^{
            [weakSelf handShakeCallBack:response];
        });
    } failure:^(NSError * _Nonnull error, NSInteger code) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        ACHandshakeCompletionBlock block = [self.completionBlock copy];
        dispatch_async(self.operationQueue, ^{
            [ACLogger error:@"first handshake timeout"];
            block(NO, nil, nil);
        });
    }];
    
}

- (void)handShakeCallBack:(NSData *)data {
    ACPBHandshakeResp *shakeResp = [ACPBHandshakeResp parseFromData:data error:nil];
    if (shakeResp.errorCode) {
        [ACLogger error:@"first handshake fail -> code: %d, m: %@", shakeResp.errorCode, shakeResp.errorMessage];

        self.completionBlock(NO, nil, nil);
        return;
    }
    // 读取body
    _serverPublicEccKey = shakeResp.pubKey;
    _serverNonce = shakeResp.nonce;

    // 计算出私钥(ECDHE)
    ACGMEllipticCurveCrypto *client = [ACGMEllipticCurveCrypto cryptoForCurve:
                                     ACGMEllipticCurveSecp256r1];
    client.privateKeyBase64 = _privateEccKey;
    NSData *tmpKey = [client sharedSecretForPublicKeyBase64:_serverPublicEccKey];
    NSString *key = [self hexStringFromData:tmpKey];
    
    _serverAESKey = [key substringToIndex:16];
    _serverAESIv = [key substringFromIndex:[key length] - 16];
    [self comfirmHandShake];
}

- (void)comfirmHandShake {
    
    [ACLogger info:@"comfirm handshake start"];
    
    NSTimeInterval milisecondedDate = [[NSDate date] timeIntervalSince1970] * 1000;
    long long timestamp = [[NSNumber numberWithDouble: milisecondedDate] longLongValue];
    NSString *clearMessage = [NSString stringWithFormat:@"%@%@", _serverPublicEccKey, _serverNonce];
    NSData *sha256 = ACSha256([clearMessage dataUsingEncoding:NSUTF8StringEncoding]);
    NSString *sha256Str = [self hexStringFromData:sha256];
    
    NSData *signData = [[sha256Str dataUsingEncoding:NSUTF8StringEncoding] dataEncryptedUsingAlgorithm:kCCAlgorithmAES128 key:_serverAESKey initializationVector:_serverAESIv options:kCCOptionPKCS7Padding error:nil];
    
    NSString *sign = [signData base64EncodedStringWithOptions:0];
    ACPBConfirmHandshakeReq *confirmReq = [[ACPBConfirmHandshakeReq alloc]init];
    confirmReq.timestamp = timestamp;
    confirmReq.sign = sign;
    
    __weak __typeof__(self) weakSelf = self;
    [[ACSocketServer shareSocketServer] sendRequest:ACCommand_Comfirm_HandShake data:[confirmReq data] timeout:6 success:^(NSData * _Nonnull response) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        dispatch_async(self.operationQueue, ^{
            [weakSelf handShakeConfirmCallBack:response];
        });
    } failure:^(NSError * _Nonnull error, NSInteger code) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        ACHandshakeCompletionBlock block = [self.completionBlock copy];
        dispatch_async(self.operationQueue, ^{
            
            [ACLogger error:@"comfirm handshake timeout"];
            block(NO, nil, nil);
        });
    }];
    
}

- (void)handShakeConfirmCallBack:(NSData *)data {

    ACPBConfirmHandshakeResp *confirmShakeResp = [ACPBConfirmHandshakeResp parseFromData:data error:nil];
    if (confirmShakeResp.errorCode) {
        [ACLogger error:@"comfirm handshake fail -> code: %d, m: %@", confirmShakeResp.errorCode, confirmShakeResp.errorMessage];
        self.completionBlock(NO, nil, nil);
        return;
    }
    
    
    [ACLogger info:@"handshake success"];
    
    ACHandshakeCompletionBlock block = [self.completionBlock copy];
    block(YES, _serverAESKey, _serverAESIv);
}


- (NSString *)hexStringFromData:(NSData *)data{
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:data.length * 2];
    for (NSUInteger i = 0; i < data.length; i++)
    {
        [string appendFormat:@"%02x", ((uint8_t *)data.bytes)[i]];
    }
    return string;
}



NSData *ACSha256(NSData *data)
{
    uint8_t digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (CC_LONG)data.length, digest);
    return [[NSData alloc] initWithBytes:digest length:CC_SHA256_DIGEST_LENGTH];
}

@end
