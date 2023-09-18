//
//  ACDialogIdConverter.m
//  ACIMLib
//
//  Created by 子木 on 2022/7/2.
//

#import "ACDialogIdConverter.h"

static NSString * const kSuperGroupTag = @"SG";
static NSString * const kGroupTag = @"G";
static NSString * const kPrivateTag = @"P";
static NSString * const kUnSupportedTag = @"US";
static NSString * const kTargetIdConnectorStr  = @"::";
static NSString * const kChannelConnectorStr  = @"_";

@implementation ACConversationTypeTargetInfo

+ (instancetype)instanceWithType:(ACConversationType)type targetId:(long)targetId {
    ACConversationTypeTargetInfo *info = [[ACConversationTypeTargetInfo alloc] init];
    info.type = type;
    info.targetId = targetId;
    return info;
}

@end

@implementation ACDialogIdConverter

+ (NSString *)getSgDialogIdWithConversationType:(ACConversationType)type targetId:(long)targetId {
    return [self getSgDialogIdWithConversationType:type targetId:targetId channelId:nil];
}

+ (NSString *)getSgDialogIdWithConversationType:(ACConversationType)type targetId:(long)targetId channelId:(NSString *)channelId {
    if (targetId == 0) return @"";
    
    switch (type) {
        case ConversationType_PRIVATE:
            return [NSString stringWithFormat:@"%@%@%ld",kPrivateTag, kTargetIdConnectorStr, targetId];
        case ConversationType_GROUP:
            return [NSString stringWithFormat:@"%@%@%ld",kGroupTag, kTargetIdConnectorStr, targetId];
        case ConversationType_ULTRAGROUP:
            if (channelId.length) {
                return [NSString stringWithFormat:@"%@%@%ld%@%@",kSuperGroupTag, kTargetIdConnectorStr,targetId, kChannelConnectorStr, channelId];;
            }
            return [NSString stringWithFormat:@"%@%@%ld",kSuperGroupTag, kTargetIdConnectorStr, targetId];
        default:
            return @"";
    }
}

+ (BOOL)isGroupType:(NSString *)dialogId {
    return [dialogId hasPrefix:kGroupTag] || [dialogId hasPrefix:kSuperGroupTag];
}

+ (BOOL)isSuperGroupType:(NSString *)dialogId {
    return [dialogId hasPrefix:kSuperGroupTag];
}

+ (BOOL)isSupported:(ACConversationType)type {
    return type == ConversationType_GROUP || type == ConversationType_PRIVATE;
}

+ (ACConversationTypeTargetInfo *)getRCConversationInfoWithDialogId:(NSString *)dialogId {
    if (!dialogId.length) {
        return nil;
    }
    
    NSArray *compo = [dialogId componentsSeparatedByString:kTargetIdConnectorStr];
    if (compo.count != 2) {
        return nil;
    }
    NSString *conversationTypeTag = compo[0];
  
    if ([conversationTypeTag isEqualToString:kGroupTag]) {
        return [ACConversationTypeTargetInfo instanceWithType:ConversationType_GROUP targetId:[compo[1] longLongValue]];
    }
    
    if ([conversationTypeTag isEqualToString:kPrivateTag]) {
        return [ACConversationTypeTargetInfo instanceWithType:ConversationType_PRIVATE targetId:[compo[1] longLongValue]];
    }
    
    if ([conversationTypeTag isEqualToString:kSuperGroupTag]) {
        
        NSUInteger idx = [compo[1] rangeOfString:kChannelConnectorStr].location;
        if (idx != NSNotFound) {
            long target = [[compo[1] substringToIndex:idx] longLongValue];
            NSString *channel = [compo[1] substringFromIndex:idx+1];
            
            ACConversationTypeTargetInfo *info = [ACConversationTypeTargetInfo instanceWithType:ConversationType_ULTRAGROUP targetId:target];
            info.channel = channel;
            return info;
        } else {
            return [ACConversationTypeTargetInfo instanceWithType:ConversationType_ULTRAGROUP targetId:[compo[1] longLongValue]];;
        }
        
    }
    
    return nil;
}

@end
