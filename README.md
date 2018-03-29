# SWPhotoBrower
仿微信图片浏览器,支持屏幕旋转,完美适配iPhoneX


##导入方式: pod 'SWPhotoBrower'

gif截图
![1.gif](https://github.com/zhoushaowen/SWPhotoBrower/blob/master/screenshot/1.gif?raw=true)

### 使用方法

##### 初始化图片浏览器
`- (instancetype)initWithIndex:(NSInteger)index delegate:(id<SWPhotoBrowerControllerDelegate>)delegate normalImageUrls:(NSArray<NSURL *> *)normalImageUrls bigImageUrls:(NSArray<NSURL *> *)bigImageUrls browerPresentingViewController:(UIViewController *)browerPresentingViewController;`

##### 弹出图片浏览器
`- (void)show;
`
##### 最后别忘了实现代理方法
`- (UIImageView *)photoBrowerControllerOriginalImageView:(SWPhotoBrowerController *)browerController withIndex:(NSInteger)index;
`