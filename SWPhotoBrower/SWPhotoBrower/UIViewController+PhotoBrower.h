//
//  UIViewController+PhotoBrower.h
//  Demo
//
//  Created by 周少文 on 16/8/24.
//  Copyright © 2016年 YiXi. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SWPhotoBrowerController;

@interface UIViewController (PhotoBrower)

////保存是哪个控制器弹出的图片浏览器,解决self.presentingViewController在未present之前取到的值为nil的情况
//@property (nonatomic,weak) UIViewController *browerPresentingViewController;

- (void)showBrower:(SWPhotoBrowerController *)browerController;

@end
