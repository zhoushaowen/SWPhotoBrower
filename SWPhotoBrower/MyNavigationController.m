//
//  MyNavigationController.m
//  SWPhotoBrower
//
//  Created by zhoushaowen on 2017/10/18.
//  Copyright © 2017年 Yidu. All rights reserved.
//

#import "MyNavigationController.h"
#import "SWPhotoBrowerController.h"

@interface MyNavigationController ()

@end

@implementation MyNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (BOOL)prefersStatusBarHidden {
    if([self.visibleViewController isKindOfClass:[SWPhotoBrowerController class]]){
        SWPhotoBrowerController *browerVC = (SWPhotoBrowerController *)self.visibleViewController;
        if(browerVC.photoBrowerControllerStatus == SWPhotoBrowerControllerHidingStatus || browerVC.photoBrowerControllerStatus == SWPhotoBrowerControllerHidingStatus){
            return NO;
        }
    }
    return self.visibleViewController.prefersStatusBarHidden;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    if([self.visibleViewController isKindOfClass:[SWPhotoBrowerController class]]){
        SWPhotoBrowerController *browerVC = (SWPhotoBrowerController *)self.visibleViewController;
        if(browerVC.photoBrowerControllerStatus == SWPhotoBrowerControllerHidingStatus || browerVC.photoBrowerControllerStatus == SWPhotoBrowerControllerDidHideStatus){
            return UIStatusBarStyleDefault;
        }
    }
    return self.visibleViewController.preferredStatusBarStyle;
}


@end
