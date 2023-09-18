//
//  ACConversationListFetcher.m
//  ACIMLib
//
//  Created by 子木 on 2022/9/1.
//

#import "ACConversationListFetcher.h"
#import "ACDialogIdConverter.h"
#import "ACDialogManager.h"
#import "ACDialogMo+Adapter.h"

typedef NS_ENUM(NSUInteger, ACDialogQueryType) {
    ACDialogQueryType_Private = 1,
    ACDialogQueryType_Group = 2,
    ACDialogQueryType_All = 3,
};


@implementation ACConversationListFetcher


- (NSArray *)getConversationList:(NSArray *)conversationTypeList {
    return [self getConversationList:conversationTypeList count:-1 startTime:0];
}

- (NSArray *)getConversationList:(NSArray *)conversationTypeList count:(int)count startTime:(long long)startTime {
    if (!conversationTypeList.count) return @[];

    NSArray *allDialogList = [self getDialogList];
    NSArray *filterDialogList = [self filter:allDialogList withFilterConversationTypes:conversationTypeList];

    if (count <= 0) {
        return [self toConversationList:filterDialogList];
    }
        
    if (startTime <= 0) {
        return [self toConversationList:[filterDialogList subarrayWithRange:NSMakeRange(0, MIN(count, filterDialogList.count))]];
    }
    
    // 传递的startTime > 0，忽略置顶的会话
    NSInteger begin = [self findIndexOfUpdateTimeGreaterThenTargetTime:startTime beginIndex:[self lastNotOnTopDialogIndexForDialogList:filterDialogList] forDialogList:filterDialogList];
    if (begin == -1) return @[];
    
    return  [self toConversationList: [filterDialogList subarrayWithRange:NSMakeRange(begin, MIN(count, filterDialogList.count  - begin))]];
}

- (NSArray<ACConversation *> *)getTopConversationList:(NSArray *)conversationTypeList {
    if (!conversationTypeList.count) return @[];
    
    NSArray *dialogList = [self filterTopDialogList:[self filter:[self getDialogList] withFilterConversationTypes:conversationTypeList]];
    
    return [self toConversationList:dialogList];
}

- (NSArray<ACConversation *> *)getBlockedConversationList:(NSArray *)conversationTypeList {
    if (!conversationTypeList.count) return @[];
    
    NSArray *dialogList = [self filterBlockedDialogList:[self filter:[self getDialogList] withFilterConversationTypes:conversationTypeList]];
    return [self toConversationList:dialogList];
}


- (NSArray *)filter:(NSArray *)originalDialogList withFilterConversationTypes:(NSArray *)conversationTypes {
    if (!conversationTypes.count) return @[];
    
    NSSet *requestTypes = [[NSSet alloc] initWithArray:conversationTypes];
    NSSet *supportTypes = [self supportedConversationTypes];
    
    BOOL isAllConType = [supportTypes isSubsetOfSet:requestTypes];
    if (isAllConType) {
        return originalDialogList;
    }
    
    NSMutableArray *contentArr = [NSMutableArray array];
    for (ACDialogMo *dialog in originalDialogList) {
        ACConversationTypeTargetInfo *info = [ACDialogIdConverter getRCConversationInfoWithDialogId:dialog.Property_ACDialogs_dialogId];
        if (info && [conversationTypes containsObject:@(info.type)]) {
            [contentArr addObject:dialog];
        }
    }
    
    return contentArr.copy;
    
}

- (NSArray *)filterTopDialogList:(NSArray<ACDialogMo *> *)originalDialogList{
    NSMutableArray *retArray = [NSMutableArray array];
    NSInteger i = 0;
    while (i < originalDialogList.count && originalDialogList[i].Property_ACDialogs_stickyFlag) {
        [retArray addObject:originalDialogList[i]];
        i++;
    }
    return [retArray copy];
    
}

- (NSArray *)filterBlockedDialogList:(NSArray *)originalDialogList{
    
    NSString *predicateString = [NSString stringWithFormat:@"%@ == %d", [ACDialogMo loadProperty_ACDialogs_muteFlagKey], YES];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateString];
    return [originalDialogList filteredArrayUsingPredicate:predicate];
    
}

- (NSInteger)lastNotOnTopDialogIndexForDialogList:(NSArray<ACDialogMo *> *)dialogList {
    NSInteger index = 0;
    while (index < dialogList.count && dialogList[index].Property_ACDialogs_stickyFlag) {
        index++;
    }
    return index;
}

- (NSInteger)findIndexOfUpdateTimeGreaterThenTargetTime:(long)targetTime beginIndex:(NSInteger)beginIndex forDialogList:(NSArray<ACDialogMo *> *)dialogList {
    if (dialogList.count == 0) return -1;
    NSInteger left = beginIndex, right = dialogList.count; // [left, right)
    
    while (left < right) {
        NSInteger mid = (left + right) / 2;
        long updateTime = dialogList[mid].Property_ACDialogs_updateTime;
        if (updateTime == targetTime) {
            left = mid + 1;
        } else if (updateTime < targetTime) {
            right = mid;
        } else if (updateTime > targetTime) {
            left = mid + 1;
        }
    }
    return left >= dialogList.count ? -1 : left;
}

- (NSArray *)toConversationList:(NSArray *)dialogList {
    NSMutableArray *retArray = [NSMutableArray array];
    for (ACDialogMo *dialogMo in dialogList) {
        [retArray addObject:[dialogMo toRCConversation]];
    }
    return [retArray copy];
}

- (NSArray *)getDialogList {
    return [[ACDialogManager sharedDialogManger] getDialogList];
}

- (NSSet *)supportedConversationTypes {
    return [[NSSet alloc] initWithArray:@[@(ConversationType_PRIVATE), @(ConversationType_GROUP)]];
}

- (ACDialogQueryType)dialogQueryTypeForConversationTypeList:(NSArray *)conversationTypeList {
    NSSet *requestTypes = [[NSSet alloc] initWithArray:conversationTypeList];
    NSSet *supportTypes = [self supportedConversationTypes];
    BOOL isAllConType = [supportTypes isSubsetOfSet:requestTypes];
    ACDialogQueryType type = isAllConType ? ACDialogQueryType_All : [conversationTypeList[0] integerValue] == ACDialogType_PRIVATE ? ACDialogQueryType_Private : ACDialogQueryType_Group;
    
    return type;
}

@end
