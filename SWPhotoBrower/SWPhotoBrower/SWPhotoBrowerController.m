//
//  SWPhotoBrowerController.m
//  Demo
//
//  Created by 周少文 on 16/8/20.
//  Copyright © 2016年 YiXi. All rights reserved.
//

#import "SWPhotoBrowerController.h"
#import "SWPhotoBrowerCell.h"
#import <SDImageCache.h>

NSTimeInterval const SWPhotoBrowerAnimationDuration = 0.3f;

@interface SWPhotoBrowerController ()<UICollectionViewDelegate,UICollectionViewDataSource>
{
    UIInterfaceOrientation _originalOrientation;//记录之前的旋转状态
    BOOL _isPresented;
    BOOL _flag;
    __weak id _observer;
    UIImageView *_originalImageView;//用来保存小图
}

//当前图片的索引
@property (nonatomic) NSInteger index;
@property (nonatomic,strong) UIImageView *tempImageView;
@property (nonatomic,strong) UICollectionView *collectionView;
@property (nonatomic) SWPhotoBrowerControllerStatus photoBrowerControllerStatus;

@end

@implementation SWPhotoBrowerController

- (instancetype)initWithIndex:(NSInteger)index delegate:(id<SWPhotoBrowerControllerDelegate>)delegate normalImageUrls:(NSArray<NSURL *> *)normalImageUrls bigImageUrls:(NSArray<NSURL *> *)bigImageUrls browerPresentingViewController:(UIViewController *)browerPresentingViewController
{
    self = [super initWithNibName:nil bundle:nil];
    if(self)
    {
        NSAssert(browerPresentingViewController != nil, @"browerPresentingViewController不能为nil");
        _browerPresentingViewController = browerPresentingViewController;
        //保存原来的屏幕旋转状态
        _originalOrientation = [[browerPresentingViewController valueForKey:@"interfaceOrientation"] integerValue];
        self.delegate = delegate;
        _index = index;
        _normalImageUrls = normalImageUrls;
        _bigImageUrls = bigImageUrls ? bigImageUrls : normalImageUrls;
        
        NSAssert(_delegate != nil, @"SWPhotoBrowerControllerDelegate不能为空");
        NSAssert([_delegate respondsToSelector:@selector(photoBrowerControllerOriginalImageView:withIndex:)], @"photoBrowerControllerOriginalImageView:withIndex:代理方法必须实现");
        //获取小图
        _originalImageView =  [_delegate photoBrowerControllerOriginalImageView:self withIndex:self.index];
        _normalImageViewSize = _originalImageView.frame.size;
        __weak typeof(self) weakSelf = self;
        _observer = [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceOrientationDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            if(!weakSelf.isViewLoaded) return;
            [weakSelf.collectionView reloadData];
            [weakSelf.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:weakSelf.index inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
        }];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupUI];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if(_isPresented)
        return;
    _isPresented = YES;
    [self doPhotoShowAnimation];
}

- (void)setupUI
{
    UICollectionViewFlowLayout *flow = [[UICollectionViewFlowLayout alloc] init];
    flow.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width+16, self.view.frame.size.height) collectionViewLayout:flow];
#ifdef __IPHONE_11_0
    if([_collectionView respondsToSelector:@selector(setContentInsetAdjustmentBehavior:)]){
        _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
#endif
    _collectionView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    flow.minimumLineSpacing = 0;
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.showsHorizontalScrollIndicator = NO;
    _collectionView.showsVerticalScrollIndicator = NO;
    _collectionView.pagingEnabled = YES;
    _collectionView.backgroundColor = [UIColor clearColor];
    //一开始先隐藏浏览器,做法放大动画再显示
    _collectionView.hidden = YES;
    [_collectionView registerClass:[SWPhotoBrowerCell class] forCellWithReuseIdentifier:@"cell"];
    [self.view addSubview:_collectionView];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    UICollectionViewFlowLayout *flow = (UICollectionViewFlowLayout *)_collectionView.collectionViewLayout;
    flow.itemSize = CGSizeMake(self.view.frame.size.width+16, self.view.frame.size.height);
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    if(_flag)
        return;
    [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:_index inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:false];
    _flag = YES;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.bigImageUrls.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SWPhotoBrowerCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.browerVC = self;
    //先设置小图
    cell.normalImageUrl = self.normalImageUrls[indexPath.row];
    //后设置大图
    cell.bigImageUrl = self.bigImageUrls[indexPath.row];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(SWPhotoBrowerCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray<NSIndexPath *> *visibleIndexPaths = [collectionView indexPathsForVisibleItems];
    if(visibleIndexPaths.lastObject.item != indexPath.item){
        [cell.scrollView setZoomScale:1.0f animated:NO];
    }
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    NSInteger index = ABS(targetContentOffset->x/self.view.frame.size.width);
    self.index = index;
    UIImageView *imageView = [_delegate photoBrowerControllerOriginalImageView:self withIndex:index];
    _normalImageViewSize = imageView.frame.size;
}

//隐藏状态栏
- (BOOL)prefersStatusBarHidden
{
    if([self isIPhoneX]) return NO;
    return YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if([self isIPhoneX]) return UIStatusBarStyleLightContent;
    return UIStatusBarStyleDefault;
}

- (BOOL)isIPhoneX {
    static BOOL flag;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if([UIScreen mainScreen].bounds.size.width == 375 && [UIScreen mainScreen].bounds.size.height == 812) {
            flag = YES;
        }
    });
    return flag;
}

