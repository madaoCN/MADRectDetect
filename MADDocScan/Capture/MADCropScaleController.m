//
//  MADCropScaleController.m
//  MADDocScan
//
//  Created by 梁宪松 on 2017/11/8.
//  Copyright © 2017年 梁宪松. All rights reserved.
//

#import "MADCropScaleController.h"
#import "Masonry.h"
#import "MADCGTransfromHelper.h"

@interface MADCropScaleController ()

// 拉伸图
@property (nonatomic, strong) MADCropScaleView *cropScaleView;
// 完成按钮
@property (nonatomic, strong) UIButton *finishBtn;
// 返回按钮
@property (nonatomic, strong) UIButton *backBtn;

@end

@implementation MADCropScaleController

- (instancetype)init
{
    if (self = [super init]) {
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    if (_cropImage) {
        self.view.layer.contents = (__bridge id _Nullable)(_cropImage.CGImage);
    }
    
//    [self.view addSubview:self.cropScaleView];
    [self.view addSubview:self.backBtn];
//    [self.view addSubview:self.finishBtn];

    if (_borderDetectFeature && _cropImage) {// 识别到了边缘
        
        // 拍照时候 设置了 UIImageOrientationRight， 所以要变换 extent
        CGRect extent = CGRectMake(0, 0, _cropImage.size.width, _cropImage.size.height);
        // 转换成UIKit坐标系
//        CGAffineTransform transform = CGAffineTransformIdentity;
        
//        CGAffineTransform transform = CGAffineTransformMakeTranslation(0.f, self.view.bounds.size.height);
//        transform = CGAffineTransformScale(transform, 1, -1);
//        transform = CGAffineTransformRotate(transform, -M_PI*3/2);
//
//        CGPoint topLeft = CGPointApplyAffineTransform(_borderDetectFeature.topLeft, transform);
//        CGPoint topRight = CGPointApplyAffineTransform(_borderDetectFeature.topRight, transform);
//        CGPoint bottomRight = CGPointApplyAffineTransform(_borderDetectFeature.bottomRight, transform);
//        CGPoint bottomLeft = CGPointApplyAffineTransform(_borderDetectFeature.bottomLeft, transform);
//
//        TransformCIFeatureRect rect =  [MADCGTransfromHelper transfromRealCIRectInPreviewRect:self.view.bounds imageRect:extent topLeft:topLeft topRight:topRight bottomLeft:bottomLeft bottomRight:bottomRight];
//
//        [_cropScaleView setCornerPointsWithTopLeft:rect.topLeft topRight:rect.topRight bottomLeft:rect.bottomLeft bottomRight:rect.bottomRight];
    }else// 没有识别到边缘
    {
        CGRect rect = self.view.bounds;
        rect = CGRectInset(rect, 10, 10);
        _cropScaleView.cropperFrame = rect;
    }
    [self.view setNeedsUpdateConstraints];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Getter
- (MADCropScaleView *)cropScaleView
{
    if (!_cropScaleView) {
        _cropScaleView = [[MADCropScaleView alloc] initWithFrame:self.view.bounds];
    }
    return _cropScaleView;
}

- (UIButton *)finishBtn
{
    if (!_finishBtn) {
        _finishBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _finishBtn.backgroundColor = kBaseColor;
        [_finishBtn setTitle:@"完成" forState:UIControlStateNormal];
        [_finishBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _finishBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        [_finishBtn setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
        _finishBtn.layer.cornerRadius = 35/2;
        _finishBtn.layer.masksToBounds = YES;
    }
    return _finishBtn;
}

- (UIButton *)backBtn
{
    if (!_backBtn) {
        _backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _backBtn.backgroundColor = kBaseColor;
        [_backBtn setTitle:@"取消" forState:UIControlStateNormal];
        [_backBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _backBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        [_backBtn setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
        _backBtn.layer.cornerRadius = 35/2;
        _backBtn.layer.masksToBounds = YES;
        [_backBtn addTarget:self action:@selector(onActionButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backBtn;
}

#pragma mark - handler
- (void)onActionButton:(id)sender{
    if (sender == _backBtn) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}


#pragma mark - Layout
- (void)updateViewConstraints
{
    [_backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.left.mas_equalTo(20);
        make.bottom.mas_equalTo(-20);
        make.size.mas_equalTo(CGSizeMake(65, 35));
    }];
    
    [_finishBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.right.mas_equalTo(-20);
        make.bottom.mas_equalTo(-20);
        make.size.mas_equalTo(CGSizeMake(65, 35));
    }];
    [super updateViewConstraints];
}
@end
