//
//  ACSecretKey.m
//  Sugram
//
//  Created by gossip2 on 16/12/17.
//  Copyright © 2016年 gossip. All rights reserved.
//

#import "ACSecretKey.h"
#import "ACDialogMo.h"
#import "ACBase.h"
#import "ACAccountManager.h"
#import "ACDeviceInfo.h"
#import "ACHelper.h"
#import "ACFileManager.h"
#import "ACConnectionListenerProtocol.h"
#import "ACSafetyMutableDictionary.h"
#import "ACDatabase.h"
#import "ACDialogSecretKeyMo.h"
#import "ACLogger.h"
#import "ACConnectionListenerManager.h"
#import "ACDialogsAesKeyPacket.h"

#define SGAeskeyFileName @"writeQueue_HHJ"

@interface ACSecretKey ()<ACConnectionListenerProtocol>
@property(nonatomic,strong)NSString* key;
@property(nonatomic,strong)ACSafetyMutableDictionary* keyAndIVDic;
@property(nonatomic,strong)dispatch_queue_t syncQueue;
@end
@implementation ACSecretKey


-(dispatch_queue_t)syncQueue {
    if (!_syncQueue) {
        _syncQueue = dispatch_queue_create("com.sync.queue", DISPATCH_QUEUE_SERIAL);
    }
    return _syncQueue;
}


+ (ACSecretKey*)instance {
    static ACSecretKey* share;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        share = [[ACSecretKey alloc] init];
        share.key = [ACDeviceInfo getEncodeKey];
    });
    return share;
}

- (instancetype)init {
    self = [super init];
    [[ACConnectionListenerManager shared] addListener:self];
    return self;
}

- (void)userDataDidLoad {
    dispatch_async(self.syncQueue, ^{
        [self.keyAndIVDic removeAllObjects];
        [self moveToDbFromFile];
    });
}


// 迁移到数据库存储
- (void)moveToDbFromFile {
    
    NSString *aesFilePath = [ACFileManager getUserArchiverFilePath:SGAeskeyFileName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:aesFilePath]) {
        return;
    }
    
    NSMutableDictionary *encryptDic = [NSKeyedUnarchiver unarchiveObjectWithFile:aesFilePath];
    
    @ac_weakify(self);
    [encryptDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, ACPBAesKeyAndIV * _Nonnull obj, BOOL * _Nonnull stop) {
        ACDialogSecretKeyMo *secretObj = [ACDialogSecretKeyMo new];
        secretObj.aesKey = [obj.aesKey ac_aes128_decrypt:weak_self.key];
        secretObj.aesIv = [obj.aesIv ac_aes128_decrypt:weak_self.key];
        if (secretObj.aesKey.length && secretObj.aesIv.length) {
            [[ACDatabase DataBase] updateDialogSecretKeyForDialog:key secretKey:secretObj];
        }
    }];
    
    [[NSFileManager defaultManager] removeItemAtPath:aesFilePath error:nil];
    
}

-(NSString*)dbSecretKey {
    NSString* key = [[NSString stringWithFormat:@"%lld%@",[ACAccountManager shared].user.Property_SGUser_uin,self.key] ac_md5String];
    return key;
}

- (BOOL)hasLoadedSecretKeyForDialogID:(NSString *)dialogID {
    return [self getLocalDialogAesKeyWithDialogId:dialogID] != nil;
}

-(NSString*)getDialogSecretKeyByDialogID:(NSString *)dialogID {
    NSString* key = [[NSString stringWithFormat:@"%lld%@%@",[ACAccountManager shared].user.Property_SGUser_uin,self.key,dialogID] ac_md5String];
    return key;
}


-(ACDialogSecretKeyMo *)getDialogAesKeyWithDialogID:(NSString *)dialogID {
    __block ACDialogSecretKeyMo* aesKey = [self getLocalDialogAesKeyWithDialogId:dialogID];
    
    if(aesKey) {
        return aesKey;
    } else {
        dispatch_group_t synGroup = dispatch_group_create();
        dispatch_group_enter(synGroup);
        [self loadDialogAesKeysWithDidlogIDs:@[dialogID] withCompletion:^(NSDictionary *dic) {
            aesKey = dic.allValues.firstObject;
            dispatch_group_leave(synGroup);
        }];
        dispatch_group_wait(synGroup,dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8 * NSEC_PER_SEC)));
        return aesKey;
    }
}

