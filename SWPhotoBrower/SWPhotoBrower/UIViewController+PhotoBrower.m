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
    if(browerController.photoBrowerControllerStatus != SWPhotoBrowerControllerUnShowStatus) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        [browerController setValue:@(SWPhotoBrowerControllerShowingStatus) forKey:@"photoBrowerControllerStatus"];
        browerController.transitioningDelegate = browerController;
        browerController.modalPresentationStyle = UIModalPresentationCustom;
        [self presentViewController:browerController animated:NO completion:^{
            [browerController setValue:@(SWPhotoBrowerControllerShowStatus) forKey:@"photoBrowerControllerStatus"];
        }];
    });
}


@end
