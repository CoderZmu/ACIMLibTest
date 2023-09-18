//
//  ACOssManager.m
//  Sugram
//
//  Created by 子木 on 2023/1/5.
//  Copyright © 2023 Sugram. All rights reserved.
//

#import "ACOssManager.h"
#import "ACOssConfig.h"
#import "ACConnectionListenerManager.h"
#import "ACGetSysConfigPacket.h"
#import "ACAliYunOss.h"
#import "ACBase.h"

static NSString * const ACOssManagerErrorDomain = @"ac.aliyun.oss.error";
static BOOL HaveRequestedOssConfig = NO;

@interface ACOssFakeTask: NSObject<ACOssCancellableTask>
@end
@implementation ACOssFakeTask
- (void)ac_cancel {
}
@end


@interface ACOssManager()<ACConnectionListenerProtocol>

@property (nonatomic,strong) ACOssConfig *config;

@property (nonatomic,strong) id<ACOssBehavior> ossService;

@end

@implementation ACOssManager

#pragma mark - 单例

+ (ACOssManager *)shareInstance {
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

#pragma mark - 生命周期

- (instancetype)init {
    self = [super init];
    _config = [self loadOssConfigFromDisk];
    [self configureOss];
    [[ACConnectionListenerManager shared] addListener:self];
    
    return self;
}

#pragma mark - 公共方法

- (id<ACOssCancellableTask>)uploadFile:(NSString *)key
                              fileData:(nonnull NSData *)fileData progress:(nullable ACOssUploadProgressBlock)progressBlock completed:(nullable ACOssUploadCompletedBlock)completedBlock {
    
    
    
    void(^tmpCompletedBlock)(NSError *error) = ^(NSError *error){
        ac_dispatch_sync_on_main_queue(^{
            !completedBlock ?: completedBlock(error);
        });
    };
    
    id <ACOssBehavior> service = self.ossService;
    if (!service) {
        tmpCompletedBlock([NSError errorWithDomain:ACOssManagerErrorDomain code:ACOssErrorCODE_InitializeServiceFailed userInfo:nil]);
        return nil;
    }
    
    
    return [service uploadFile:key fileData:fileData progress:progressBlock ? ^(NSProgress *p){
        ac_dispatch_sync_on_main_queue(^{
            progressBlock(p);
        });
    } : nil completed:tmpCompletedBlock];
}

- (void)uploadMultipleFiles:(NSArray<NSString *> *)keys
                  fileDatas:(NSArray<NSData *> *)fileDatas
                  completed:(nullable ACOssUploadCompletedBlock)completedBlock {
    
    NSAssert(keys.count == fileDatas.count, @"Invalid params");
    
    if (!keys.count) {
        completedBlock(nil);
        return;
    }
    
    NSMutableArray *keyMArr = [NSMutableArray arrayWithArray:keys];
    NSMutableArray *fileDataMArr = [NSMutableArray arrayWithArray:fileDatas];
    
    [self uploadFile:keyMArr.firstObject fileData:fileDataMArr.firstObject progress:nil completed:^(NSError * _Nullable error) {
        if (error) {
            completedBlock(error);
            return;
        }
        
        [keyMArr removeObjectAtIndex:0];
        [fileDataMArr removeObjectAtIndex:0];
        
        [self uploadMultipleFiles:keyMArr fileDatas:fileDataMArr completed:completedBlock];
    }];
    
}

- (id<ACOssCancellableTask>)downloadFile:(NSString *)key
                                progress:(nullable ACOssDownloadProgressBlock)progressBlock
                               completed:(nullable ACOssDownloadCompletedBlock)completedBlock {
    
    
    ACOssDownloadCompletedBlock tmpCompletedBlock = ^(NSData * _Nullable data, NSError * _Nullable error){
        ac_dispatch_sync_on_main_queue(^{
            !completedBlock ?: completedBlock(data, error);
        });
    };
    
    
    id <ACOssBehavior> service = self.ossService;
    
    if (!service) {
        tmpCompletedBlock(nil, [NSError errorWithDomain:ACOssManagerErrorDomain code:ACOssErrorCODE_InitializeServiceFailed userInfo:nil]);
        return nil;
    }
    
    return [service downloadFile:key progress:progressBlock ? ^(NSProgress *p){
        ac_dispatch_sync_on_main_queue(^{
            progressBlock(p);
        });
    } : nil completed:^(NSData * _Nullable data, NSError * _Nullable error) {
        
        tmpCompletedBlock(data, error);
    }];
}


- (void)copyObjects:(NSArray<ACOssCopyObjectMeta *> *)objectMetaArray
          completed:(nullable ACOssCopyObjectsCompletedBlock)completedBlock {
    
    if (!objectMetaArray.count) {
        !completedBlock ?: completedBlock(YES);
        return;
    }
    
    id <ACOssBehavior> service = self.ossService;
    if (!service) {
        !completedBlock ?: completedBlock(NO);
        return;
    }
    
    
    [service copyObjects:objectMetaArray completed:^(BOOL result) {
        !completedBlock ?: completedBlock(result);
    }];
    
    
}

- (void)doesObjectExist:(NSString *)key completed:(ACOssQueryObjectCompletedBlock)completedBlock {
    
    id <ACOssBehavior> service = self.ossService;
    if (!service) {
        ac_dispatch_sync_on_main_queue(^{
            !completedBlock ?: completedBlock(NO);
        });
        return;
    }
    
    [service doesObjectExist:key completed:^(BOOL isExisted) {
        ac_dispatch_sync_on_main_queue(^{
            !completedBlock ?: completedBlock(isExisted);
        });
    }];
}


- (NSString *)generateObjectKeyWithExt:(nullable NSString *)ext {
    NSString *uniqueId = [NSString stringWithFormat:@"%f_%@", [[NSDate date] timeIntervalSince1970] * 1000, [[NSUUID UUID] UUIDString]];
    NSString *name = ext.length ? [uniqueId stringByAppendingPathExtension:ext] : uniqueId;
    return name;
}


#pragma mark - 私有方法

- (void)requestOssConfigFromServer {
    ACGetSysConfigPacket *packet = [[ACGetSysConfigPacket alloc] init];
    [packet sendWithSuccessBlockIdParameter:^(ACPBGetSysConfigResp * _Nonnull response) {
        __block NSDictionary *val;
        [response.configArray enumerateObjectsUsingBlock:^(ACPBSysConfigItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.key isEqualToString:@"alioss"]) {
                val = [obj.value ac_jsonValueDecoded];
                *stop = true;
            }
        }];
        if (!val.count) return;
        self.config = [ACOssConfig createOssConfigWithServerConfDict:val];
        [self saveOssConfigToDisk:self.config];
        [self configureOss];
        HaveRequestedOssConfig = YES;
    } failure:^(NSError * _Nonnull error, NSInteger errorCode) {
    }];
}

- (void)configureOss {
    if (!self.config) return;
    if (!self.ossService) {
//        self.ossService = [[ACAliYunOss alloc] init];
    }
    [self.ossService configurate:self.config];
}



#pragma mark - ACConnectionListenerProtocol

- (void)onConnected {
    if (!HaveRequestedOssConfig)
        [self requestOssConfigFromServer];
}


#pragma mark - 归档

- (ACOssConfig *)loadOssConfigFromDisk {
    NSData *data = [NSData dataWithContentsOfFile:[self makeArchivePath]];
    if (!data) return nil;
    NSError *error;
    
    ACOssConfig *conf = [NSKeyedUnarchiver
                         unarchivedObjectOfClass:ACOssConfig.class fromData:data error:&error];
    return conf;
}


- (void)saveOssConfigToDisk:(ACOssConfig *)conf {
    NSError *error;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:conf requiringSecureCoding:YES error:&error];
    if (data) {
        [data writeToFile:[self makeArchivePath] atomically:YES];
    }
}

- (NSString *)makeArchivePath {
    NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *folderPath = [paths[0] stringByAppendingPathComponent:@"ACOss"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:folderPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return [folderPath stringByAppendingPathComponent:@"Config.achive"];
}

@end
