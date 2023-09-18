//
//  ACGetSuperGroupOfflineMessagesPacket.m
//  ACIMLib
//
//  Created by 子木 on 2022/11/23.
//

#import "ACGetSuperGroupOfflineMessagesPacket.h"
#import "ACUrlConstants.h"

@interface ACGetSuperGroupOfflineMessagesPacket()

@property (nonatomic, strong) NSData *data;

@end

@implementation ACGetSuperGroupOfflineMessagesPacket

- (instancetype)initWithOffset:(long)offset dialogMessageOffsets:(NSDictionary *)dialogMessageOffsets readOffsets:(NSDictionary *)readOffsets {
    self = [super init];
    ACPBGetSuperGroupNewMessageReq *req = [[ACPBGetSuperGroupNewMessageReq alloc] init];
    req.offset = offset;
    req.dialogKeys = [[ACGPBStringInt64Dictionary alloc] initWithCapacity:dialogMessageOffsets.count];
    [dialogMessageOffsets enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [req.dialogKeys setInt64:[obj longValue] forKey:key];
    }];
    _data = [req data];
    return self;
}

- (int32_t)packetUrl {
    return AC_API_NAME_GetSuperGroupNewMessage;
}

- (NSData *)packetBody {
    return self.data;
}


- (void)sendWithSuccessBlockIdParameter:(nullable void(^)(ACPBGetSuperGroupNewMessageResp * response))successBlock failure:(nullable ACSendPacketFailureBlock)failureBlock {
    [super sendWithSuccessBlockIdParameter:successBlock failure:failureBlock modelClassType:ACPBGetSuperGroupNewMessageResp.class];
}

@end
