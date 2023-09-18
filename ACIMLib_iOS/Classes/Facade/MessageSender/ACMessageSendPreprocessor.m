//
//  ACMessageSendPreprocessor.m
//  ACIMLib
//
//  Created by 子木 on 2022/6/30.
//

#import "ACBase.h"
#import "ACFileManager.h"
#import "ACLogger.h"
#import "ACMessageHeader.h"
#import "ACGIFMessage+Private.h"
#import "ACImageMessage+Private.h"
#import "ACMessageSendPreprocessor.h"
#import "UIImage+SPModify.h"
#import <AVFoundation/AVFoundation.h>

static NSString *const MessageSendPreprocessorError = @"MessageSendPreprocessorError";

@implementation ACImageMessageSendPreprocessor

- (dispatch_queue_t)seriesQueue  {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.message.imageProcrocessor", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

- (ACErrorCode)preprocess:(ACMessageContent *)messageContent dialogId:(NSString *)target msgId:(long)msgId {
    ACImageMessage *imageMessage = (ACImageMessage *)messageContent;
    NSString *storePath = [ACFileManager getMsgMediaFilePathForKey:msgId target:target withType:ACMediaPhoto extension:nil];
    NSString *tmpStorePath = [ACFileManager getTmpMsgMediaFilePathForKey:msgId target:target withType:ACMediaPhoto extension:nil];
    
    if (imageMessage.remoteUrl.length) {
        if (imageMessage.localPath.length && [[NSFileManager defaultManager] fileExistsAtPath:imageMessage.localPath]) {
            [[NSFileManager defaultManager] copyItemAtPath:imageMessage.localPath toPath:storePath error:nil];
        }

        return AC_SUCCESS;
    }

    

    // 图片资源
    UIImage *originalImage = imageMessage.originalImage ?: imageMessage.originalImageData ? [UIImage imageWithData:imageMessage.originalImageData] : nil;
    originalImage = [originalImage sp_fixOrientation];
    if (!originalImage) { // 图片为空
        return AC_MEDIA_EXCEPTION;
    }

    NSData *imageData;
    NSData *thumbImageData;
    CGSize finalPixelSize = originalImage.size;
    if (imageMessage.full) {
        imageData = imageMessage.originalImageData ?: [originalImage sp_losslessCompress];
    } else {
        imageData = [originalImage sp_compressIntelligently:ACImageEncodeFormat_IO finalPixelSize:&finalPixelSize];
    }
    thumbImageData = [originalImage sp_thumbnail:ACImageEncodeFormat_IO];
    
    NSError *error;
    [imageData writeToFile:tmpStorePath atomically:YES];
    [imageData writeToFile:storePath atomically:YES];

    if (error) {
        return AC_MEDIA_EXCEPTION;
    }

    imageMessage.width = finalPixelSize.width;
    imageMessage.height = finalPixelSize.height;
    imageMessage.localPath = tmpStorePath;
    
    return AC_SUCCESS;
}

- (void)compress:(ACMessageContent *)messageContent dialogId:(NSString *)target msgId:(long)msgId complete:(void (^)(ACErrorCode))completeBlock {
    ACImageMessage *imageMessage = (ACImageMessage *)messageContent;
    NSString *storePath = [ACFileManager getMsgMediaFilePathForKey:msgId target:target withType:ACMediaPhoto];
    
    dispatch_async([self seriesQueue], ^{
        if (imageMessage.remoteUrl.length) {
            !completeBlock ? : completeBlock(AC_SUCCESS);
            return;
        }

        UIImage *originalImage = imageMessage.originalImage ?: imageMessage.originalImageData ? [UIImage imageWithData:imageMessage.originalImageData] : nil;
        if (!originalImage) {
            originalImage = [UIImage imageWithContentsOfFile:storePath];
        }
        // 修正图片的方向
        originalImage = [originalImage sp_fixOrientation];

        if (!originalImage) { // 图片为空
            completeBlock(AC_MEDIA_EXCEPTION);
        }

        CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
        dispatch_queue_t concurrentQueue = dispatch_get_global_queue(0, 0);
        dispatch_group_t dispatchGroup = dispatch_group_create();

        dispatch_group_enter(dispatchGroup);
        dispatch_group_enter(dispatchGroup);
        __block NSData *imageData;
        __block NSData *thumbImageData;
        __block CGSize finalPixelSize = originalImage.size;
        dispatch_async(concurrentQueue, ^{
            if (imageMessage.full) {
                imageData = [NSData dataWithContentsOfFile:imageMessage.localPath];
            } else {
                imageData = [originalImage sp_compressIntelligently:ACImageEncodeFormat_Webp finalPixelSize:&finalPixelSize];
            }

            dispatch_group_leave(dispatchGroup);
        });
        dispatch_async(concurrentQueue, ^{
            thumbImageData = [originalImage sp_thumbnail:ACImageEncodeFormat_Webp];
            dispatch_group_leave(dispatchGroup);
        });
        dispatch_group_wait(dispatchGroup, DISPATCH_TIME_FOREVER);
        CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
        ACLog(@"ACImageMessageSendPreprocessor compressImage -> %d", (int)((endTime - startTime) * 1000));

        [[NSFileManager defaultManager] removeItemAtPath:storePath error:nil];
        [imageData writeToFile:storePath atomically:true];

        imageMessage.width = finalPixelSize.width;
        imageMessage.height = finalPixelSize.height;
        imageMessage.localPath = storePath;
        imageMessage.thumbnailData = thumbImageData;
        imageMessage.originalImage = nil;
        imageMessage.originalImageData = nil;
        completeBlock(AC_SUCCESS);
    });
}

@end


@implementation ACFileMessageSendPreprocessor

- (ACErrorCode)preprocess:(ACMessageContent *)messageContent dialogId:(NSString *)target msgId:(long)msgId {
    ACFileMessage *fileMessage = (ACFileMessage *)messageContent;
    NSString *storePath = [ACFileManager getMsgMediaFilePathForKey:msgId target:target withType:ACMediaFile extension:fileMessage.type];

    if (fileMessage.remoteUrl.length) {
        if (fileMessage.localPath.length && [[NSFileManager defaultManager] fileExistsAtPath:fileMessage.localPath]) {
            [[NSFileManager defaultManager] copyItemAtPath:fileMessage.localPath toPath:storePath error:nil];
        }

        return YES;
    }

    NSURL *fileURL = [NSURL fileURLWithPath:fileMessage.localPath];
    NSNumber *fileSizeValue = nil;
    [fileURL getResourceValue:&fileSizeValue
                       forKey:NSURLFileSizeKey
                        error:nil];
    long fileSizeLongValue = [fileSizeValue longValue];

    if (fileSizeLongValue <= 0) {
        return AC_MEDIA_EXCEPTION;
    }

    if (fileSizeLongValue > 100 * 1024 * 1024) {
        return AC_FILE_MSG_SIZE_LIMIT_EXCEED;
    }

    NSString *fileName = [fileURL lastPathComponent];
    NSString *extension = fileURL.pathExtension;

    if (extension.length == 0) {
        extension = @"bin";
    }

    NSError *copyError;
    [[NSFileManager defaultManager] copyItemAtURL:fileURL toURL:[NSURL fileURLWithPath:storePath] error:&copyError];

    if (copyError) {
        return AC_MEDIA_EXCEPTION;
    }

    fileMessage.localPath = storePath;
    fileMessage.name = fileName;
    fileMessage.type = extension;
    fileMessage.size = fileSizeLongValue;

    return AC_SUCCESS;
}

@end

@implementation ACVideoMessageSendPreprocessor

- (ACErrorCode)preprocess:(ACMessageContent *)messageContent dialogId:(NSString *)target msgId:(long)msgId {
    ACSightMessage *sightMessage = (ACSightMessage *)messageContent;

    if (sightMessage.remoteUrl.length) {
        NSString *storePath = [ACFileManager getMsgMediaFilePathForKey:msgId target:target withType:ACMediaVideo];

        if (sightMessage.localPath.length && [[NSFileManager defaultManager] fileExistsAtPath:sightMessage.localPath]) {
            [[NSFileManager defaultManager] copyItemAtPath:sightMessage.localPath toPath:storePath error:nil];
        }

        return AC_SUCCESS;
    }

    if (![[NSFileManager defaultManager] fileExistsAtPath:sightMessage.localPath]) {
        return AC_MEDIA_EXCEPTION;
    }

    NSNumber *fileSizeValue = nil;
    [[NSURL fileURLWithPath:sightMessage.localPath] getResourceValue:&fileSizeValue
                                                              forKey:NSURLFileSizeKey
                                                               error:nil];

    if (fileSizeValue.intValue <= 0) {
        return AC_MEDIA_EXCEPTION;
    }

    int actualDuration = [self videoTime:[NSURL fileURLWithPath:sightMessage.localPath]];

    if (actualDuration > 2 * 60) {
        return AC_SIGHT_MSG_DURATION_LIMIT_EXCEED;
    }

    sightMessage.size = [fileSizeValue longLongValue];
    sightMessage.name = [sightMessage.localPath lastPathComponent];

    sightMessage.duration = actualDuration;

    // 封面图
    sightMessage.thumbnailData = sightMessage.thumbnailData != nil ? sightMessage.thumbnailData : [[self imageWithVideoURL:[NSURL fileURLWithPath:sightMessage.localPath]] sp_thumbnail:ACImageEncodeFormat_Webp];

    NSString *storePath = [ACFileManager getMsgMediaFilePathForKey:msgId target:target withType:ACMediaVideo];

    if (![storePath isEqualToString:sightMessage.localPath]) {
        NSError *copyError;

        if ([[NSFileManager defaultManager] fileExistsAtPath:storePath]) {
            [[NSFileManager defaultManager] removeItemAtPath:storePath error:nil];
        }

        [[NSFileManager defaultManager] moveItemAtPath:sightMessage.localPath toPath:storePath error:&copyError];
        sightMessage.localPath = storePath;

        if (copyError) {
            return AC_MEDIA_EXCEPTION;
        }
    }

    return AC_SUCCESS;
}

- (void)compress:(ACMessageContent *)messageContent dialogId:(NSString *)target msgId:(long)msgId complete:(void (^)(ACErrorCode))completeBlock {
    ACSightMessage *sightMessage = (ACSightMessage *)messageContent;

    if (sightMessage.remoteUrl.length) {
        !completeBlock ? : completeBlock(AC_SUCCESS);
        return;
    }

    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
    NSString *storePath = [ACFileManager getMsgMediaFilePathForKey:msgId target:target withType:ACMediaVideo];

    // 压缩视频
    [self compressVideo:sightMessage.localPath
             outputPath:tempPath
               complete:^(BOOL success) {
        if (success) {
            NSError *error;
            [[NSFileManager defaultManager] removeItemAtPath:sightMessage.localPath
                                                       error:nil];
            [[NSFileManager defaultManager] moveItemAtPath:tempPath
                                                    toPath:sightMessage.localPath
                                                     error:&error];

            if (error) {
                completeBlock(AC_SIGHT_COMPRESS_FAILED);
                return;
            }

            sightMessage.localPath = storePath;

            NSNumber *fileSizeValue = nil;
            [[NSURL fileURLWithPath:sightMessage.localPath] getResourceValue:&fileSizeValue
                                                                      forKey:NSURLFileSizeKey
                                                                       error:nil];
            sightMessage.size = [fileSizeValue longLongValue];
            completeBlock(AC_SUCCESS);
        } else {
            completeBlock(AC_SIGHT_COMPRESS_FAILED);
        }
    }];
}

- (void)compressVideo:(NSString *)videoPath outputPath:(NSString *)outputPath complete:(void (^)(BOOL success))completeBlock {
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:videoPath] options:nil];
    NSString *qualityPreset = AVAssetExportPreset1280x720;
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:qualityPreset];
    exportSession.outputURL = [NSURL fileURLWithPath:outputPath];
    exportSession.outputFileType = AVFileTypeMPEG4;
    exportSession.shouldOptimizeForNetworkUse= YES;
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void) {
        switch (exportSession.status) {
            case AVAssetExportSessionStatusCancelled:
                completeBlock(NO);
                break;
            case AVAssetExportSessionStatusUnknown:
                break;
            case AVAssetExportSessionStatusWaiting:
                break;
            case AVAssetExportSessionStatusExporting:
                break;
            case AVAssetExportSessionStatusCompleted: {
                completeBlock(YES);
            } break;
            case AVAssetExportSessionStatusFailed: {
                completeBlock(NO);
            } break;
        }
    }];
    
}

