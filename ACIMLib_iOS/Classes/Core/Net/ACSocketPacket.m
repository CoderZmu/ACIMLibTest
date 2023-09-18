//
//  ACRequest.m
//  ACIMLib
//
//  Created by 子木 on 2022/11/21.
//

#import "ACSocketPacket.h"
#import "ACSocketPacketCacheAgent.h"
#import "AcpbGlobalStructure.pbobjc.h"

static int const MAX_SEND_TIMES = 3;

@interface ACSocketPacket()
@property (nonatomic, copy) NSString *internalPackekId;
@end

@implementation ACSocketPacket

- (instancetype)init {
    self = [super init];
    
    return self;
}

- (int)packetSendTimes {
    return 1;
}

- (NSString *)packekId {
    return self.internalPackekId;
}

- (NSInteger)getBusinessCode:(id)responseModel; {
    return [[responseModel valueForKey:@"errorCode"] integerValue];
}

- (void)sendWithSuccessBlockEmptyParameter:(nullable ACSendPacketSuccessBlockEmptyParameter)successBlock failure: (nullable ACSendPacketFailureBlock)failureBlock {
    // 使用ACPBBaseResp解析数据
    [self sendWithSuccessBlockIdParameter:^(id  _Nonnull response) {
        !successBlock ?: successBlock();
    } failure:failureBlock modelClassType:ACPBBaseResp.class] ;
}

- (void)sendWithSuccessBlockIdParameter: (ACSendPacketSuccessBlockIdParameter)successBlock
                      failure: (ACSendPacketFailureBlock)failureBlock
               modelClassType: (Class)modelClassType {
    [self sendWithCompletionBlockWithSuccess:^(__kindof ACBaseSocketPacket * _Nonnull request) {
        id modelObj = [self serializeModel:request.responseData cls:modelClassType];
        NSInteger code = [self getBusinessCode:modelObj];
        if (code == 0) {
            !successBlock ?: successBlock(modelObj);
        } else {
            NSError *error = [NSError errorWithDomain:@"BissinessLogicErrorDomain" code:code userInfo:nil];
            !failureBlock ?: failureBlock(error, error.code);
        }
    } failure:^(__kindof ACBaseSocketPacket * _Nonnull request) {
        !failureBlock ?: failureBlock(request.error, request.error.code);
    }];
}

- (void)sendWithCompletionBlockWithSuccess:(ACSendPacketCompletionBlock)success failure:(ACSendPacketCompletionBlock)failure {
    if (self.openQoS) [self doCacheProcess];
    
    [super sendWithCompletionBlockWithSuccess:^(__kindof ACBaseSocketPacket * _Nonnull request){
        success(request);
        // 请求拿到数据则认为通信成功，忽略业务处理失败的情况，移除缓存
        if (self.openQoS) [self removeCache];
    } failure:^(__kindof ACBaseSocketPacket * _Nonnull request){
        failure(request);
    }];
}

- (id)serializeModel:(NSData *)data cls:(Class)aClass {
    SEL sel = @selector(parseFromData:error:);
    NSMethodSignature *sign = [aClass methodSignatureForSelector:sel];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sign];
    NSData *responseData = data;
    [invocation setArgument:&responseData atIndex:2];
    invocation.selector = sel;
    [invocation invokeWithTarget:aClass];
    id __unsafe_unretained modelObj = nil;
    [invocation getReturnValue:&modelObj];
    return modelObj;
}

- (void)doCacheProcess {
    int times = [self packetSendTimes];
    if (times <= 1) {
        [ACSocketPacketCacheAgent storeSendingPacket:[self packetUrl] data:[self packetBody] uuid:[self packekId]];
    } else if (times <= MAX_SEND_TIMES) {
        [ACSocketPacketCacheAgent increasePacketSendTimes:[self packekId]];
    } else {
        [ACSocketPacketCacheAgent drop:[self packekId]];
    }
}

- (void)removeCache {
    [ACSocketPacketCacheAgent drop:[self packekId]];
}

- (NSString *)internalPackekId {
    if (!_internalPackekId) {
        _internalPackekId = [[NSUUID UUID] UUIDString];
    }
    return _internalPackekId;
}

@end
