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
#import <SDWebImageManager.h>

NSTimeInterval const SWPhotoBrowerAnimationDuration = 0.3f;

@interface SWPhotoBrowerController ()<UICollectionViewDelegate,UICollectionViewDataSource,UIGestureRecognizerDelegate>
{
    UIInterfaceOrientation _originalOrientation;//记录之前的旋转状态
    BOOL _flag;
    __weak id _observer;
    UIImageView *_originalImageView;//用来保存小图
    BOOL _statusBarHidden;
    BOOL _isPresentAnimation;
    UIPanGestureRecognizer *_panGesture;
    __weak UIView *_containerView;
}

//当前图片的索引
@property (nonatomic) NSInteger index;
@property (nonatomic,strong) UIImageView *tempImageView;
@property (nonatomic) SWPhotoBrowerControllerStatus photoBrowerControllerStatus;
@property (nonatomic,strong) UICollectionView *collectionView;
@property (nonatomic) UIDeviceOrientation currentOrientation;

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
        self.currentOrientation = [UIDevice currentDevice].orientation;
        __weak typeof(self) weakSelf = self;
        //warning:在下拉屏幕的时候也会触发UIDeviceOrientationDidChangeNotification,所以如果当前屏幕旋转状态没有改变就不用刷新UI
        _observer = [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceOrientationDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            if(!weakSelf.isViewLoaded) return;
            if([UIDevice currentDevice].orientation == weakSelf.currentOrientation) return;
            weakSelf.currentOrientation = [UIDevice currentDevice].orientation;
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

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.browerPresentingViewController setNeedsStatusBarAppearanceUpdate];
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
    //添加平移手势
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    _panGesture.delegate = self;
    [self.view addGestureRecognizer:_panGesture];
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
    //已知bug：cellForItemAtIndexPath这里的indexPath有可能是乱序，不能在这里进行下载
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(SWPhotoBrowerCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%@",indexPath);
    cell.browerVC = self;
    //先设置小图
    cell.normalImageUrl = self.normalImageUrls[indexPath.row];
    //后设置大图
    cell.bigImageUrl = self.bigImageUrls[indexPath.row];
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
    return _statusBarHidden;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if([self isIPhoneX]) return UIStatusBarStyleLightContent;
    return self.browerPresentingViewController.preferredStatusBarStyle;
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

- (void)doPresentAnimation:(id<UIViewControllerContextTransitioning>)transitionContext
{
    self.photoBrowerControllerStatus = SWPhotoBrowerControllerWillShow;
    UIView *containerView = [transitionContext containerView];
    containerView.backgroundColor = [UIColor blackColor];
    _containerView = containerView;
    UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    toView.backgroundColor = [UIColor clearColor];
    [containerView addSubview:toView];
    NSURL *imageUrl = _bigImageUrls[_index];
    //从缓存中获取大图
    UIImage *image = [[SDImageCache sharedImageCache] imageFromCacheForKey:imageUrl.absoluteString];
    if(image == nil){
        NSURL *normalImgUrl = _normalImageUrls[_index];
        image = [[SDImageCache sharedImageCache] imageFromCacheForKey:normalImgUrl.absoluteString];
        if(image == nil){//小图大图都没有找到
            if(_delegate && [_delegate respondsToSelector:@selector(photoBrowerControllerPlaceholderImageForDownloadError:)]){
                image = [_delegate photoBrowerControllerPlaceholderImageForDownloadError:self];
            }
        }
    }
    //获取转换之后的坐标
    CGRect convertFrame = [_originalImageView.superview convertRect:_originalImageView.frame toCoordinateSpace:[UIScreen mainScreen].coordinateSpace];
    self.tempImageView.frame = convertFrame;
    self.tempImageView.image = image;
    [toView addSubview:self.tempImageView];
    //计算临时图片放大之后的frame
    CGRect toFrame = [self getTempImageViewFrameWithImage:image];
    [UIView animateWithDuration:SWPhotoBrowerAnimationDuration delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.tempImageView.frame = toFrame;
        //更新状态栏,iphoneX不要隐藏状态栏
        if(![self isIPhoneX]){
            _statusBarHidden = YES;
            [self setNeedsStatusBarAppearanceUpdate];
        }
    } completion:^(BOOL finished) {
        //移除图片
        [self.tempImageView removeFromSuperview];
        //显示图片浏览器
        _collectionView.hidden = NO;
        [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
        self.photoBrowerControllerStatus = SWPhotoBrowerControllerDidShow;
    }];
}

- (void)doDismissAnimation:(id<UIViewControllerContextTransitioning>)transitionContext
{
    self.photoBrowerControllerStatus = SWPhotoBrowerControllerWillHide;
    //一定要在获取到imageView的frame之前改变状态栏，否则动画会出现跳一下的现象
    if(![self isIPhoneX]){
        _statusBarHidden = NO;
        [self setNeedsStatusBarAppearanceUpdate];
    }
    //获取当前屏幕可见cell的indexPath
    NSIndexPath *visibleIndexPath = _collectionView.indexPathsForVisibleItems.lastObject;
    _index = visibleIndexPath.item;
    if(_delegate && [_delegate respondsToSelector:@selector(photoBrowerControllerWillHide:withIndex:)])
    {
        [_delegate photoBrowerControllerWillHide:self withIndex:_index];
    }
    SWPhotoBrowerCell *cell = (SWPhotoBrowerCell *)[_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:_index inSection:0]];
    self.tempImageView.image = cell.imagView.image;
    CGRect fromRect = [cell.imagView.superview convertRect:cell.imagView.frame toCoordinateSpace:[UIScreen mainScreen].coordinateSpace];
    self.tempImageView.frame = fromRect;
    _collectionView.hidden = YES;
    UIView *containerView = [transitionContext containerView];
    UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
    [fromView addSubview:self.tempImageView];
    UIImageView *imageView = [_delegate photoBrowerControllerOriginalImageView:self withIndex:_index];
    _normalImageViewSize = imageView.frame.size;
    CGRect convertFrame = [imageView.superview convertRect:imageView.frame toCoordinateSpace:[UIScreen mainScreen].coordinateSpace];
    [UIView animateWithDuration:SWPhotoBrowerAnimationDuration delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.tempImageView.frame = convertFrame;
        containerView.backgroundColor = [UIColor clearColor];
        //旋转屏幕至原来的状态
        [[UIDevice currentDevice] setValue:@(_originalOrientation) forKey:@"orientation"];
    } completion:^(BOOL finished) {
        [fromView removeFromSuperview];
        [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
        self.photoBrowerControllerStatus = SWPhotoBrowerControllerDidHide;
    }];
}