- (Float64)videoTime:(NSURL *)filePath {
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:filePath options:nil];
    CMTime assetTime = [asset duration];
    Float64 duration = CMTimeGetSeconds(assetTime);

    return duration;
}

// 获取视频的首帧图
- (UIImage *)imageWithVideoURL:(NSURL *)url {
    NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:url options:opts];
    // 根据asset构造一张图
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:urlAsset];

    // 设定缩略图的方向
    // 如果不设定，可能会在视频旋转90/180/270°时，获取到的缩略图是被旋转过的，而不是正向的（自己的理解）
    generator.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(0.0, 600);
    // 设置图片的最大size(分辨率)
    NSError *error = nil;
    CMTime actualTime;
    // 根据时间，获得第N帧的图片
    // CMTimeMake(a, b)可以理解为获得第a/b秒的frame
    CGImageRef img = [generator copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *image = [[UIImage alloc] initWithCGImage:img];
    CGImageRelease(img);
    return image;
}

@end


@implementation ACGifMessageSendPreprocessor

- (ACErrorCode)preprocess:(ACMessageContent *)messageContent dialogId:(NSString *)target msgId:(long)msgId {
    ACGIFMessage *gifMessage = (ACGIFMessage *)messageContent;
    NSString *storePath = [ACFileManager getMsgMediaFilePathForKey:msgId target:target withType:ACMediaPhoto extension:@"gif"];
    
    if (gifMessage.remoteUrl.length) {
        if (gifMessage.localPath.length && [[NSFileManager defaultManager] fileExistsAtPath:gifMessage.localPath]) {
            [[NSFileManager defaultManager] copyItemAtPath:gifMessage.localPath toPath:storePath error:nil];
        }
        
        return AC_SUCCESS;
    }
    
    NSData *gifData = gifMessage.gifData;

    if (!gifData.length) {
        return AC_MEDIA_EXCEPTION;
    }

    long fileSizeLongValue = gifData.length;

    if (fileSizeLongValue > 2 * 1024 * 1024) {
        return AC_GIF_MSG_SIZE_LIMIT_EXCEED;
    }
    
    NSError *writeError;
    [gifData writeToURL:[NSURL fileURLWithPath:storePath] options:NSDataWritingAtomic error:&writeError];
    
    if (writeError) {
        return AC_MEDIA_EXCEPTION;
    }
    
   
    
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFTypeRef)(gifData), NULL);
    size_t count = CGImageSourceGetCount(source);
    
    if (count > 0) {
        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, 0, NULL);
        UIImage *image = [UIImage imageWithCGImage:imageRef];
        gifMessage.thumbnailData = [image sp_thumbnail:ACImageEncodeFormat_Webp];
        
        CFRelease(imageRef);
    }
    
    CFRelease(source);
    
    gifMessage.localPath = storePath;
    gifMessage.gifDataSize = fileSizeLongValue;
    
    if (gifMessage.height <= 0 || gifMessage.width <= 0) {
        CGSize fixedSize = [self getGifSizeFrom:[NSData dataWithContentsOfFile:storePath]];
        gifMessage.width = fixedSize.width;
        gifMessage.height = fixedSize.height;
    }
    gifMessage.gifData = nil;
    
    return AC_SUCCESS;
}

