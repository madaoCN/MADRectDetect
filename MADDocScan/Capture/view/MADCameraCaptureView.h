//
//  MADCameraCaptureView.h
//  MADDocScan
//
//  Created by 梁宪松 on 2017/11/1.
//  Copyright © 2017年 梁宪松. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^CompletionHandler)(UIImage *image, CIRectangleFeature *borderDetectFeature);
@interface MADCameraCaptureView : UIView

/// 创建视图捕获view
- (void)setupCameraView;
/// 开始捕获视图
- (void)start;
/// 结束视图捕获
- (void)stop;
/// 开启边缘检测
@property (nonatomic,assign,getter=isBorderDetectionEnabled) BOOL enableBorderDetection;
/// 是否开启手电筒
@property (nonatomic,assign,getter=isTorchEnabled) BOOL enableTorch;
/// 是否开启闪关灯
@property (nonatomic,assign,getter=isFlashEnabled) BOOL enableFlash;
/// 聚焦视图
- (void)focusAtPoint:(CGPoint)point completionHandler:(void(^)(void))completionHandler;
/// 拍照
- (void)captureImageWithCompletionHandler:(CompletionHandler)completionHandler;

@end
