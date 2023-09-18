//
//  ACGetNewMsgConf.h
//  ACIMLib
//
//  Created by 子木 on 2022/6/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACLetterBox : NSObject


+ (void)setMessageOffSet:(long)offset;
+ (long)getMessageOffSet;

+ (void)setDialogStatusOffSet:(long)offset;
+ (long)getDialogStatusOffSet;

@end

NS_ASSUME_NONNULL_END
