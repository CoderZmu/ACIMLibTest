//
//  ACMessageFilter.m
//  ACIMLib
//
//  Created by 子木 on 2022/8/1.
//

#import "ACMessageFilter.h"
#import "ACMessageMo.h"
#import "ACServerTime.h"
#import "ACMessageSerializeSupport.h"
#import "ACMessageManager.h"

static long const kStatusMessageAliveTimeMS = 6000;

@implementation ACMessageFilter

- (NSArray *)filter:(NSArray *)arr  {
    NSMutableArray *contentArr = [NSMutableArray array];
    for (ACMessageMo* message in arr){
      
        // 状态消息
        if ([[ACMessageSerializeSupport shared] isStatusMessage:message.Property_ACMessage_objectName]) {
            if ([ACServerTime getServerMSTime] - message.Property_ACMessage_msgSendTime > kStatusMessageAliveTimeMS) {
                continue;
            }
        }
        
        
        if ([[ACMessageSerializeSupport shared] isSupported:message.Property_ACMessage_objectName]) {
            // 消息能被解析
            [contentArr addObject:message];
        }
        
    }
    
    return [contentArr copy];
}

- (NSArray *)filterSentOutMessages:(NSArray *)arr  {
    NSMutableArray *contentArr = [NSMutableArray array];
    
    [arr enumerateObjectsUsingBlock:^(ACMessageMo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (!obj.Property_ACMessage_isOut) {
            [contentArr addObject:obj];
        }
      
    }];
    
    return contentArr.copy;
}


- (NSArray *)filterUndecodeMessage:(NSArray *)arr {
    
    NSString *predicateString = [NSString stringWithFormat:@"%@ == %d", [ACMessageMo loadMsgProperty_ACMessage_decodeKey], YES];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateString];
    return [arr filteredArrayUsingPredicate:predicate];
    
}


@end
