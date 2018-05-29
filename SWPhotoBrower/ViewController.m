//
//  ViewController.m
//  SWPhotoBrower
//
//  Created by zhoushaowen on 2017/4/1.
//  Copyright © 2017年 Yidu. All rights reserved.
//

#import "ViewController.h"
#import "MyCollectionViewCell.h"
#import <UIImageView+WebCache.h>
#import "SWPhotoBrowerController.h"

static NSString *const Cell = @"cell";

@interface ViewController ()<UICollectionViewDelegate,UICollectionViewDataSource,SWPhotoBrowerControllerDelegate>
{
    UICollectionView *_collectionView;
    NSArray *_dataArray;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _dataArray = @[
                        @"http://ww2.sinaimg.cn/thumbnail/9ecab84ejw1emgd5nd6eaj20c80c8q4a.jpg",
                        @"http://ww2.sinaimg.cn/thumbnail/642beb18gw1ep3629gfm0g206o050b2a.gif",
                        @"http://ww4.sinaimg.cn/thumbnail/9e9cb0c9jw1ep7nlyu8waj20c80kptae.jpg",
                        @"http://ww3.sinaimg.cn/thumbnail/8e88b0c1gw1e9lpr1xydcj20gy0o9q6s.jpg",
                        @"http://ww2.sinaimg.cn/thumbnail/8e88b0c1gw1e9lpr2n1jjj20gy0o9tcc.jpg",
                        @"http://ww4.sinaimg.cn/thumbnail/8e88b0c1gw1e9lpr4nndfj20gy0o9q6i.jpg",
                        @"http://ww3.sinaimg.cn/thumbnail/8e88b0c1gw1e9lpr57tn9j20gy0obn0f.jpg",
                        @"http://ww2.sinaimg.cn/thumbnail/677febf5gw1erma104rhyj20k03dz16y.jpg",
                        @"http://ww4.sinaimg.cn/thumbnail/677febf5gw1erma1g5xd0j20k0esa7wj.jpg"
                        ];
    UICollectionViewFlowLayout *flow = [[UICollectionViewFlowLayout alloc] init];
    flow.itemSize = CGSizeMake(100, 100);
    flow.sectionInset = UIEdgeInsetsMake(20, 20, 20, 20);
    _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:flow];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.backgroundColor = [UIColor whiteColor];
    [_collectionView registerClass:[MyCollectionViewCell class] forCellWithReuseIdentifier:Cell];
    [self.view addSubview:_collectionView];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _dataArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MyCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:Cell forIndexPath:indexPath];
    [cell.imgV sd_setImageWithURL:[NSURL URLWithString:_dataArray[indexPath.item]] placeholderImage:nil];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *normalImageUrls = [NSMutableArray arrayWithCapacity:0];
    NSMutableArray *bigImageUrls = [NSMutableArray arrayWithCapacity:0];
    [_dataArray enumerateObjectsUsingBlock:^(NSString*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [normalImageUrls addObject:[NSURL URLWithString:obj]];
        NSString *str = [obj stringByReplacingOccurrencesOfString:@"thumbnail" withString:@"bmiddle"];
        [bigImageUrls addObject:[NSURL URLWithString:str]];
    }];
    SWPhotoBrowerController *photoBrower = [[SWPhotoBrowerController alloc] initWithIndex:indexPath.item delegate:self normalImageUrls:[normalImageUrls copy] bigImageUrls:[bigImageUrls copy] browerPresentingViewController:self];
//    photoBrower.disablePhotoSave = YES;
    [photoBrower show];
}

#pragma mark - SWPhotoBrowerControllerDelegate
- (UIImageView *)photoBrowerControllerOriginalImageView:(SWPhotoBrowerController *)browerController withIndex:(NSInteger)index {
    //cellForItemAtIndexPath:The cell object at the corresponding index path or nil if the cell is not visible or indexPath is out of range.
    MyCollectionViewCell *cell = (MyCollectionViewCell *)[_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
    return cell.imgV;
}

- (void)photoBrowerControllerWillHide:(SWPhotoBrowerController *)browerController withIndex:(NSInteger)index {
    [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
    //collectionView必须要layoutIfNeeded，否则cellForItemAtIndexPath,有可能获取到的是nil，
    [_collectionView layoutIfNeeded];
}

- (UIImage *)photoBrowerControllerPlaceholderImageForDownloadError:(SWPhotoBrowerController *)browerController {
    return [UIImage imageNamed:@"error"];
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}


@end
