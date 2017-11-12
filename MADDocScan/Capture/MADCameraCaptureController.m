//
//  MADCameraCaptureController.m
//  MADDocScan
//
//  Created by 梁宪松 on 2017/10/28.
//  Copyright © 2017年 梁宪松. All rights reserved.
//

#import "MADCameraCaptureController.h"
#import "MADCropScaleController.h"
#import "MADSnapshotButton.h"
#import "MADCameraCaptureView.h"
#import "Masonry.h"


@interface MADCameraCaptureController ()<UINavigationControllerDelegate, UIGestureRecognizerDelegate>

// 导航栏
@property (nonatomic, strong) UIView *navToolBar;
// 返回按钮
@property (nonatomic,strong) UIButton *leftBtn;
// 导航栏标题
@property (nonatomic,strong) UILabel *navTitleLabel;
// 闪光灯按钮
@property (nonatomic,strong) UIButton *flashLigthToggle;
// 拍照按钮
@property (nonatomic, strong) MADSnapshotButton *snapshotBtn;
// 拍照视图
@property (nonatomic, strong) MADCameraCaptureView *captureCameraView;
// 聚焦指示器
@property (nonatomic, strong) UIView *focusIndicator;
// 单击手势
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;

@end

@implementation MADCameraCaptureController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationController.delegate = self;
    [self initUI];
    // 设置需要更新约束
    [self.view setNeedsUpdateConstraints];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    // 关闭闪光灯
    self.captureCameraView.enableTorch = NO;
    // 停止捕获图像
    [self.captureCameraView stop];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // 开始捕获图像
    [self.captureCameraView start];
}

/**
 初始化视图
 */
- (void)initUI{
    
    // 导航栏
    [self.view addSubview:self.navToolBar];
    [self.navToolBar addSubview:self.leftBtn];
    [self.navToolBar addSubview:self.flashLigthToggle];
    [self.navToolBar addSubview:self.navTitleLabel];
    // 拍照视图
    [self.view addSubview:self.captureCameraView];
    [self.captureCameraView setupCameraView];
    // 添加单机手势
    [self.captureCameraView addGestureRecognizer:self.tapGestureRecognizer];
    [self.tapGestureRecognizer addTarget:self action:@selector(handleTapGesture:)];
    // 拍照按钮
    [self.view addSubview:self.snapshotBtn];
    // 添加聚焦指示器
    [self.view addSubview:self.focusIndicator];
    // 更新导航栏标题
    [self updateTitleLabel];
}

#pragma mark - UINavigationBarDelegate
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (viewController == self) {
        [self.navigationController setNavigationBarHidden:YES animated:NO];
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
    }else
    {
        [self.navigationController setNavigationBarHidden:NO animated:NO];
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
    }
}

#pragma mark - Getter
- (UIView *)navToolBar
{
    if (!_navToolBar) {
        _navToolBar = [[UIView alloc] init];
        _navToolBar.backgroundColor = kBaseColor;
    }
    return _navToolBar;
}

- (UIView *)focusIndicator
{
    if (!_focusIndicator) {
        _focusIndicator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        _focusIndicator.layer.borderWidth = 5.0f;
        _focusIndicator.layer.borderColor = kWhiteColor.CGColor;
        _focusIndicator.alpha = 0;
    }
    return _focusIndicator;
}



- (UIButton *)leftBtn
{
    if (!_leftBtn) {
        _leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _leftBtn.frame = CGRectMake(0, 0, 40, 40);
        [_leftBtn setImage:[UIImage imageNamed:@"Capture_back_forward"] forState:UIControlStateNormal];
        [_leftBtn setImageEdgeInsets:UIEdgeInsetsMake(0, -5, 0, 0)];
        [_leftBtn setTitle:@"  " forState:UIControlStateNormal];
        _leftBtn.adjustsImageWhenHighlighted = NO;
        [_leftBtn addTarget:self action:@selector(popSelf) forControlEvents:UIControlEventTouchUpInside];
    }
    return _leftBtn;
}

- (UILabel *)navTitleLabel
{
    if (!_navTitleLabel) {
        _navTitleLabel = [[UILabel alloc] init];
        _navTitleLabel.textAlignment = NSTextAlignmentCenter;
        _navTitleLabel.font = [UIFont systemFontOfSize:17];
        _navTitleLabel.textColor = kWhiteColor;
    }
    return _navTitleLabel;
}