- (CGSize)getGifSizeFrom:(NSData *)data {
    if (data == nil || data.length <= 0) {
        return CGSizeZero;
    }

    CGImageSourceRef ref = CGImageSourceCreateWithData((__bridge CFDataRef)(data), NULL);

    if (!ref) {
        return CGSizeZero;
    }

    CFDictionaryRef dictRef = CGImageSourceCopyPropertiesAtIndex(ref, 0, NULL);
    NSDictionary *dict = (__bridge NSDictionary *)dictRef;

    NSNumber *pixelWidth = (dict[(NSString *)kCGImagePropertyPixelWidth]);
    NSNumber *pixelHeight = (dict[(NSString *)kCGImagePropertyPixelHeight]);

    CGSize sizeAsInProperties = CGSizeMake([pixelWidth floatValue], [pixelHeight floatValue]);

    if (dictRef) {
        CFRelease(dictRef);
    }

    CFRelease(ref);
    return sizeAsInProperties;
}

@end


@implementation ACHQVoiceMessageSendPreprocessor

- (ACErrorCode)preprocess:(ACMessageContent *)messageContent dialogId:(NSString *)target msgId:(long)msgId {
    ACHQVoiceMessage *voiceMessage = (ACHQVoiceMessage *)messageContent;

    if (voiceMessage.remoteUrl.length) {
        return AC_SUCCESS;
    }

    if (![[NSFileManager defaultManager] fileExistsAtPath:voiceMessage.localPath]) {
        return AC_MEDIA_EXCEPTION;
    }

    // 音频时长
    AVURLAsset *audioAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:voiceMessage.localPath] options:nil];
    CMTime audioDuration = audioAsset.duration;
    float audioDurationSeconds = CMTimeGetSeconds(audioDuration);

    if (!audioDurationSeconds) {
        return AC_MEDIA_EXCEPTION;
    }

    NSString *extension = voiceMessage.localPath.pathExtension != nil ? voiceMessage.localPath.pathExtension : @"mp3";
    NSString *storePath = [ACFileManager getMsgMediaFilePathForKey:msgId target:target withType:ACMediaAudio extension:extension];
    NSError *copyError;
    [[NSFileManager defaultManager] copyItemAtURL:[NSURL fileURLWithPath:voiceMessage.localPath] toURL:[NSURL fileURLWithPath:storePath] error:&copyError];

    if (copyError) {
        return AC_MEDIA_EXCEPTION;
    }

    if (voiceMessage.duration <= 0) {
        voiceMessage.duration = audioDurationSeconds;
    }

    voiceMessage.type = extension;
    voiceMessage.localPath = storePath;
    return AC_SUCCESS;
}

