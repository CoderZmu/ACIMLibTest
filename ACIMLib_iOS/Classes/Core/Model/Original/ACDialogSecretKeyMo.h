//
//  ACDialogSecretKeyMo.h
//  ACIMLib
//
//  Created by 子木 on 2022/9/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACDialogSecretKeyMo : NSObject

@property(nonatomic, copy) NSString *aesKey;

@property(nonatomic, copy) NSString *aesIv;
@end

NS_ASSUME_NONNULL_END
