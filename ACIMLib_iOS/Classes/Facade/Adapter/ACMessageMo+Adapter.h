//
//  ACMessageMo+Bridge.h
//  ACIMLib
//
//  Created by 子木 on 2022/6/20.
//

#import "ACMessageMo.h"
#import "ACMessage.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACMessageMo (Adapter)

- (ACMessage *)toRCMessage;
- (void)setMessageStatusWithRCSentStatus:(ACSentStatus)sentStatus;
- (void)setMessageStatusWithRCReceiveStatus:(ACReceivedStatus)receivedStatus;
@end

NS_ASSUME_NONNULL_END
