//
//  MyCollectionViewCell.m
//  SWPhotoBrower
//
//  Created by zhoushaowen on 2017/8/23.
//  Copyright © 2017年 Yidu. All rights reserved.
//

#import "MyCollectionViewCell.h"

@implementation MyCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self){
        self.contentView.backgroundColor = [UIColor blackColor];
        _imgV = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
        _imgV.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _imgV.contentMode = UIViewContentModeScaleAspectFill;
        _imgV.clipsToBounds = YES;
        [self.contentView addSubview:_imgV];
    }
    return self;
}

@end