@end

@implementation ACGenericMediaMessageSendPreprocessor

- (ACErrorCode)preprocess:(ACMessageContent *)messageContent dialogId:(NSString *)target msgId:(long)msgId {
    ACMediaMessageContent *mediaMessage = (ACMediaMessageContent *)messageContent;
    NSString *storePath = [ACFileManager getMsgMediaFilePathForKey:msgId target:target withType:ACMediaFile extension:nil];
    
    if (mediaMessage.remoteUrl.length) {
        if (mediaMessage.localPath.length && [[NSFileManager defaultManager] fileExistsAtPath:mediaMessage.localPath]) {
            [[NSFileManager defaultManager] copyItemAtPath:mediaMessage.localPath toPath:storePath error:nil];
        }
        return AC_SUCCESS;
    }
    
    NSURL *fileURL = [NSURL fileURLWithPath:mediaMessage.localPath];
    NSNumber *fileSizeValue = nil;
    [fileURL getResourceValue:&fileSizeValue
                       forKey:NSURLFileSizeKey
                        error:nil];
    long fileSizeLongValue = [fileSizeValue longValue];

    if (fileSizeLongValue <= 0) {
        return AC_MEDIA_EXCEPTION;
    }

    if (fileSizeLongValue > 100 * 1024 * 1024) {
        return AC_FILE_MSG_SIZE_LIMIT_EXCEED;
    }

    NSString *fileName = [fileURL lastPathComponent];


    NSError *copyError;
    [[NSFileManager defaultManager] copyItemAtURL:fileURL toURL:[NSURL fileURLWithPath:storePath] error:&copyError];

    if (copyError) {
        return AC_MEDIA_EXCEPTION;
    }

    mediaMessage.localPath = storePath;
    return AC_SUCCESS;
    
}

@end
