//
//  ACMessageSenderManager.m
//  ACIMLib
//
//  Created by 子木 on 2022/6/28.
//

#import "ACAccountManager.h"
#import "ACBase.h"
#import "ACConnectionListenerManager.h"
#import "ACConnectionListenerProtocol.h"
#import "ACFileManager.h"
#import "ACMessage.h"
#import "ACMessageHeader.h"
#import "ACMessageManager.h"
#import "ACMessageMo+Adapter.h"
#import "ACMessageSenderManager.h"
#import "ACMessageSendOperation.h"

static NSString *const kSeparator = @"__***__";

@interface ACMessageSenderManager ()<ACConnectionListenerProtocol>

@property (nonatomic, strong) NSMutableArray *sendingRecordArr;

@property (nonatomic, strong) NSOperationQueue *queue;

@property (nonatomic, strong) dispatch_queue_t recordProcessQueue;
@end

@implementation ACMessageSenderManager

+ (ACMessageSenderManager *)shared {
    static ACMessageSenderManager *instance;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        instance = [[ACMessageSenderManager alloc] init];
        instance.recordProcessQueue = dispatch_queue_create("com.sendrecord.process", DISPATCH_QUEUE_SERIAL);
        instance.queue = [NSOperationQueue new];
        instance.queue.name = @"MessageSender";
        instance.queue.qualityOfService = NSQualityOfServiceUserInitiated;
        instance.queue.maxConcurrentOperationCount = 5;
        [[ACConnectionListenerManager shared] addListener:instance];
    });
    return instance;
}

- (ACMessage *)sendMessage:(ACMessage *)message
              toUserIdList:(NSArray *)userIdList
                sendConfig:(ACSendMessageConfig *)sendConfig
                  progress:(void (^)(int progress, ACMessage *message))progressBlock
                   success:(void (^)(ACMessage *message))successBlock
                     error:(void (^)(ACErrorCode nErrorCode, ACMessage *message))errorBlock {
    NSError *error;
    ACMessageSendOperation *op = [[ACMessageSendOperation alloc] initWithMessage:message toUserIdList:userIdList sendConfig:sendConfig preprocessor:[self createMessagePreprocessor:message.content] error:&error];

    if (error) {
        errorBlock(error.code, 0);
        return nil;
    }

    NSString *key = [self keyForDialog:[op getDialogId] andMsgId:[op getMsgId]];
    long curUid = [ACAccountManager shared].user.Property_SGUser_uin;

    dispatch_async(self.recordProcessQueue, ^{
        [self.sendingRecordArr addObject:key];
        [self saveSendingRecords:self.sendingRecordArr];
    });

    // 移除
    void (^ removeBlock)(void) = ^{
        if (curUid != [ACAccountManager shared].user.Property_SGUser_uin) {
            return;
        }

        dispatch_async(self.recordProcessQueue, ^{
            [self.sendingRecordArr removeObject:key];
            [self saveSendingRecords:self.sendingRecordArr];
        });
    };

    [op setSuccessBlock:^(ACMessage *message) {
        removeBlock();
        ac_dispatch_async_on_main_queue(^{
            !successBlock ? : successBlock(message);
        });
    }
             errorBlock:^(ACErrorCode errorCode, ACMessage *message) {
        removeBlock();
        ac_dispatch_async_on_main_queue(^{
            !errorBlock ? : errorBlock(errorCode, message);
        });
    }
          progressBlock:^(int progress, ACMessage *message) {
        ac_dispatch_async_on_main_queue(^{
            !progressBlock ? : progressBlock(progress, message);
        });
    }];
    
    
    @synchronized (self) {
        [self.queue addOperation:op];
    }

    return [op getSentMessage];
}

- (BOOL)cancelSendMediaMessage:(long)messageId {
    __block BOOL result = NO;
    @synchronized (self) {
        NSArray<ACMessageSendOperation *> *sendOperations = [self.queue operations];
        [sendOperations enumerateObjectsUsingBlock:^(ACMessageSendOperation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj getMsgId] == messageId) {
                result = [obj cancelSendMessage];
                *stop = YES;
            }
        }];
    }
    return result;
}

#pragma mark - ACConnectionListenerProtocol

- (void)userDataDidLoad {
    // 将上次发送中状态的消息修改为失败
    dispatch_async(self.recordProcessQueue, ^{
        NSArray *records = [self getSenddingRecords];

        for (NSString *item in records) {
            NSArray *compo = [item componentsSeparatedByString:kSeparator];
            NSString *dialogId = compo[0];
            long msgId = (long)[compo[1] longLongValue];

            ACMessageMo *message = [[ACMessageManager shared] getMessageWithMsgId:msgId dilogId:dialogId];

            if (message && message.Property_ACMessage_isOut && message.Property_ACMessage_deliveryState <= ACMessageDelivering) {
                message.Property_ACMessage_deliveryState = ACMessageFailure;
                [[ACMessageManager shared] updateMessage:message];
            }
        }

        [self.sendingRecordArr removeAllObjects];
        [self saveSendingRecords:@[]];
    });
}

- (void)onClosed {
    @synchronized (self) {
        [self.queue cancelAllOperations];
    }
}

- (NSString *)keyForDialog:(NSString *)dialogId andMsgId:(long)msgid {
    return [NSString stringWithFormat:@"%@%@%ld", dialogId, kSeparator, msgid];
}

- (id<ACMessageSendPreprocessor>)createMessagePreprocessor:(ACMessageContent *)content {
    if ([content isKindOfClass:ACImageMessage.class]) {
        return [ACImageMessageSendPreprocessor new];
    }

    if ([content isKindOfClass:ACFileMessage.class]) {
        return [ACFileMessageSendPreprocessor new];
    }

    if ([content isKindOfClass:ACSightMessage.class]) {
        return [ACVideoMessageSendPreprocessor new];
    }

    if ([content isKindOfClass:ACGIFMessage.class]) {
        return [ACGifMessageSendPreprocessor new];
    }

    if ([content isKindOfClass:ACHQVoiceMessage.class]) {
        return [ACHQVoiceMessageSendPreprocessor new];
    }

    if ([content isKindOfClass:ACMediaMessageContent.class]) {
        return [ACGenericMediaMessageSendPreprocessor new];
    }
    return nil;
}

- (void)saveSendingRecords:(NSArray *)arr {
    [NSKeyedArchiver archiveRootObject:arr toFile:[ACFileManager getUserArchiverFilePath:@"SendingRecords"]];
}

- (NSArray *)getSenddingRecords {
    return [NSKeyedUnarchiver unarchiveObjectWithFile:[ACFileManager getUserArchiverFilePath:@"SendingRecords"]];
}

- (NSMutableArray *)sendingRecordArr {
    if (!_sendingRecordArr) {
        _sendingRecordArr = [NSMutableArray array];
    }

    return _sendingRecordArr;
}

@end
