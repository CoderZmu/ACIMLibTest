//
//  ACMessageDownloader.m
//  ACIMLib
//
//  Created by 子木 on 2023/8/22.
//

#import "ACMessageDownloader.h"
#import "ACFileDownloader.h"
#import "ACStatusDefine.h"
#import "ACDialogManager.h"
#import "ACMessageManager.h"
#import "ACMediaMessageContent.h"
#import "ACMessageMo+Adapter.h"
#import "ACFileManager.h"
#import "ACMessageMediaLocalPathFetcher.h"
#import "ACMessageHeader.h"
#import "ACOssBehavior.h"

@implementation ACMessageDownloader

+ (void)downloadMediaMessage:(long)messageId
                    progress:(void (^)(NSProgress *progress))progressBlock
                     success:(void (^)(NSString *mediaPath))successBlock
                       error:(void (^)(ACErrorCode errorCode))errorBlock
                      cancel:(void (^)(void))cancelBlock {
    ACMessage *message = [[[ACMessageManager shared] getMessageWithMsgId:messageId] toRCMessage];
    if (!message || ![message.content isKindOfClass:ACMediaMessageContent.class]) {
        !errorBlock ?: errorBlock(INVALID_PARAMETER_MESSAGEID);
        return;
    }
    ACMediaMessageContent *messageContent = (ACMediaMessageContent *)(message.content);
    if (messageContent.localPath.length && [[NSFileManager defaultManager] fileExistsAtPath:messageContent.localPath]) {
        !successBlock ?: successBlock(messageContent.localPath);
        return;
    }

    NSString *localPath = [ACMessageMediaLocalPathFetcher mediaPathForMediaMessage:message];
    if ([[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
        !successBlock ?: successBlock(localPath);
        return;
    }
    if (!messageContent.remoteUrl.length) {
        !errorBlock ?: errorBlock(INVALID_PARAMETER);
        return;
    }
//    BOOL isImageMsg = [message.objectName isEqualToString:ACImageMessageTypeIdentifier] || [message.objectName isEqualToString:ACGIFMessageTypeIdentifier];
    [[ACFileDownloader shared] downloadFileWithOssKey:messageContent.remoteUrl fileEncryptKey:messageContent.encryptKey destination:[NSURL fileURLWithPath:localPath] ignoreCache:NO progress:^(NSProgress * _Nonnull progress) {
        !progressBlock ?: progressBlock(progress);
    } completed:^(NSError * _Nullable error) {
        if (error == nil) {
            !successBlock ?: successBlock(localPath);
            return;
        }
        if (error.code == ACOssErrorCODE_TaskCancelled) {
            !cancelBlock ?: cancelBlock();
        }
        
        ACErrorCode errorCode = ERRORCODE_UNKNOWN;
        switch (error.code) {
            case ACOssErrorCODE_InitializeServiceFailed:
            case ACOssErrorCODE_SignFailed:
                errorCode = AC_OssServer_InitializeFailed;
                break;
            case ACOssErrorCODE_NotExist:
                errorCode = AC_FILE_EXPIRED;
                break;
            case ACOssErrorCODE_AccessDenied:
                errorCode = AC_Oss_AccessDenied;
                break;
            case ACOssErrorCODE_NetworkError:
                errorCode = AC_FILE_Download_NetworkError;
                break;
            case ACOssErrorCODE_TaskCancelled:
                errorCode = AC_FILE_Download_Cancelled;
                break;
            default:
                break;
        }
        !errorBlock ?: errorBlock(errorCode);
    }];
}

+ (BOOL)cancelDownloadMediaMessage:(long)messageId {
    ACMessage *message = [[[ACMessageManager shared] getMessageWithMsgId:messageId] toRCMessage];
    if (!message || ![message.content isKindOfClass:ACMediaMessageContent.class]) {
        return NO;
    }
    ACMediaMessageContent *messageContent = (ACMediaMessageContent *)(message.content);
    if ([[ACFileDownloader shared] isDownloading:messageContent.remoteUrl]) {
        [[ACFileDownloader shared] cancelDownloading:messageContent.remoteUrl];
        return YES;
    }
    return NO;
}


@end
