//
//  SGFileManager.h
//  Sugram
//
//  Created by Humberto on 2020/7/2.
//  Copyright © 2020 gossip. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    ACMediaPhoto,
    ACMediaAudio,
    ACMediaVideo,
    ACMediaFile
} ACMediaItemType;


@interface ACFileManager : NSObject

#pragma mark - 沙盒目录相关
// 沙盒中Documents的目录路径
+ (NSString *)documentsDir;
// 沙盒中Library的目录路径
+ (NSString *)libraryDir;
// 沙盒中Libarary/Preferences的目录路径
+ (NSString *)preferencesDir;
// 沙盒中Library/Caches的目录路径
+ (NSString *)cachesDir;
// 沙盒中tmp的目录路径
+ (NSString *)tmpDir;

+ (NSString *)IMLibRootDir;
+ (NSString *)publicPath;
+ (NSString *)logsPath;
+ (NSString *)dbPathForUid:(long)uid;


/// 获取媒体消息存储路径
/// @param key 唯一key（对应是msgId）
/// @param target 会话ID
/// @param type 媒体类型
+ (NSString*)getMsgMediaFilePathForKey:(long)key target:(NSString *)target withType:(ACMediaItemType)type;
+ (NSString*)getMsgMediaFilePathForKey:(long)key target:(NSString *)target withType:(ACMediaItemType)type extension:(nullable NSString *)extension;
+ (NSString*)getTmpMsgMediaFilePathForKey:(long)key target:(NSString *)target withType:(ACMediaItemType)type extension:(nullable NSString *)extension;

+ (void)deleteMsgMediaFilesWithKeys:(NSArray *)keys target:(NSString *)target;

+ (void)deleteAllMsgMediaFilesForTarget:(NSString *)target;

+ (NSString *_Nullable)getUserArchiverFilePath:(NSString *_Nonnull)fileName;


@end

NS_ASSUME_NONNULL_END
