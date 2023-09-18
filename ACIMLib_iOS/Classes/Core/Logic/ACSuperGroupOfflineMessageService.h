//
//  ACSuperGroupOfflineMessageService.h
//  ACIMLib
//
//  Created by 子木 on 2022/8/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACSuperGroupOfflineMessageService : NSObject

+ (ACSuperGroupOfflineMessageService *)shared;
- (BOOL)isOfflineMessagesLoaded;
@end


typedef void (^ACGetSuperGroupOfflineMessageSuccessBlock)(void);
typedef void (^ACGetSuperGroupOfflineMessageErrorBlock)(void);

@interface ACGetSuperGroupOfflineMessageOperation: NSOperation

- (void)setSuccessBlock:(ACGetSuperGroupOfflineMessageSuccessBlock)successBlock errorBlock:(ACGetSuperGroupOfflineMessageErrorBlock)errorBlock;

@end


NS_ASSUME_NONNULL_END