- (ACDialogSecretKeyMo *)getLocalDialogAesKeyWithDialogId:(NSString *)dialogId {
    ACDialogSecretKeyMo *secretObj = self.keyAndIVDic[dialogId];
    if (secretObj && secretObj.aesKey.length && secretObj.aesIv.length) {
        return secretObj;
    }
    secretObj = [[ACDatabase DataBase] selectDialogSecretKeyDialog:dialogId];
    if (secretObj && secretObj.aesKey.length && secretObj.aesIv.length) {
        self.keyAndIVDic[dialogId] = secretObj;
        return secretObj;
    }
    return  nil;
    
}


/**
 强制更新某一组dialogId的key，必定会重写写数据库
 */
- (void)loadDialogAesKeysWithDidlogIDs:(NSArray *)dialogIDs withCompletion:(void (^)(NSDictionary *))completion  {
    ACLog(@"get dialog aes keys -> %@", [dialogIDs componentsJoinedByString:@","]);
    @ac_weakify(self);
    [[[ACDialogsAesKeyPacket alloc] initWithDialogIdArray:dialogIDs cert:[ACAccountManager shared].user.Property_SGUser_cert] sendWithSuccessBlockIdParameter:^(ACPBGetDialogKeyResp * _Nonnull response) {
        ACLog(@"get dialog aes keys success");
        NSMutableDictionary *callbackContent = [NSMutableDictionary dictionaryWithCapacity:response.entry.count];
        [response.entry enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, ACPBAesKeyAndIV * _Nonnull object, BOOL * _Nonnull stop) {
            ACDialogSecretKeyMo *secretObj = [ACDialogSecretKeyMo new];
            secretObj.aesKey = object.aesKey;
            secretObj.aesIv = object.aesIv;
            
            if (secretObj.aesKey.length && secretObj.aesIv.length){
                callbackContent[key] = secretObj;
                
                if(!weak_self.keyAndIVDic[key]){
                    weak_self.keyAndIVDic[key] = secretObj;
                    [[ACDatabase DataBase] updateDialogSecretKeyForDialog:key secretKey:secretObj];
                }
            }
        }];
        if (completion) {
            completion(callbackContent.copy);
        }
    } failure:^(NSError * _Nonnull error, NSInteger errorCode) {
        [ACLogger error:@"get dialog aes keys fail -> %ld", errorCode];
        if (completion){
            completion(nil);
        }
    }];
    
}




//一下这个block可能会多次回调（如果存在本地有的key和需要请求的key，则会先回调本地有的key，然后请求key并回调请求的key，如此会多次回调）
- (void)getDialogAesKeyWithDialogIDArr:(NSArray<NSString*>*)dialogIDArr withCompletion:(void(^)(NSDictionary*, BOOL remote))completion {
    NSMutableDictionary* aesKeyDic = [NSMutableDictionary dictionary];
    NSMutableArray* unAesKeyArr = [NSMutableArray array];
    
    for (id dialogNum in dialogIDArr) {
        NSString* dialogID;
        if([dialogNum isKindOfClass:[NSNumber class]]) {
            dialogID = ((NSNumber*)dialogNum).stringValue;
        } else if([dialogNum isKindOfClass:[NSString class]]) {
            dialogID = dialogNum;
        }

        if (dialogID.length) {
            ACDialogSecretKeyMo* aesKey = [self getLocalDialogAesKeyWithDialogId:dialogID];

            if (aesKey.aesKey.length&&aesKey.aesIv.length) {
                [aesKeyDic setValue:aesKey forKey:dialogID];
			} else {
                [unAesKeyArr addObject:dialogID];
            }
        }
    }
    
    if (completion) {
        completion(aesKeyDic, NO);
    }
   
    if (unAesKeyArr.count) {
        [self loadDialogAesKeysWithDidlogIDs:unAesKeyArr withCompletion:^(NSDictionary *dic) {
            !completion ?: completion(dic, true);
        }];
    }
}


- (ACSafetyMutableDictionary *)keyAndIVDic {
    if (!_keyAndIVDic) {
        _keyAndIVDic = [[ACSafetyMutableDictionary alloc] init];
    }
    return _keyAndIVDic;
}

@end
