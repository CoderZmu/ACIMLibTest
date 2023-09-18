//
//  ACFileDownloader.m
//  ACIMLib
//
//  Created by 子木 on 2023/8/22.
//

#import "ACFileDownloader.h"
#import "ACOssManager.h"
#import "ACFileEncrypter.h"
#import "ACFileDownloadCache.h"
#import "ACBase.h"

@interface ACFileDownloadChangeInf : NSObject
@property (nonatomic,strong) NSString *key;
@property (nonatomic,strong) NSProgress *progress;
@property (nonatomic,assign) BOOL finished;
@property (nonatomic,strong) NSError *error;
+ (instancetype)createPercentChangeInf:(NSString *)key progress:(NSProgress *)progress;
+ (instancetype)createCompletedChangeInf:(NSString *)key error:(NSError *)error;
@end

@implementation ACFileDownloadChangeInf

+ (instancetype)createPercentChangeInf:(NSString *)key progress:(NSProgress *)progress {
    ACFileDownloadChangeInf *changeInf = [[ACFileDownloadChangeInf alloc] init];
    changeInf.key = key;
    changeInf.progress = progress;
    changeInf.finished = NO;
    changeInf.error = nil;
    return changeInf;
}

+ (instancetype)createCompletedChangeInf:(NSString *)key error:(NSError *)error {
    ACFileDownloadChangeInf *changeInf = [[ACFileDownloadChangeInf alloc] init];
    changeInf.key = key;
    changeInf.finished = YES;
    changeInf.error = error;
    return changeInf;
}

@end

@interface ACFileDownloadChangeCallback : NSObject

@property (nonatomic,copy) ACFileDownloaderProgressBlock progressBlock;
@property (nonatomic,copy) ACFileDownloaderCompletedBlock completedBlock;
@end
@implementation ACFileDownloadChangeCallback
@end


@interface ACFileDownloader()

@property (nonatomic, strong) NSMutableDictionary<NSString *, ACFileDownloadChangeInf *> *downloadChangePresent;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id<ACOssCancellableTask>> *downloadTaskPresent;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableSet<ACFileDownloadChangeCallback *> *> *downloadChangeCallbacks;
@property (nonatomic, strong) dispatch_queue_t serialQueue;

@end

@implementation ACFileDownloader

+ (ACFileDownloader *)shared {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    self.downloadChangePresent = [NSMutableDictionary new];
    self.downloadTaskPresent = [NSMutableDictionary new];
    self.downloadChangeCallbacks = [NSMutableDictionary new];
    self.serialQueue = dispatch_queue_create("com.fileDownload.serialQueue", NULL);
    return self;
}

- (void)downloadFileWithOssKey:(NSString *)key
              fileEncryptKey:(NSString *)fileEncryptKey
                 destination:(NSURL *)destination
                   ignoreCache:(BOOL)ignoreCache
                    progress:(ACFileDownloaderProgressBlock)progressBlock
                     completed:(ACFileDownloaderCompletedBlock)completedBlock {
    dispatch_sync(self.serialQueue, ^{
        NSString *cachedKey = [[key stringByAppendingFormat:@"___%@", fileEncryptKey ?: @""] ac_md5String];
        if (!ignoreCache) {
            NSData *cachedData = [[ACFileDownloadCache shared] resonseDataForKey:cachedKey];
            if (cachedData) {
                NSError *error;
                [cachedData writeToURL:destination options:NSDataWritingAtomic error:&error];
                if (error == nil) {
                    completedBlock(nil);
                    return;
                }
            }
        }
        
        if (!self.downloadTaskPresent[key]) {
            id<ACOssCancellableTask> task = [[ACOssManager shareInstance] downloadFile:key progress:^(NSProgress * _Nonnull progress) {
                [self updateLatestChange:[ACFileDownloadChangeInf createPercentChangeInf:key progress:progress]];
            } completed:^(NSData * _Nullable data, NSError * _Nullable downloadError) {
                NSError *error = downloadError;
                if (data) {
                    if (fileEncryptKey) {
                        data = [ACFileEncrypter isaac_decrypt:data withKey:fileEncryptKey];
                    }
                    [data writeToURL:destination options:NSDataWritingAtomic error:&error];
                    if (!ignoreCache) {
                        [[ACFileDownloadCache shared] setResponseData:data forKey:cachedKey];
                    }
                }
                
                [self updateLatestChange:[ACFileDownloadChangeInf createCompletedChangeInf:key error:error]];
            }];
            
            self.downloadTaskPresent[key] = task;
        }
        
        [self watch:key progress:progressBlock completed:completedBlock];
    });
    
}


- (void)updateLatestChange:(ACFileDownloadChangeInf *)changeInf {
    ac_dispatch_sync_on_main_queue(^{
        NSSet<ACFileDownloadChangeCallback *> *callbackSet = [self.downloadChangeCallbacks[changeInf.key] copy];
        for (ACFileDownloadChangeCallback *callback in callbackSet) {
            if (changeInf.finished) {
                callback.completedBlock(changeInf.error);
            } else {
                !callback.progressBlock ?: callback.progressBlock(changeInf.progress);
            }
        }
        
    });
    dispatch_sync(self.serialQueue, ^{
        if (changeInf.finished) {
            [self.downloadChangePresent removeObjectForKey:changeInf.key];
            [self.downloadTaskPresent removeObjectForKey:changeInf.key];
            [self.downloadChangeCallbacks removeObjectForKey:changeInf.key];
        } else {
            self.downloadChangePresent[changeInf.key] = changeInf;
        }
    });
}

- (void)watch:(NSString *)key progress:(ACFileDownloaderProgressBlock)progressBlock
    completed:(ACFileDownloaderCompletedBlock)completedBlock {
    ACFileDownloadChangeInf *latestChangeInf = self.downloadChangePresent[key];
    if (latestChangeInf) {
        ac_dispatch_sync_on_main_queue(^{
            if (latestChangeInf.finished) {
                completedBlock(latestChangeInf.error);
            } else {
                !progressBlock ?: progressBlock(latestChangeInf.progress);
            }
        });
    }
    
    if (!latestChangeInf.finished) {
        ACFileDownloadChangeCallback *callback = [ACFileDownloadChangeCallback new];
        callback.progressBlock = progressBlock;
        callback.completedBlock = completedBlock;
        NSMutableSet<ACFileDownloadChangeCallback *> *callbackSet = self.downloadChangeCallbacks[key];
        if (!callbackSet) {
            callbackSet = [NSMutableSet new];
            self.downloadChangeCallbacks[key] = callbackSet;
        }
        [callbackSet addObject:callback];
    }
}

- (BOOL)isDownloading:(NSString *)key {
    return self.downloadTaskPresent[key] != nil;
}

- (void)cancelDownloading:(NSString *)key {
    dispatch_sync(_serialQueue, ^{
        id <ACOssCancellableTask> task = self.downloadTaskPresent[key];
        if (task) {
            [task ac_cancel];
        }
    });
}

@end
