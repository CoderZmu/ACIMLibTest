//
//  SGFileManager.m
//  Sugram
//
//  Created by Humberto on 2020/7/2.
//  Copyright © 2020 gossip. All rights reserved.
//

#import "ACFileManager.h"
#import "ACBase.h"
#import "ACAccountManager.h"

@interface ACFileManager ()

@property(nonatomic,strong)NSFileManager* fileManager;

@end

@implementation ACFileManager

#pragma mark - 沙盒目录相关
+ (NSString *)documentsDir {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
}

+ (NSString *)libraryDir {
    return [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];;
}

+ (NSString *)preferencesDir {
    NSString *libraryDir = [self libraryDir];
    return [libraryDir stringByAppendingPathComponent:@"Preferences"];
}

+ (NSString *)cachesDir {
    return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
}

+ (NSString *)tmpDir {
    return NSTemporaryDirectory();
}

+ (NSString *)IMLibRootDir {
    NSString *path = [[self documentsDir] stringByAppendingPathComponent:@"ACIMLib"];
    NSURL *url = [NSURL fileURLWithPath:path];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:true attributes:nil error:nil];
        [url setTemporaryResourceValue:@1 forKey:NSURLIsExcludedFromBackupKey];
    }
    return path;
}

+ (NSString *)publicPath {
    NSString *publicDir = [[self IMLibRootDir] stringByAppendingPathComponent:@"Public"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:publicDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:publicDir withIntermediateDirectories:true attributes:nil error:nil];
    }
    return publicDir;
}

+ (NSString *)logsPath {
    NSString *publicDir = [[self IMLibRootDir] stringByAppendingPathComponent:@"Logs"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:publicDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:publicDir withIntermediateDirectories:true attributes:nil error:nil];
    }
    return publicDir;
}

+ (NSString *)currentUserRootDir {
    return [self userRootDirForUid:[ACAccountManager shared].user.Property_SGUser_uin];
}

+ (NSString *)userRootDirForUid:(long)uid {
    if (!uid) return nil;
    
    NSString *uidMD5 = [[NSString stringWithFormat:@"%ld",uid] uppercaseString] ;
    NSString *userDir = [[self IMLibRootDir] stringByAppendingPathComponent:uidMD5];
    if (![[NSFileManager defaultManager] fileExistsAtPath:userDir]) {
        NSError* error;
        [[NSFileManager defaultManager] createDirectoryAtPath:userDir withIntermediateDirectories:true attributes:nil error:&error];
        if (error) {
            return nil;
        }
    }
    return userDir;
}


+ (NSString *)dbPathForUid:(long)uid {
    NSString *userDir = [self userRootDirForUid:uid];
    if (!userDir) return nil;
    
  
    return [userDir stringByAppendingPathComponent:@"Cache.db"];;
}

+ (NSString *)msgMediaDirForTarget:(NSString *)target {
    NSString* root = [self currentUserRootDir];
    NSString *targetDir = [target ac_md5String];
    
    NSString* directory =  [root stringByAppendingPathComponent:targetDir];
    if (![[NSFileManager defaultManager] fileExistsAtPath:directory]) {
        NSError* error;
        [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:true attributes:nil error:&error];
        if (error) {
            return nil;
        }
    }

    return directory;
}

+ (NSString*)getMsgMediaFilePathForKey:(long)key target:(NSString *)target withType:(ACMediaItemType)type {
    return [self getMsgMediaFilePathForKey:key target:target withType:type extension:nil];
}

+ (NSString*)getMsgMediaFilePathForKey:(long)key target:(NSString *)target withType:(ACMediaItemType)type extension:(NSString *)extension  {
    
    NSString* fileTypDirctory;
    if (type==ACMediaPhoto){
        fileTypDirctory = @"ACImageCache";
    }
    else if (type==ACMediaAudio){
        fileTypDirctory = @"ACAudioCache";
        if (!extension.length) extension = @"mp3";
    }
    else if (type==ACMediaVideo) {
        fileTypDirctory = @"ACVideoCache";
        if (!extension.length) extension = @"mp4";
    }else {
        fileTypDirctory = @"ACFileCache";
    }
    
    NSString *storeName = extension.length ? [NSString stringWithFormat:@"%ld.%@", key, extension] : [NSString stringWithFormat:@"%ld", key];
    
    NSString* directory =  [[self msgMediaDirForTarget:target] stringByAppendingPathComponent:fileTypDirctory];
    if (![[NSFileManager defaultManager] fileExistsAtPath:directory]) {
        NSError* error;
        [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:true attributes:nil error:&error];
        if (error) {
            return nil;
        }
    }
    
    return [directory stringByAppendingPathComponent:storeName];;
}

+ (NSString*)getTmpMsgMediaFilePathForKey:(long)key target:(NSString *)target withType:(ACMediaItemType)type extension:(nullable NSString *)extension {
    NSString* directory = [[[self tmpDir] stringByAppendingPathComponent:@"ACIMLibTmpMedia"] stringByAppendingPathComponent:[target ac_md5String]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:directory]) {
        NSError* error;
        [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:true attributes:nil error:&error];
        if (error) {
            return nil;
        }
    }
    return [directory stringByAppendingPathComponent:[[NSString stringWithFormat:@"%ld", key] ac_md5String]];
}

+ (void)deleteMsgMediaFilesWithKeys:(NSArray *)keys target:(NSString *)target {
    
    NSMutableArray *fileNameToDelete = [NSMutableArray array];
    for (NSNumber *k in keys) {
        [fileNameToDelete addObject:[NSString stringWithFormat:@"%@", k]];
    }
    
    NSURL *diskCacheURL = [NSURL fileURLWithPath:[self msgMediaDirForTarget:target] isDirectory:YES];
    
    NSArray<NSString *> *resourceKeys = @[NSURLIsDirectoryKey, NSURLNameKey];

    NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtURL:diskCacheURL
                                                                 includingPropertiesForKeys:resourceKeys
                                                                                    options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                               errorHandler:NULL];
    
    
    NSMutableArray<NSURL *> *urlsToDelete = [[NSMutableArray alloc] init];
    for (NSURL *fileURL in fileEnumerator) {
        NSError *error;
        NSDictionary<NSString *, id> *resourceValues = [fileURL resourceValuesForKeys:resourceKeys error:&error];
        
        if (error || !resourceValues || [resourceValues[NSURLIsDirectoryKey] boolValue]) {
            continue;
        }
        
        NSString *fileName = [resourceValues[NSURLNameKey] stringByDeletingPathExtension];
        if ([fileNameToDelete containsObject:fileName]) {
            [urlsToDelete addObject:fileURL];
        }
    }
    
    for (NSURL *fileURL in urlsToDelete) {
        [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
    }
    
}

+ (void)deleteAllMsgMediaFilesForTarget:(NSString *)target {
    [[NSFileManager defaultManager] removeItemAtPath:[self msgMediaDirForTarget:target] error:nil];
}

+ (NSString *_Nullable)getUserArchiverFilePath:(NSString *_Nonnull)fileName {
    if (![NSString ac_isValidString:fileName]) {
        return nil;
    }
    NSString *userDir = [self currentUserRootDir];
    if (!userDir) return nil;
    
    NSString *archiverDir = [userDir stringByAppendingPathComponent:@"Archiver"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:archiverDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:archiverDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return [archiverDir stringByAppendingPathComponent:fileName];
}


@end
