//
//  ACServerMessageDataParser.m
//  ACIMLib
//
//  Created by 子木 on 2022/8/1.
//

#import "ACServerMessageDataParser.h"
#import "AcpbPrivatechat.pbobjc.h"
#import "AcpbGlobalStructure.pbobjc.h"
#import "ACSecretKey.h"
#import "ACBase.h"
#import "ACMessageMo.h"
#import "ACDialogIdConverter.h"
#import "ACDialogManager.h"
#import "ACServerTime.h"

@implementation ACServerMessageDataParser

+ (dispatch_queue_t)operationQueue {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.newMessage.process", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}


- (void)parse:(NSDictionary<NSString*, ACPBDialogMessageList*> *)orginalMsgs callback:(void(^)(BOOL done, NSDictionary<NSString *, NSArray<ACMessageMo *> *> *msgMaps))callback {
    dispatch_async([[self class] operationQueue], ^{
        NSMutableDictionary *msgDic = [NSMutableDictionary dictionary];
        [orginalMsgs enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, ACPBDialogMessageList * _Nonnull object, BOOL * _Nonnull stop) {
            NSMutableArray *arr = [NSMutableArray array];
            for (ACPBDialogMessage *dialogMessage in object.dialogMessageArray) {
                //是否是共享群消息，群消息扩散
                if (dialogMessage.sharingGroupFlag) {
                } else {
                    ACMessageMo *message = [ACMessageMo messageCopyWithDialogMessage:dialogMessage];
                    [arr addObject:message];
                }
            }
            if (arr.count) {
                [msgDic ac_setSafeObject:arr forKey:key];
            }
        }];
  

        if (!msgDic.count) {
            callback(YES, @{});
            return;
        }
        NSMutableArray *remainDialogIds = [msgDic.allKeys mutableCopy];
        [[ACSecretKey instance] getDialogAesKeyWithDialogIDArr:msgDic.allKeys withCompletion:^(NSDictionary * dialogAesKeys, BOOL remote){
            
            dispatch_async([[self class] operationQueue], ^{
                if (dialogAesKeys.count) {
                    [remainDialogIds removeObjectsInArray:dialogAesKeys.allKeys];
                    callback(remainDialogIds.count == 0, [self parseBatchDislogsMessages:dialogAesKeys.allKeys msgDict:msgDic aesKeys:dialogAesKeys]);
                }

                if (remainDialogIds.count > 0 && remote) {
                    callback(YES, [self parseBatchDislogsMessages:remainDialogIds.copy msgDict:msgDic aesKeys:[NSDictionary new]]);
                }
            });
        }];
    });
   
}



- (NSDictionary<NSString *, NSArray<ACMessageMo *> *> *)parseBatchDislogsMessages:(NSArray *)dialogIdArr msgDict:(NSDictionary *)msgDict aesKeys:(NSDictionary *)aesKeys {
    if (!dialogIdArr.count)  return nil;
    
    NSMutableDictionary<NSString *, NSArray *> *messageDict = [NSMutableDictionary dictionary];

    for (NSString* dialogId in dialogIdArr){
        NSArray *messageArr = [self parseDialogMessages:[msgDict objectForKey:dialogId] forDialogId:dialogId aesKey:aesKeys[dialogId]];
        [messageDict setObject:messageArr forKey:dialogId];
        
    }

    return messageDict;
    
}

- (NSArray *)parseDialogMessages:(NSArray *)originalMessageArray forDialogId:(NSString *)dialogId aesKey:(ACDialogSecretKeyMo *)aesKey {
    NSMutableArray *contentArr = [NSMutableArray array];
    
    for (ACMessageMo* message in originalMessageArray){
        message.Property_ACMessage_dialogIdStr = dialogId;
        message.Property_ACMessage_groupFlag = [ACDialogIdConverter isGroupType:dialogId];
        message.Property_ACMessage_deliveryState = ACMessageSuccessed;
        
        if (aesKey) {
            [message decryptWithAesKey:aesKey];
        }
        [contentArr addObject:message];
    }
    
    return [contentArr copy];
}



@end
