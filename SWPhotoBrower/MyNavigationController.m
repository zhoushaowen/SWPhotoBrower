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

- (UIViewController *)childViewControllerForStatusBarHidden {
    return nil;
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return nil;
}

- (BOOL)prefersStatusBarHidden {
    return self.visibleViewController.prefersStatusBarHidden;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.visibleViewController.preferredStatusBarStyle;
}


@end
