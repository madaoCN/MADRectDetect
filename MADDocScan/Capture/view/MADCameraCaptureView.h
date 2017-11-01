//
//  MADCameraCaptureView.h
//  MADDocScan
//
//  Created by 梁宪松 on 2017/11/1.
//  Copyright © 2017年 梁宪松. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MADCameraCaptureView : UIView

- (void)setupCameraView;

- (void)start;
- (void)stop;

@property (nonatomic,assign,getter=isBorderDetectionEnabled) BOOL enableBorderDetection;
@property (nonatomic,assign,getter=isTorchEnabled) BOOL enableTorch;
@property (nonatomic,assign,getter=isFlashEnabled) BOOL enableFlash;

- (void)focusAtPoint:(CGPoint)point completionHandler:(void(^)())completionHandler;

- (void)captureImageWithCompletionHander:(void(^)(id data, NSArray *pointsValueArr))completionHandler;

@end
