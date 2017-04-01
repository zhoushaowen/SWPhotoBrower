//
//  UIViewController+PhotoBrower.m
//  Demo
//
//  Created by 周少文 on 16/8/24.
//  Copyright © 2016年 YiXi. All rights reserved.
//

#import "UIViewController+PhotoBrower.h"
#import "SWPhotoBrowerController.h"

@implementation UIViewController (PhotoBrower)

- (void)showBrower:(SWPhotoBrowerController *)browerController
{
    dispatch_async(dispatch_get_main_queue(), ^{
        browerController.transitioningDelegate = browerController;
        browerController.modalPresentationStyle = UIModalPresentationCustom;
        [self presentViewController:browerController animated:NO completion:nil];
    });
}

//- (void)setBrowerPresentingViewController:(UIViewController *)browerPresentingViewController
//{
//    objc_setAssociatedObject(self, &browerPresentingViewController, self, OBJC_ASSOCIATION_ASSIGN);
//}
//
//- (UIViewController *)browerPresentingViewController
//{
//    return objc_getAssociatedObject(self, &BrowerPresentingViewController);
//}


@end
