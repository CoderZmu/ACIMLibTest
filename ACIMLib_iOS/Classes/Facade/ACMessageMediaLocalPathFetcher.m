//
//  ACMessageMediaLocalUrlFetcher.m
//  ACIMLib
//
//  Created by 子木 on 2023/8/22.
//

#import "ACMessageMediaLocalPathFetcher.h"
#import "ACMessage.h"
#import "ACFileManager.h"
#import "ACMessageHeader.h"
#import "ACDialogIdConverter.h"

@implementation ACMessageMediaLocalPathFetcher

+ (NSString *)mediaPathForMediaMessage:(ACMessage *)message {
    ACMediaItemType type;
    NSString *extension;
    ACMediaMessageContent *mediaContent = (ACMediaMessageContent *)(message.content);
    if ([mediaContent isKindOfClass:ACImageMessage.class] || [mediaContent isKindOfClass:ACGIFMessage.class]) {
        type = ACMediaPhoto;
        if ([mediaContent isKindOfClass:ACGIFMessage.class]) {
            extension = @"gif";
        }
    }
    else if ([mediaContent isKindOfClass:ACSightMessage.class]) {
        type = ACMediaVideo;
    }
    else if ([mediaContent isKindOfClass:ACHQVoiceMessage.class]) {
        type = ACMediaAudio;
        extension = ((ACHQVoiceMessage *)mediaContent).type;
    } else {
        type = ACMediaFile;
        extension = ((ACFileMessage *)mediaContent).type;
    }
    NSString *localPath;
    if (message.sentStatus == SentStatus_SENDING) {
        NSString *tmpLocalPath =[ACFileManager getTmpMsgMediaFilePathForKey:message.messageId target:[ACDialogIdConverter getSgDialogIdWithConversationType:message.conversationType targetId:message.targetId] withType:type extension:extension];

        if ([[NSFileManager defaultManager] fileExistsAtPath:tmpLocalPath]) {
            localPath = tmpLocalPath;
        }
    }
    if (!localPath) {
        localPath = [ACFileManager getMsgMediaFilePathForKey:message.messageId target:[ACDialogIdConverter getSgDialogIdWithConversationType:message.conversationType targetId:message.targetId] withType:type extension:extension];
    }
    return localPath;
}
@end
