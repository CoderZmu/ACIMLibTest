//
//  ACDialogMo+Bridge.h
//  ACIMLib
//
//  Created by 子木 on 2022/6/20.
//

#import "ACDialogMo.h"
#import "ACConversation.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACDialogMo (Adapter)

- (ACConversation *)toRCConversation;
@end

NS_ASSUME_NONNULL_END
