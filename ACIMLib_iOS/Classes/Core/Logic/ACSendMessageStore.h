//
//  ACSendMessageStore.h
//  ACIMLib
//
//  Created by 子木 on 2022/11/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACSendMessageStore : NSObject

+ (ACSendMessageStore *)shared;
- (void)addMessage:(long)messageId;
- (void)remove:(long)messageId;
- (BOOL)has:(long)messageId;
@end

NS_ASSUME_NONNULL_END