- (UIButton *)flashLigthToggle
{
    if (!_flashLigthToggle) {
        _flashLigthToggle = [UIButton buttonWithType:UIButtonTypeCustom];
        _flashLigthToggle.frame = CGRectMake(0, 0, 40, 40);
        [_flashLigthToggle setImage:[UIImage imageNamed:@"Capture_torch"] forState:UIControlStateNormal];
        [_flashLigthToggle setImageEdgeInsets:UIEdgeInsetsMake(0, -5, 0, 0)];
        [_flashLigthToggle setTitle:@"  " forState:UIControlStateNormal];
        _flashLigthToggle.titleLabel.font = [UIFont systemFontOfSize:17];
        _flashLigthToggle.adjustsImageWhenHighlighted = NO;
        [_flashLigthToggle addTarget:self action:@selector(onFlashLigthToggle) forControlEvents:UIControlEventTouchUpInside];
    }
    return _flashLigthToggle;
}

- (MADSnapshotButton *)snapshotBtn
{
    if (!_snapshotBtn) {
        _snapshotBtn = [[MADSnapshotButton alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
        [_snapshotBtn addTarget:self action:@selector(onSnapshotBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _snapshotBtn;
}

- (MADCameraCaptureView *)captureCameraView
{
    if (!_captureCameraView) {
        _captureCameraView = [[MADCameraCaptureView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 300)];
        //打开边缘检测
        [_captureCameraView setEnableBorderDetection:YES];
        _captureCameraView.backgroundColor = kBlackColor;
    }
    return _captureCameraView;
}

- (UITapGestureRecognizer *)tapGestureRecognizer
{
    if (!_tapGestureRecognizer) {
        _tapGestureRecognizer = [[UITapGestureRecognizer alloc] init];
//        _tapGestureRecognizer.delegate = self;
        
    }
    return _tapGestureRecognizer;
}

#pragma mark - engine
- (void)onFlashLigthToggle {
    BOOL enable = !self.captureCameraView.isTorchEnabled;
    self.captureCameraView.enableTorch = enable;
    [self updateTitleLabel];
}

- (void)onSnapshotBtn:(id)sender {
    
    __weak typeof(self) weakSelf = self;
    [self.captureCameraView captureImageWithCompletionHandler:^(UIImage *data, CIRectangleFeature *borderDetectFeature) {
        __strong typeof(self) strongSelf = weakSelf;
    
        MADCropScaleController *vc = [[MADCropScaleController alloc] init];
        vc.borderDetectFeature = borderDetectFeature;
        vc.cropImage = data;
        [strongSelf presentViewController:vc animated:YES completion:nil];
    }];
}

- (void)handleTapGesture:(UITapGestureRecognizer *)sender{
    if (sender.state == UIGestureRecognizerStateRecognized)
    {
        CGPoint location = [sender locationInView:self.view];
        [self.captureCameraView focusAtPoint:location completionHandler:^
         {
             [self focusIndicatorAnimateToPoint:location];
         }];
        [self focusIndicatorAnimateToPoint:location];
    }
}

- (void)focusIndicatorAnimateToPoint:(CGPoint)targetPoint
{
    [self.focusIndicator setCenter:targetPoint];
    self.focusIndicator.alpha = 0.0;
    self.focusIndicator.hidden = NO;
    
    [UIView animateWithDuration:0.4 animations:^
     {
         self.focusIndicator.alpha = 1.0;
     }
                     completion:^(BOOL finished)
     {
         [UIView animateWithDuration:0.4 animations:^
          {
              self.focusIndicator.alpha = 0.0;
          }];
     }];
}

- (void)popSelf
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [self.navigationController popViewControllerAnimated:YES];;
}

// 更新
- (void)updateTitleLabel
{
    CATransition *animation = [CATransition animation];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    animation.type = kCATransitionPush;
    animation.subtype = kCATransitionFromBottom;
    animation.duration = 0.5;
    [self.navTitleLabel.layer addAnimation:animation forKey:@"kCATransitionFade"];
    self.navTitleLabel.text = self.captureCameraView.isTorchEnabled ? @"闪光灯 开" : @"闪光灯 关";
}

#pragma mark - Contraints
- (void)updateViewConstraints
{
    [super updateViewConstraints];
    
    [_navToolBar mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.top.left.right.mas_equalTo(0);
        make.height.mas_equalTo(NAV_HEIGHT + 10);
    }];
    
    [_leftBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.left.mas_equalTo(10);
        make.centerY.mas_equalTo(_navToolBar);
        make.size.mas_equalTo(CGSizeMake(40, 40));
    }];
    
    [_flashLigthToggle mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.right.mas_equalTo(0);
        make.centerY.mas_equalTo(_navToolBar);
        make.size.mas_equalTo(_leftBtn.frame.size);
    }];
    
    [_navTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(_navToolBar);
    }];
    
    [_snapshotBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.size.mas_equalTo(CGSizeMake(65, 65));
        make.bottom.mas_equalTo(-25);
        make.centerX.mas_equalTo(self.view);
    }];
    
    [_captureCameraView mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.left.right.mas_equalTo(0);
        make.top.mas_equalTo(_navToolBar.mas_bottom);
        make.bottom.mas_equalTo(0);
    }];
}
@end
