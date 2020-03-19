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
#import <SDImageCache.h>
#import <MBProgressHUD.h>
#import "SWShortTapGestureRecognizer.h"

NSString *const SWPhotoBrowerErrorImageIdentifier = @"SWPhotoBrowerErrorImageIdentifier";

@interface SWPhotoBrowerCell ()<UIScrollViewDelegate>
{
    __weak id _observer;
    UILongPressGestureRecognizer *_longPress;
}
@property (nonatomic,strong) SWProgressView *progressView;
@property (nonatomic) UIDeviceOrientation currentOrientation;

@end

@implementation SWPhotoBrowerCell

@synthesize normalImageUrl = _normalImageUrl;

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
        self.currentOrientation = [UIDevice currentDevice].orientation;
        __weak typeof(self) weakSelf = self;
        _observer = [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceOrientationDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            if([UIDevice currentDevice].orientation == weakSelf.currentOrientation) return;
            weakSelf.currentOrientation = [UIDevice currentDevice].orientation;
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
        SWShortTapGestureRecognizer *doubleTap = [[SWShortTapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
        doubleTap.numberOfTapsRequired = 2;
        [_scrollView addGestureRecognizer:doubleTap];
        [singleTap requireGestureRecognizerToFail:doubleTap];
        //添加长按手势
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
        longPress.delegate = self;
        _longPress = longPress;
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

- (BOOL)setNormalImageUrl:(NSURL *)normalImageUrl
{
    _normalImageUrl = normalImageUrl;
    self.scrollView.zoomScale = 1.0f;
    UIImage *image = [[SDImageCache sharedImageCache] imageFromCacheForKey:normalImageUrl.absoluteString];
    CGSize size = _browerVC.normalImageViewSize;
    CGFloat offX = ([UIScreen mainScreen].bounds.size.width - size.width)*0.5f;
    offX = offX < 0 ? 0 : offX;
    CGFloat offY = ([UIScreen mainScreen].bounds.size.height - size.height)*0.5f;
    offY = offY < 0 ? 0 : offY;
    [self adjustImageViewWithImage:image];
    return image != nil;
}

- (void)setBigImageUrl:(NSURL *)bigImageUrl
{
    _bigImageUrl = bigImageUrl;
    //先关闭缩放
    self.scrollView.maximumZoomScale = 1.0f;
    self.progressView.progress = 1.0f;
    //从缓存中取大图
    UIImage *image = [[SDImageCache sharedImageCache] imageFromCacheForKey:bigImageUrl.absoluteString];
    if(image)
    {
        [self adjustImageViewWithImage:image];
        //开启缩放
        self.scrollView.maximumZoomScale = 2.0f;
    }else{
        self.progressView.progress = 0.0;
        [MBProgressHUD hideHUDForView:self.browerVC.view animated:NO];
        __weak typeof(self) weakSelf = self;
        [[SDWebImageManager sharedManager] cancelAll];
        [[SDWebImageManager sharedManager] loadImageWithURL:bigImageUrl options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
            CGFloat proress = receivedSize*1.0f/expectedSize*1.0f;
//            NSLog(@"%f",proress);
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.progressView.progress = proress;
            });
        } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
            if(error){
//                [weakSelf showHUDWithMessage:@"无法加载图片" imageName:@"TipViewErrorIcon"];
//                NSLog(@"------%@",imageURL);
                if(![weakSelf setNormalImageUrl:weakSelf.normalImageUrl]){
                    if(weakSelf.browerVC.delegate && [weakSelf.browerVC.delegate respondsToSelector:@selector(photoBrowerControllerPlaceholderImageForDownloadError:)]){
                        image = [weakSelf.browerVC.delegate photoBrowerControllerPlaceholderImageForDownloadError:weakSelf.browerVC];
                    }else{
                        NSString *path = [[NSBundle mainBundle] pathForResource:@"SWPhotoBrower.bundle" ofType:nil];
                        path = [path stringByAppendingPathComponent:@"preview_image_failure"];
                        image = [UIImage imageWithContentsOfFile:path];
                    }
                    image.accessibilityIdentifier = SWPhotoBrowerErrorImageIdentifier;
                    [weakSelf adjustImageViewWithImage:image];
                }
            }else{
                weakSelf.scrollView.maximumZoomScale = 2.0f;
                [weakSelf adjustImageViewWithImage:image];
            }
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
    self.imagView.frame = [image.accessibilityIdentifier isEqualToString:SWPhotoBrowerErrorImageIdentifier]?CGRectMake((screenWidth - image.size.width)/2.0f, (screenHeight - image.size.height)/2.0f, image.size.width, image.size.height):CGRectMake(0, 0, screenWidth, imageHeight);
    if([image.accessibilityIdentifier isEqualToString:SWPhotoBrowerErrorImageIdentifier]){
        self.scrollView.contentInset = UIEdgeInsetsZero;
    }else{
        if(imageHeight > screenHeight)
        {
            //长图
            self.scrollView.contentInset = UIEdgeInsetsZero;
        }else{
            //短图
            CGFloat inset = (screenHeight - imageHeight) * 0.5f;
            self.scrollView.contentInset = UIEdgeInsetsMake(inset, 0, inset, 0);
        }
    }
    self.scrollView.contentSize = [image.accessibilityIdentifier isEqualToString:SWPhotoBrowerErrorImageIdentifier]?CGSizeZero: CGSizeMake(screenWidth, imageHeight);
}

#pragma mark - UIScrollViewDelegate
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
    if(gesture.state != UIGestureRecognizerStateEnded) return;
    if(self.scrollView.zoomScale == 1.0f)
    {
        //如果是失败图片禁止缩放
        if([self.imagView.image.accessibilityIdentifier isEqualToString:SWPhotoBrowerErrorImageIdentifier]) return;
        CGPoint point = [gesture locationInView:self.imagView];
        [self.scrollView zoomToRect:CGRectMake(point.x, point.y, 1, 1) animated:YES];

    }else{
        [self.scrollView setZoomScale:1.0f animated:YES];
    }
}

- (void)singleTap:(UITapGestureRecognizer *)gesture
{
    if(gesture.state != UIGestureRecognizerStateEnded) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:_browerVC.view animated:NO];
        [_browerVC dismissViewControllerAnimated:YES completion:nil];
    });
}

