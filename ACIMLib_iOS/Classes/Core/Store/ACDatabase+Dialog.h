//
//  ACDatabase+Dialog.h
//  ACIMLib
//
//  Created by 子木 on 2022/12/8.
//

#import "ACDatabase.h"

NS_ASSUME_NONNULL_BEGIN


@interface ACDatabase (Dialog)

// 更新指定dialog
- (void)updateDialog:(ACDialogMo *)dialog;
- (void)deleteDialog:(NSString *)dialogId;

- (NSArray *)selectAllDialogs;

@end

NS_ASSUME_NONNULL_END
