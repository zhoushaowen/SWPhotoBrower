//
//  SWPhotoBrowerCell.h
//  Demo
//
//  Created by 周少文 on 16/8/20.
//  Copyright © 2016年 YiXi. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SWPhotoBrowerController;

extern NSString *const SWPhotoBrowerErrorImageIdentifier;

@interface SWPhotoBrowerCell : UICollectionViewCell<UIGestureRecognizerDelegate>

@property (nonatomic,strong) UIScrollView *scrollView;
@property (nonatomic,strong) UIImageView *imagView;
@property (nonatomic,strong) NSURL *bigImageUrl;
@property (nonatomic,readonly,strong) NSURL *normalImageUrl;
@property (nonatomic,weak) SWPhotoBrowerController *browerVC;
- (BOOL)setNormalImageUrl:(NSURL *)normalImageUrl;
- (void)adjustImageViewWithImage:(UIImage *)image;

@end