- (void)longPress:(UILongPressGestureRecognizer *)gesture
{
    if(gesture.state != UIGestureRecognizerStateBegan) return;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"保存图片" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if(self.imagView.image)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIImageWriteToSavedPhotosAlbum(self.imagView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
            });
        }
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self.browerVC presentViewController:alert animated:YES completion:nil];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if(error)
    {
        [self showHUDWithMessage:@"保存失败" imageName:@"TipViewErrorIcon"];
    }else{
        [self showHUDWithMessage:@"保存成功" imageName:@"icon_success"];
    }
}

- (void)showHUDWithMessage:(NSString *)msg {
    [MBProgressHUD hideHUDForView:self.browerVC.view animated:YES];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.browerVC.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.label.text = msg;
    hud.userInteractionEnabled = NO;
    [hud hideAnimated:YES afterDelay:2.0f];
}

- (void)showHUDWithMessage:(NSString *)msg imageName:(NSString *)imageName {
    [MBProgressHUD hideHUDForView:self.contentView animated:NO];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.contentView animated:YES];
    hud.mode = MBProgressHUDModeCustomView;
    hud.label.text = msg;
    hud.label.font = [UIFont systemFontOfSize:15];
    hud.contentColor = [UIColor whiteColor];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"SWPhotoBrower.bundle" ofType:nil];
    path = [path stringByAppendingPathComponent:imageName];
    hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:path]];
    hud.userInteractionEnabled = NO;
    hud.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
    hud.backgroundView.style = MBProgressHUDBackgroundStyleSolidColor;
    hud.bezelView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
    hud.square = YES;//强制让hud的宽高相等
    [hud hideAnimated:YES afterDelay:2.0f];
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if(gestureRecognizer == _longPress &&
       ![[SDImageCache sharedImageCache] imageFromCacheForKey:self.browerVC.bigImageUrls[self.browerVC.index].absoluteString] &&
       ![[SDImageCache sharedImageCache] imageFromCacheForKey:self.browerVC.normalImageUrls[self.browerVC.index].absoluteString]){
           return NO;
    }
    if(gestureRecognizer == _longPress) return !self.browerVC.disablePhotoSave;
    return YES;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:_observer];
    self.scrollView.delegate = nil;
}



@end
