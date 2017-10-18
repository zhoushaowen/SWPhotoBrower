//
//  SWPhotoBrowerCell.m
//  Demo
//
//  Created by 周少文 on 16/8/20.
//  Copyright © 2016年 YiXi. All rights reserved.
//

#import "SWPhotoBrowerCell.h"
#import <UIImageView+WebCache.h>
#import "SWPhotoBrowerController.h"
#import "SWProgressView.h"
#import <SDWebImageManager.h>
#import <MBProgressHUD.h>

@interface SWPhotoBrowerCell ()<UIScrollViewDelegate>
{
    __weak id _observer;
}
@property (nonatomic,strong) SWProgressView *progressView;

@end

@implementation SWPhotoBrowerCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        [self.contentView addSubview:self.scrollView];
        self.imagView = [UIImageView new];
        [self.scrollView addSubview:self.imagView];
        [self.contentView addSubview:self.progressView];
        self.progressView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.progressView attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.progressView attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_progressView(w)]" options:0 metrics:@{@"w":@(self.progressView.frame.size.width)} views:NSDictionaryOfVariableBindings(_progressView)]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_progressView(h)]" options:0 metrics:@{@"h":@(self.progressView.frame.size.height)} views:NSDictionaryOfVariableBindings(_progressView)]];
        __weak typeof(self) weakSelf = self;
        _observer = [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceOrientationDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            [weakSelf.scrollView setZoomScale:1.0f animated:YES];
        }];
    }
    return self;
}

- (UIScrollView *)scrollView
{
    if(!_scrollView)
    {
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.contentView.frame.size.width - 16, self.contentView.frame.size.height)];
        _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _scrollView.delegate = self;
#ifdef __IPHONE_11_0
        if([_scrollView respondsToSelector:@selector(setContentInsetAdjustmentBehavior:)]){
            _scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
#endif
        //单击
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
        singleTap.numberOfTapsRequired = 1;
        [_scrollView addGestureRecognizer:singleTap];
        //双击
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
        doubleTap.numberOfTapsRequired = 2;
        [_scrollView addGestureRecognizer:doubleTap];
        [singleTap requireGestureRecognizerToFail:doubleTap];
        //添加长按手势
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
        [_scrollView addGestureRecognizer:longPress];
    }
    
    return _scrollView;
}

- (SWProgressView *)progressView
{
    if(!_progressView)
    {
        _progressView = [SWProgressView progressView];
    }
    
    return _progressView;
}

- (void)setNormalImageUrl:(NSURL *)normalImageUrl
{
    _normalImageUrl = normalImageUrl;
    self.scrollView.zoomScale = 1.0f;
    UIImage *image = [[SDImageCache sharedImageCache] imageFromCacheForKey:normalImageUrl.absoluteString];
//    self.imagView.image = image;
    CGSize size = _browerVC.normalImageViewSize;
    CGFloat offX = ([UIScreen mainScreen].bounds.size.width - size.width)*0.5f;
    offX = offX<0 ? 0 : offX;
    CGFloat offY = ([UIScreen mainScreen].bounds.size.height - size.height)*0.5f;
    offY = offY<0 ? 0: offY;
//    self.imagView.frame = CGRectMake(0, 0, size.width, size.height);
//    self.scrollView.contentInset = UIEdgeInsetsMake(offY, offX, offY, offX);
//    self.scrollView.contentSize = size;
    [self adjustImageViewWithImage:image];
}

- (void)setBigImageUrl:(NSURL *)bigImageUrl
{
    _bigImageUrl = bigImageUrl;
    //先关闭缩放
    self.scrollView.maximumZoomScale = 1.0f;
    self.scrollView.minimumZoomScale = 1.0f;
    self.progressView.progress = 1.0f;
    //从缓存中取大图
    UIImage *image = [[SDImageCache sharedImageCache] imageFromCacheForKey:bigImageUrl.absoluteString];
    if(image)
    {
        [self adjustImageViewWithImage:image];
        //开启缩放
        self.scrollView.maximumZoomScale = 2.0f;
        self.scrollView.minimumZoomScale = 0.5f;
    }else{
        self.progressView.progress = 0.01;
        __weak typeof(self) weakSelf = self;
        [[SDWebImageManager sharedManager] cancelAll];
        [[SDWebImageManager sharedManager] loadImageWithURL:bigImageUrl options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
            CGFloat proress = receivedSize*1.0f/expectedSize*1.0f;
//            NSLog(@"%f",proress);
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.progressView.progress = proress;
            });
        } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
            if(error) return;
            weakSelf.scrollView.maximumZoomScale = 2.0f;
            weakSelf.scrollView.minimumZoomScale = 0.5f;
            [weakSelf adjustImageViewWithImage:image];
        }];
    }
}

//调整图片尺寸
- (void)adjustImageViewWithImage:(UIImage *)image
{
    self.imagView.image = image;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    if(image == nil){
        self.scrollView.contentInset = UIEdgeInsetsZero;
        self.scrollView.contentSize = CGSizeMake(screenWidth, screenHeight);
        return;
    }
    CGFloat scale = image.size.height/image.size.width;
    CGFloat imageHeight = screenWidth*scale;
    self.imagView.frame = CGRectMake(0, 0, screenWidth, imageHeight);
    if(imageHeight > screenHeight)
    {
        //长图
        self.scrollView.contentInset = UIEdgeInsetsZero;
    }else{
        //短图
        CGFloat inset = (screenHeight - imageHeight) * 0.5f;
        self.scrollView.contentInset = UIEdgeInsetsMake(inset, 0, inset, 0);
    }
    self.scrollView.contentSize = CGSizeMake(screenWidth, imageHeight);
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imagView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat offX = (screenWidth - self.imagView.frame.size.width)*0.5;
    CGFloat offY = (screenHeight - self.imagView.frame.size.height)*0.5;
    
    offX = offX<0 ? 0:offX;
    offY = offY<0 ? 0:offY;
    self.scrollView.contentInset = UIEdgeInsetsMake(offY, offX, offY, offX);
}

- (void)doubleTap:(UITapGestureRecognizer *)gesture
{
    if(self.scrollView.zoomScale == 1.0f)
    {
        CGPoint point = [gesture locationInView:self.imagView];
        [self.scrollView zoomToRect:CGRectMake(point.x, point.y, 1, 1) animated:YES];

    }else{
        [self.scrollView setZoomScale:1.0f animated:YES];
    }
}

- (void)singleTap:(UITapGestureRecognizer *)gesture
{
    [_browerVC performSelectorOnMainThread:NSSelectorFromString(@"doPhotoHideAnimation") withObject:nil waitUntilDone:YES];
}

- (void)longPress:(UILongPressGestureRecognizer *)gesture
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"保存图片" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if(self.imagView.image)
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                UIImageWriteToSavedPhotosAlbum(self.imagView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
            });
        }
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self.browerVC presentViewController:alert animated:YES completion:nil];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    NSString *msg = nil;
    if(error)
    {
        msg = @"保存失败";
    }else{
        msg = @"保存成功";
    }
    [self showHUDWithMessage:msg];
}

- (void)showHUDWithMessage:(NSString *)msg {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.browerVC.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.label.text = msg;
    [hud hideAnimated:YES afterDelay:1.0f];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:_observer];
    self.scrollView.delegate = nil;
}



@end
