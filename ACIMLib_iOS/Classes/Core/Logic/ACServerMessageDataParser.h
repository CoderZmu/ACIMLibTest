//
//  ACServerMessageDataParser.h
//  ACIMLib
//
//  Created by 子木 on 2022/8/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ACPBDialogMessageList, ACMessageMo;
@interface ACServerMessageDataParser : NSObject

- (void)parse:(NSDictionary<NSString*, ACPBDialogMessageList*> *)orginalMsgs callback:(void(^)(BOOL done, NSDictionary<NSString *, NSArray<ACMessageMo *> *> *msgMaps))callback;

@end

NS_ASSUME_NONNULL_END
