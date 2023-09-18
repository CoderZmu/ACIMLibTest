//
//  ACMessageSerializeGlobalHelper.m
//  ACIMLib
//
//  Created by 子木 on 2022/6/30.
//

#import "ACMessageSerializeSupport.h"
#import "ACIMIWMessageContent.h"
#import "ACMessageMo.h"
#import "ACBase.h"
#import "ACServerTime.h"
#import "ACMessageHeader.h"

@interface ACMessageSerializeSupport()

@property (nonatomic, strong) NSMutableDictionary<NSString *, Class> *messageContentClasses; // objectName : contentClass  映射表
@end

@implementation ACMessageSerializeSupport


+ (ACMessageSerializeSupport *)shared {
    static ACMessageSerializeSupport *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ACMessageSerializeSupport alloc] init];
    });
    return instance;
}

- (void)registerMessageContentClass:(Class)contentClass  {
    if ([contentClass conformsToProtocol:@protocol(ACMessageCoding)] && [contentClass conformsToProtocol:@protocol(ACMessagePersistentCompatible)]) {
        [self.messageContentClasses setObject:contentClass forKey:[contentClass getObjectName]];
    }
}

- (Class)getMessageContentClass:(NSString *)objectName {
    return [self.messageContentClasses objectForKey:objectName];
}

- (NSString *)getMessageType:(ACMessageMo *)messageMo {
    Class cls = [self getMessageContentClass:messageMo.Property_ACMessage_objectName];
    if ([cls isSubclassOfClass:ACIMIWMessageContent.class]) {
        // 自定义消息
        ACIMIWMessageContent *content = [[cls alloc] init];
        [content decodeWithData:[messageMo.Property_ACMessage_mediaAttribute ac_jsonValueDecoded]];
        return content.messageType;
    }

    return messageMo.Property_ACMessage_objectName;
}

- (NSArray *)getSearchableWords:(ACMessageMo *)messageMo {
    Class cls = [self getMessageContentClass:messageMo.Property_ACMessage_objectName];
    if (!cls) return nil;
    if (![cls instancesRespondToSelector:@selector(getSearchableWords)]) return nil;
    
    ACMessageContent *content = [[cls alloc] init];
    [content decodeWithData:[messageMo.Property_ACMessage_mediaAttribute ac_jsonValueDecoded]];
    return [content getSearchableWords];
}

- (BOOL)messageShouldPersisted:(NSString *)objectName {
    ACMessagePersistent flag = [self getMessagePersistentFlag:objectName];
    return flag & MessagePersistent_ISPERSISTED;
}

- (BOOL)messageShouldCounted:(NSString *)objectName {
    ACMessagePersistent flag = [self getMessagePersistentFlag:objectName];
    return flag == MessagePersistent_ISCOUNTED;
}

- (BOOL)isStatusMessage:(NSString *)objectName {
    return [self getMessagePersistentFlag:objectName] == MessagePersistent_STATUS;
}

- (BOOL)isHQVoiceMessage:(NSString *)objectName {
    return [objectName isEqualToString:ACHQVoiceMessageTypeIdentifier];
}

- (NSString *)recallNotificationMessageType {
    return ACRecallNotificationMessageIdentifier;
}

- (ACMessagePersistent)getMessagePersistentFlag:(NSString *)objectName {
    Class contentClass = [self getMessageContentClass:objectName];
    if (!contentClass) return MessagePersistent_NONE;
    
    return [contentClass persistentFlag];
}

- (BOOL)isSupported:(NSString *)objectName {
    return [self getMessageContentClass:objectName] != nil;
}


// 将消息体改为撤回消息
- (NSString *)changeMessageContentAsRecallStatus:(ACMessageMo *)originalMessage recallTime:(long)recallTime {

    if ([originalMessage.Property_ACMessage_objectName isEqualToString: ACRecallNotificationMessageIdentifier]) {
        return originalMessage.Property_ACMessage_mediaAttribute;
    }
    
    NSDictionary *oldContent = [originalMessage.Property_ACMessage_mediaAttribute ac_jsonValueDecoded];
    NSMutableDictionary *content = [NSMutableDictionary dictionary];
    [content ac_setSafeObject:oldContent[@"user"] forKey:@"user"];
    [content addEntriesFromDictionary:@{
        @"operatorId": @(originalMessage.Property_ACMessage_srcUin), // 发起撤回操作的用户 ID
        @"recallTime": @(recallTime), //  撤回的时间
        @"originalObjectName": originalMessage.Property_ACMessage_objectName, // 原消息的消息类型名
    }];
    
    
    [content ac_setSafeObject:[originalMessage.Property_ACMessage_objectName isEqualToString:ACTextMessageTypeIdentifier] ? oldContent[@"content"] : nil forKey:@"recallContent"];//  // 撤回的文本消息的内容

    return [NSString ac_jsonStringWithJsonObject:content];;
}


- (NSMutableDictionary<NSString *,Class> *)messageContentClasses {
    if (!_messageContentClasses) {
        _messageContentClasses = [NSMutableDictionary dictionary];
    }
    return _messageContentClasses;
}

@end