//用于创建一个和当前点击图片一模一样的imageView
- (UIImageView *)tempImageView
{
    if(!_tempImageView)
    {
        _tempImageView = [[UIImageView alloc] init];
        _tempImageView.contentMode = UIViewContentModeScaleAspectFill;
        _tempImageView.clipsToBounds = YES;
    }
    
    return _tempImageView;
}

- (void)doPhotoShowAnimation
{
    NSURL *imageUrl = _bigImageUrls[_index];
    //从缓存中获取大图
    UIImage *image = [[SDImageCache sharedImageCache] imageFromCacheForKey:imageUrl.absoluteString];
    if(image == nil){
        NSURL *normalImgUrl = _normalImageUrls[_index];
        image = [[SDImageCache sharedImageCache] imageFromCacheForKey:normalImgUrl.absoluteString];
        if(image == nil){
            self.view.backgroundColor = [UIColor blackColor];
            _collectionView.hidden = NO;
            return;
        }
    }
    //获取转换之后的坐标
    CGRect convertFrame = [_originalImageView.superview convertRect:_originalImageView.frame toCoordinateSpace:[UIScreen mainScreen].coordinateSpace];
    self.tempImageView.frame = convertFrame;
    self.tempImageView.image = image;
    [self.view addSubview:self.tempImageView];
    //计算临时图片放大之后的frame
    CGRect toFrame = [self getTempImageViewFrameWithImage:image];
    [UIView animateWithDuration:SWPhotoBrowerAnimationDuration delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.tempImageView.frame = toFrame;
        self.view.backgroundColor = [UIColor blackColor];
        //更新状态栏
        [self setNeedsStatusBarAppearanceUpdate];
    } completion:^(BOOL finished) {
        //移除图片
        [self.tempImageView removeFromSuperview];
        //显示图片浏览器
        _collectionView.hidden = NO;
    }];
}

- (void)doPhotoHideAnimation
{
    //获取当前屏幕可见cell的indexPath
    NSIndexPath *visibleIndexPath = _collectionView.indexPathsForVisibleItems.lastObject;
    _index = visibleIndexPath.row;
    if(_delegate && [_delegate respondsToSelector:@selector(photoBrowerControllerWillHide:withIndex:)])
    {
        [_delegate photoBrowerControllerWillHide:self withIndex:_index];
    }
    SWPhotoBrowerCell *cell = (SWPhotoBrowerCell *)[_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:_index inSection:0]];
    self.tempImageView.image = cell.imagView.image;
    CGRect fromRect = [cell.imagView.superview convertRect:cell.imagView.frame toCoordinateSpace:[UIScreen mainScreen].coordinateSpace];
    self.tempImageView.frame = fromRect;
    _collectionView.hidden = YES;
    [self.view addSubview:self.tempImageView];
    UIImageView *imageView = [_delegate photoBrowerControllerOriginalImageView:self withIndex:_index];
    _normalImageViewSize = imageView.frame.size;
    CGRect convertFrame = [imageView.superview convertRect:imageView.frame toCoordinateSpace:[UIScreen mainScreen].coordinateSpace];
    [_collectionView removeFromSuperview];
    self.collectionView.userInteractionEnabled = NO;
    [UIView animateWithDuration:SWPhotoBrowerAnimationDuration delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.tempImageView.frame = convertFrame;
        self.view.backgroundColor = [UIColor clearColor];
        [self setNeedsStatusBarAppearanceUpdate];
        //旋转屏幕至原来的状态
        [[UIDevice currentDevice] setValue:@(_originalOrientation) forKey:@"orientation"];
    } completion:^(BOOL finished) {
        [self hideBrowerController];
    }];
}

- (void)hideBrowerController
{
    self.photoBrowerControllerStatus = SWPhotoBrowerControllerHidingStatus;
    [self dismissViewControllerAnimated:NO completion:^{
        self.photoBrowerControllerStatus = SWPhotoBrowerControllerDidHideStatus;
    }];
}

- (CGRect)getTempImageViewFrameWithImage:(UIImage *)image
{
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat scale = image.size.height/image.size.width;
    CGFloat imageHeight = screenWidth*scale;
    CGFloat inset = 0;
    if(imageHeight<screenHeight)
    {
        inset = (screenHeight - imageHeight)*0.5f;
    }
    return CGRectMake(0, inset, screenWidth, imageHeight);
}

#pragma mark - UIViewControllerTransitioningDelegate
- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source
{
    UIPresentationController *controller = [[UIPresentationController alloc] initWithPresentedViewController:presented presentingViewController:presenting];
    return controller;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    return self;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    return self;
}

#pragma mark - UIViewControllerAnimatedTransitioning
- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return SWPhotoBrowerAnimationDuration;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {

}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (void)showBrower {
    if(self.photoBrowerControllerStatus != SWPhotoBrowerControllerUnShowStatus) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setValue:@(SWPhotoBrowerControllerShowingStatus) forKey:@"photoBrowerControllerStatus"];
        self.transitioningDelegate = self;
        self.modalPresentationStyle = UIModalPresentationCustom;
        [self.browerPresentingViewController presentViewController:self animated:NO completion:^{
            [self setValue:@(SWPhotoBrowerControllerDidShowStatus) forKey:@"photoBrowerControllerStatus"];
        }];
    });
}

- (void)dealloc
{
    NSLog(@"%s",__func__);
    [[NSNotificationCenter defaultCenter] removeObserver:_observer];
    _collectionView.delegate = nil;
    _collectionView.dataSource = nil;
}



@end
