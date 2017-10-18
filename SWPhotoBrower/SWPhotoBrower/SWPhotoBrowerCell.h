//
//  SWPhotoBrowerCell.h
//  Demo
//
//  Created by 周少文 on 16/8/20.
//  Copyright © 2016年 YiXi. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SWPhotoBrowerController;

@interface SWPhotoBrowerCell : UICollectionViewCell

@property (nonatomic,strong) UIScrollView *scrollView;
@property (nonatomic,strong) UIImageView *imagView;
@property (nonatomic,strong) NSURL *bigImageUrl;
@property (nonatomic,strong) NSURL *normalImageUrl;
@property (nonatomic,weak) SWPhotoBrowerController *browerVC;


@end
