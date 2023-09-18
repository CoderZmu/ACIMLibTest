//
//  ACFileDownloaderCache.m
//  ACIMLib
//
//  Created by 子木 on 2023/8/24.
//

#import "ACFileDownloadCache.h"
#import "ACFileManager.h"

@interface ACFileDownloadCache()
@property (nonatomic, strong, nonnull) dispatch_queue_t ioQueue;
@end

@implementation ACFileDownloadCache

+ (ACFileDownloadCache *)shared {
    static ACFileDownloadCache *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ACFileDownloadCache alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    _ioQueue = dispatch_queue_create("com.fileDownloadCache.ioQueue", DISPATCH_QUEUE_SERIAL);
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillTerminate:)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
    return self;
}

- (void)setResponseData:(NSData *)responseData forKey:(NSString *)key {
    dispatch_async(self.ioQueue, ^{
        if (!key.length || !responseData) {
            return;
        }
        NSString *filePath = [self filePathForKey:key];
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        [responseData writeToURL:fileURL options:0 error:nil];
        [fileURL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
    });
}

- (NSData *)resonseDataForKey:(NSString *)key {
    __block NSData *result;
    dispatch_sync(self.ioQueue, ^{
        NSString *filePath = [self filePathForKey:key];
        result = [NSData dataWithContentsOfFile:filePath];
    });
    return result;
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    dispatch_sync(self.ioQueue, ^{
        [self removeExpiredData];
    });
}

- (void)removeExpiredData {
    NSURL *folderURL = [NSURL fileURLWithPath:[self responseFolderPath] isDirectory:YES];

    NSURLResourceKey cacheContentDateKey = NSURLContentAccessDateKey;
    
    NSArray<NSString *> *resourceKeys = @[NSURLIsDirectoryKey, cacheContentDateKey, NSURLTotalFileAllocatedSizeKey];
    
    NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtURL:folderURL
                                                   includingPropertiesForKeys:resourceKeys
                                                                      options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                 errorHandler:NULL];
    
    NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:-3*24*60*60];
    
    NSMutableArray<NSURL *> *urlsToDelete = [[NSMutableArray alloc] init];
    for (NSURL *fileURL in fileEnumerator) {
        
        NSError *error;
        NSDictionary<NSString *, id> *resourceValues = [fileURL resourceValuesForKeys:resourceKeys error:&error];
        
        if (error || !resourceValues || [resourceValues[NSURLIsDirectoryKey] boolValue]) {
            continue;
        }

        NSDate *modifiedDate = resourceValues[cacheContentDateKey];
        if (expirationDate && [[modifiedDate laterDate:expirationDate] isEqualToDate:expirationDate]) {
            [urlsToDelete addObject:fileURL];
            continue;
        }
    }
    
    for (NSURL *fileURL in urlsToDelete) {
        [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
    }
}

- (NSString *)filePathForKey:(NSString *)key {
    if (!key.length) {
        return nil;
    }
    return [[self responseFolderPath] stringByAppendingPathComponent:key];
}


- (NSString *)responseFolderPath {
    NSArray<NSString *> *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *folderPath = [cachePaths[0] stringByAppendingPathComponent:@"ACDownloadTmp"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:folderPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return folderPath;
}


@end
