//
//  SWPhotoBrowerController.h
//  Demo
//
//  Created by 周少文 on 16/8/20.
//  Copyright © 2016年 YiXi. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, SWPhotoBrowerControllerStatus) {
    SWPhotoBrowerControllerUnShow,//未显示
    SWPhotoBrowerControllerWillShow,//将要显示出来
    SWPhotoBrowerControllerDidShow,//已经显示出来
    SWPhotoBrowerControllerWillHide,//将要隐藏
    SWPhotoBrowerControllerDidHide,//已经隐藏
};

@class SWPhotoBrowerController;

extern NSTimeInterval const SWPhotoBrowerAnimationDuration;

@protocol SWPhotoBrowerControllerDelegate <NSObject>

@required

/**
 获取将要缩放的小图

 @param browerController 图片浏览器
 @param index 当前图片索引
 @return 原始的小图
 */
- (UIImageView *)photoBrowerControllerOriginalImageView:(SWPhotoBrowerController *)browerController withIndex:(NSInteger)index;
/**
 图片浏览器即将消失

 @param browerController 图片浏览器
 @param index 当前图片索引
 */
- (void)photoBrowerControllerWillHide:(SWPhotoBrowerController *)browerController withIndex:(NSInteger)index;

@optional
/**
 下载失败的占位图

 @param browerController 图片浏览器
 @return 占位图
 */
- (UIImage *)photoBrowerControllerPlaceholderImageForDownloadError:(SWPhotoBrowerController *)browerController;

@end

@interface SWPhotoBrowerController : UIViewController<UIViewControllerTransitioningDelegate,UIViewControllerAnimatedTransitioning>

//保存是哪个控制器弹出的图片浏览器,解决self.presentingViewController在未present之前取到的值为nil的情况
@property (nonatomic,weak,readonly) UIViewController *browerPresentingViewController;
/**
 显示状态
 */
@property (nonatomic,readonly) SWPhotoBrowerControllerStatus photoBrowerControllerStatus;

@property (nonatomic,weak) id<SWPhotoBrowerControllerDelegate> delegate;
/**
 当前图片的索引
 */
@property (nonatomic,readonly) NSInteger index;
/**
 小图url
 */
@property (nonatomic,readonly,strong) NSArray<NSURL *> *normalImageUrls;
/**
 大图url
 */
@property (nonatomic,readonly,strong) NSArray<NSURL *> *bigImageUrls;
/**
 小图的大小
 */
@property (nonatomic,readonly) CGSize normalImageViewSize;
/**
 初始化方法

 @param index 当前图片在数组中的index
 @param delegate delegate
 @param normalImageUrls 小图url数组
 @param bigImageUrls 大图url数组
 @param browerPresentingViewController 在哪个控制器上弹出
 @return 图片浏览器
 */
- (instancetype)initWithIndex:(NSInteger)index delegate:(id<SWPhotoBrowerControllerDelegate>)delegate normalImageUrls:(NSArray<NSURL *> *)normalImageUrls bigImageUrls:(NSArray<NSURL *> *)bigImageUrls browerPresentingViewController:(UIViewController *)browerPresentingViewController;
/**
 显示图片浏览器
 */
- (void)show;

@end