- (CGRect)getTempImageViewFrameWithImage:(UIImage *)image
{
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat scale = 1.0f;
    if(image != nil){
        scale = image.size.height/image.size.width;
    }
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
    _isPresentAnimation = YES;
    return self;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    _isPresentAnimation = NO;
    return self;
}

#pragma mark - UIViewControllerAnimatedTransitioning
- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return SWPhotoBrowerAnimationDuration;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    if(_isPresentAnimation){
        [self doPresentAnimation:transitionContext];
    }else{
        [self doDismissAnimation:transitionContext];
    }
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (void)show {
    if(self.photoBrowerControllerStatus != SWPhotoBrowerControllerUnShow) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.transitioningDelegate = self;
        self.modalPresentationStyle = UIModalPresentationCustom;
        [self.browerPresentingViewController presentViewController:self animated:YES completion:nil];
    });
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    SWPhotoBrowerCell *cell = [[_collectionView visibleCells] firstObject];
    if(cell.scrollView.zoomScale > 1.0f) return NO;
    CGPoint velocity = [_panGesture velocityInView:_panGesture.view];
    if(velocity.y < 0) return NO;//禁止上滑
    return YES;
}

//这个方法返回YES，第一个和第二个互斥时，第二个会失效
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    SWPhotoBrowerCell *cell = [[_collectionView visibleCells] firstObject];
    if(otherGestureRecognizer == cell.scrollView.panGestureRecognizer){
        if(cell.scrollView.contentOffset.y <= 0) return YES;
    }
    return NO;
}


#pragma mark - HandleGesture
- (void)handlePanGesture:(UIPanGestureRecognizer *)panGesture
{
    CGPoint point = [panGesture translationInView:panGesture.view];
    CGPoint velocity = [panGesture velocityInView:panGesture.view];
    SWPhotoBrowerCell *cell = [[_collectionView visibleCells] firstObject];
    switch (panGesture.state) {
        case UIGestureRecognizerStateBegan:
        {
            //更改状态栏
            _statusBarHidden = NO;
            [self setNeedsStatusBarAppearanceUpdate];
            
        }
            break;
            
        case UIGestureRecognizerStateChanged:
        {
            double percent = 1 - fabs(point.y)/self.view.frame.size.height;
            percent = MAX(percent, 0);
            double s = MAX(percent, 0.5);//最低不能缩小原来的0.5倍
            CGAffineTransform translation = CGAffineTransformMakeTranslation(point.x, point.y);
            CGAffineTransform scale = CGAffineTransformMakeScale(s, s);
            //合并两个transform
            CGAffineTransform concatTransform = CGAffineTransformConcat(scale, translation);
            cell.scrollView.transform = concatTransform;
            double alpha = 1.0 - MIN(1.0, point.y/(self.view.frame.size.height/2.0f));
            _containerView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:alpha];
        }
            break;
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        {
            if(fabs(point.y) > 200 || fabs(velocity.y) > 500){
                [self dismissViewControllerAnimated:YES completion:nil];
            }else{
                //恢复图片到原来的属性
                _collectionView.userInteractionEnabled = NO;
                if(![self isIPhoneX]){
                    _statusBarHidden = YES;
                }
                [UIView animateWithDuration:SWPhotoBrowerAnimationDuration delay:0 options:0 animations:^{
                    _containerView.backgroundColor = [UIColor blackColor];
                    cell.scrollView.transform = CGAffineTransformIdentity;
                    [cell adjustImageViewWithImage:cell.imagView.image];
                    [self setNeedsStatusBarAppearanceUpdate];
                } completion:^(BOOL finished) {
                    _collectionView.userInteractionEnabled = YES;
                }];
            }
        }
            break;
            
        default:
            break;
    }
}

- (void)dealloc
{
    NSLog(@"%s",__func__);
    [[SDWebImageManager sharedManager] cancelAll];
    [[NSNotificationCenter defaultCenter] removeObserver:_observer];
    _collectionView.delegate = nil;
    _collectionView.dataSource = nil;
}



@end
