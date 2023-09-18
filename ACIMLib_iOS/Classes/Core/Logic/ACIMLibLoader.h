//
//  ACIMLib.h
//  ACIMLib
//
//  Created by 子木 on 2022/6/15.
//

#import <Foundation/Foundation.h>
#import "ACBase.h"
#import "ACStatusDefine.h"

NS_ASSUME_NONNULL_BEGIN


typedef void (^IMLibLoaderSuccessBlock)(NSString *userId);
typedef void (^IMLibLoaderErrorBlock)(ACConnectErrorCode errorCode);

@interface ACIMLibLoader : NSObject

ACSingletonH(Loader)

- (void)setServerInfo:(NSString *)imServer;

- (void)setDeviceToken:(NSString *)deviceToken;

- (void)connectWithToken:(NSString *)token
               timeLimit:(int)timeLimit
                dbOpened:(void (^)(BOOL))dbOpenedBlock
                 success:(IMLibLoaderSuccessBlock)successBlock
                   error:(IMLibLoaderErrorBlock)errorBlock;

- (void)disconnect:(BOOL)isReceivePush;

- (ACConnectionStatus)getConnectionStatus;

@end

NS_ASSUME_NONNULL_END
