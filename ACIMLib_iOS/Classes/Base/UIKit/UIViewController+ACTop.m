//
//  UIViewController+SPTop.m
//  SPVCBase_Example
//
//  Created by 子木 on 2019/11/18.
//  
//

#import "UIViewController+ACTop.h"

@implementation UIViewController (ACTop)

+ (UIApplication *)sharedApplication {
    return [UIApplication sharedApplication];
}

+ (UIViewController *)ac_topViewController {
    NSArray *windows = [self sharedApplication].windows;
    if (!windows) {
        return nil;
    }
    UIViewController *rootViewController;
    for (UIWindow *window in windows) {
        if (window.rootViewController) {
            rootViewController = window.rootViewController;
            break;
        }
    }
   
    return [self ac_topViewControllerOf:rootViewController];
}

+ (UIViewController *)ac_topViewControllerOf:(UIViewController *)viewController {
    UIViewController *presentedViewController = viewController.presentedViewController;
    if (presentedViewController) {
        return [self ac_topViewControllerOf:presentedViewController];
    }
 
    if ([viewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabBarController = (UITabBarController *)viewController;
        UIViewController *selectedViewController = tabBarController.selectedViewController;
        if (selectedViewController) {
            return [self ac_topViewControllerOf:selectedViewController];
        }
    }
    
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)viewController;
        UIViewController *visibleViewController = navigationController.visibleViewController;
        if (visibleViewController) {
            return [self ac_topViewControllerOf:visibleViewController];
        }
    }

    
    for (UIView *subView in [[viewController.view.subviews reverseObjectEnumerator] allObjects]) {
        UIResponder *responder = subView.nextResponder;
        if (responder && [responder isKindOfClass:[UIViewController class]]) {
            UIViewController *childViewController = (UIViewController *)responder;
            return [self ac_topViewControllerOf:childViewController];
        }
    }
    
    return viewController;
}

@end
