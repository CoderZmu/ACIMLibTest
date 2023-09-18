//
//  UIViewController+ACTop.h
//  SPVCBase_Example
//
//  Created by 子木 on 2019/11/18.
//  
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (ACTop)

+ (UIViewController *)ac_topViewController;

+ (UIViewController *)ac_topViewControllerOf:(UIViewController *)viewController;
@end

NS_ASSUME_NONNULL_END
