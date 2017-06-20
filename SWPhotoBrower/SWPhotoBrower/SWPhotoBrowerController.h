//
//  SWPhotoBrowerController.h
//  Demo
//
//  Created by 周少文 on 16/8/20.
//  Copyright © 2016年 YiXi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewController+PhotoBrower.h"

typedef NS_ENUM(NSUInteger, SWPhotoBrowerControllerStatus) {
    SWPhotoBrowerControllerUnShowStatus,//未显示
    SWPhotoBrowerControllerShowingStatus,//正在显示出来
    SWPhotoBrowerControllerShowStatus,//已经显示出来
    SWPhotoBrowerControllerHidingStatus,//正在隐藏
};

@class SWPhotoBrowerController;

@protocol SWPhotoBrowerControllerDelegate <NSObject>

@required
//获取将要缩放的小图
- (UIImageView *)photoBrowerControllerOriginalImageView:(SWPhotoBrowerController *)browerController withIndex:(NSInteger)index;
@optional
//图片浏览器即将消失
- (void)photoBrowerControllerWillHide:(SWPhotoBrowerController *)browerController withIndex:(NSInteger)index;

@end

@interface SWPhotoBrowerController : UIViewController<UIViewControllerTransitioningDelegate>

//保存是哪个控制器弹出的图片浏览器,解决self.presentingViewController在未present之前取到的值为nil的情况
@property (nonatomic,weak,readonly) UIViewController *browerPresentingViewController;

/**
 显示状态
 */
@property (nonatomic,readonly) SWPhotoBrowerControllerStatus photoBrowerControllerStatus;

@property (nonatomic,weak) id<SWPhotoBrowerControllerDelegate> delegate;
//当前图片的索引
@property (nonatomic,readonly) NSInteger index;
//小图url
@property (nonatomic,readonly,strong) NSArray<NSURL *> *normalImageUrls;
//大图url
@property (nonatomic,readonly,strong) NSArray<NSURL *> *bigImageUrls;
//小图的大小
@property (nonatomic,readonly) CGSize normalImageViewSize;
//初始化方法
- (instancetype)initWithIndex:(NSInteger)index delegate:(id<SWPhotoBrowerControllerDelegate>)delegate normalImageUrls:(NSArray<NSURL *> *)normalImageUrls bigImageUrls:(NSArray<NSURL *> *)bigImageUrls browerPresentingViewController:(UIViewController *)browerPresentingViewController;


@end
