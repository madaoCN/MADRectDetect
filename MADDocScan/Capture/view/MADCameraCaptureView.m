//
//  MADCameraCaptureView.m
//  MADDocScan
//
//  Created by 梁宪松 on 2017/11/1.
//  Copyright © 2017年 梁宪松. All rights reserved.
//

#import "MADCameraCaptureView.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <GLKit/GLKit.h>
#import "MADCGTransfromHelper.h"

@interface MADCameraCaptureView()<AVCaptureVideoDataOutputSampleBufferDelegate>
{
    CIContext *_coreImageContext;
    GLuint _renderBuffer;
    GLKView *_glkView;
    BOOL _isStopped;
    CGFloat _imageDedectionConfidence;
    NSTimer *_borderDetectTimeKeeper;
    BOOL _borderDetectFrame;
    CIRectangleFeature *_borderDetectLastRectangleFeature;
    __block BOOL _isCapturing;
    
    CAShapeLayer *_rectOverlay;//边缘识别遮盖
}

@property (nonatomic,strong) AVCaptureSession *captureSession;
@property (nonatomic,strong) AVCaptureDevice *captureDevice;
@property (nonatomic,strong) EAGLContext *context;
@property (nonatomic, strong) AVCaptureStillImageOutput* stillImageOutput;
// 是否强制停止
@property (nonatomic, assign) BOOL forceStop;


@end
@implementation MADCameraCaptureView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        // 注册进入后台通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_backgroundMode) name:UIApplicationWillResignActiveNotification object:nil];
        // 注册进入前台通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_foregroundMode) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

// 高精度边缘识别器
- (CIDetector *)highAccuracyRectangleDetector
{
    static CIDetector *detector = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
                  {
                      detector = [CIDetector detectorOfType:CIDetectorTypeRectangle context:nil options:@{CIDetectorAccuracy : CIDetectorAccuracyHigh}];
                  });
    return detector;
}
// 低精度边缘识别器
- (CIDetector *)rectangleDetetor
{
    static CIDetector *detector = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
                  {
                      detector = [CIDetector detectorOfType:CIDetectorTypeRectangle context:nil options:@{CIDetectorAccuracy : CIDetectorAccuracyLow,CIDetectorTracking : @(YES)}];
                  });
    return detector;
}

- (void)_backgroundMode
{
    self.forceStop = YES;
}

- (void)_foregroundMode
{
    self.forceStop = NO;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - egine
/// 开始捕获图像
- (void)start
{
    _isStopped = NO;
//    _shouldRemoveBorderLayer = YES;
    
    [self.captureSession startRunning];
    
    if (_borderDetectTimeKeeper) {
        [_borderDetectTimeKeeper invalidate];
    }
    // 每隔0.85监测
    _borderDetectTimeKeeper = [NSTimer scheduledTimerWithTimeInterval:0.65f target:self selector:@selector(enableBorderDetectFrame) userInfo:nil repeats:YES];
    
    [self hideGLKView:NO completion:nil];
}

// 停止捕获图像
- (void)stop
{
    _isStopped = YES;
    
    [self.captureSession stopRunning];
    
    [_borderDetectTimeKeeper invalidate];
    
    [self hideGLKView:YES completion:nil];
}

// 开启边缘识别
- (void)enableBorderDetectFrame
{
    _borderDetectFrame = YES;
}

// 设置手电筒
- (void)setEnableTorch:(BOOL)enableTorch
{
    _enableTorch = enableTorch;
    
    AVCaptureDevice *device = self.captureDevice;
    if ([device hasTorch] && [device hasFlash])
    {
        [device lockForConfiguration:nil];
        if (enableTorch)
        {
            [device setTorchMode:AVCaptureTorchModeOn];
        }
        else
        {
            [device setTorchMode:AVCaptureTorchModeOff];
        }
        [device unlockForConfiguration];
    }
}
// 设置闪光灯
- (void)setEnableFlash:(BOOL)enableFlash
{
    _enableFlash = enableFlash;
    AVCaptureDevice *device = self.captureDevice;
    if ([device hasTorch] && [device hasFlash])
    {
        [device lockForConfiguration:nil];
        if (enableFlash)
        {
            [device setTorchMode:AVCaptureTorchModeOn];
        }
        else
        {
            [device setFlashMode:AVCaptureFlashModeOff];
        }
        [device unlockForConfiguration];
    }
}


- (void)createGLKView
{
    if (self.context) return;
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    GLKView *view = [[GLKView alloc] initWithFrame:self.bounds];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    view.translatesAutoresizingMaskIntoConstraints = YES;
    view.context = self.context;
    view.contentScaleFactor = 1.0f;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    [self insertSubview:view atIndex:0];
    _glkView = view;
    glGenRenderbuffers(1, &_renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    
    _coreImageContext = [CIContext contextWithEAGLContext:self.context];
    [EAGLContext setCurrentContext:self.context];
}

- (void)setupCameraView
{
    [self createGLKView];
    
    NSArray *possibleDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *device = [possibleDevices firstObject];
    if (!device) return;
    
    _imageDedectionConfidence = 0.0;
    
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    self.captureSession = session;
    [session beginConfiguration];
    self.captureDevice = device;
    
    NSError *error = nil;
    AVCaptureDeviceInput* input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    session.sessionPreset = AVCaptureSessionPresetPhoto;
    [session addInput:input];
    
    AVCaptureVideoDataOutput *dataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [dataOutput setAlwaysDiscardsLateVideoFrames:YES];
    [dataOutput setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)}];
    [dataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    [session addOutput:dataOutput];
    
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    [session addOutput:self.stillImageOutput];
    
    AVCaptureConnection *connection = [dataOutput.connections firstObject];
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    
    if (device.isFlashAvailable)
    {
        [device lockForConfiguration:nil];
        [device setFlashMode:AVCaptureFlashModeOff];
        [device unlockForConfiguration];
        
        if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
        {
            [device lockForConfiguration:nil];
            [device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            [device unlockForConfiguration];
        }
    }
    
    [session commitConfiguration];
}

// 聚焦动作
- (void)focusAtPoint:(CGPoint)point completionHandler:(void(^)(void))completionHandler
{
    AVCaptureDevice *device = self.captureDevice;
    CGPoint pointOfInterest = CGPointZero;
    CGSize frameSize = self.bounds.size;
    pointOfInterest = CGPointMake(point.y / frameSize.height, 1.f - (point.x / frameSize.width));
    
    if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus])
    {
        NSError *error;
        if ([device lockForConfiguration:&error])
        {
            if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
            {
                [device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
                [device setFocusPointOfInterest:pointOfInterest];
            }
            
            if([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
            {
                [device setExposurePointOfInterest:pointOfInterest];
                [device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
                completionHandler();
            }
            
            [device unlockForConfiguration];
        }
    }
    else
    {
        completionHandler();
    }
}

// 隐藏glkview
- (void)hideGLKView:(BOOL)hidden completion:(void(^)(void))completion
{
    [UIView animateWithDuration:0.1 animations:^
     {
         _glkView.alpha = (hidden) ? 0.0 : 1.0;
     }
                     completion:^(BOOL finished)
     {
         if (!completion) return;
         completion();
     }];
}

// 选取feagure rectangles中最大的矩形
- (CIRectangleFeature *)biggestRectangleInRectangles:(NSArray *)rectangles
{
    if (![rectangles count]) return nil;
    
    float halfPerimiterValue = 0;
    
    CIRectangleFeature *biggestRectangle = [rectangles firstObject];
    
    for (CIRectangleFeature *rect in rectangles)
    {
        CGPoint p1 = rect.topLeft;
        CGPoint p2 = rect.topRight;
        CGFloat width = hypotf(p1.x - p2.x, p1.y - p2.y);
        
        CGPoint p3 = rect.topLeft;
        CGPoint p4 = rect.bottomLeft;
        CGFloat height = hypotf(p3.x - p4.x, p3.y - p4.y);
        
        CGFloat currentHalfPerimiterValue = height + width;
        
        if (halfPerimiterValue < currentHalfPerimiterValue)
        {
            halfPerimiterValue = currentHalfPerimiterValue;
            biggestRectangle = rect;
        }
    }
    
    return biggestRectangle;
}

#pragma mark - 滤镜
- (CIImage *)filteredImageUsingEnhanceFilterOnImage:(CIImage *)image
{
    return [CIFilter filterWithName:@"CIColorControls" keysAndValues:kCIInputImageKey, image, @"inputBrightness", [NSNumber numberWithFloat:0.0], @"inputContrast", [NSNumber numberWithFloat:1.14], @"inputSaturation", [NSNumber numberWithFloat:0.0], nil].outputImage;
}

- (CIImage *)filteredImageUsingContrastFilterOnImage:(CIImage *)image
{
    return [CIFilter filterWithName:@"CIColorControls" withInputParameters:@{@"inputContrast":@(1.1),kCIInputImageKey:image}].outputImage;
}

/// 将任意四边形转换成长方形
- (CIImage *)correctPerspectiveForImage:(CIImage *)image withFeatures:(CIRectangleFeature *)rectangleFeature
{
    NSMutableDictionary *rectangleCoordinates = [NSMutableDictionary new];
    rectangleCoordinates[@"inputTopLeft"] = [CIVector vectorWithCGPoint:rectangleFeature.topLeft];
    rectangleCoordinates[@"inputTopRight"] = [CIVector vectorWithCGPoint:rectangleFeature.topRight];
    rectangleCoordinates[@"inputBottomLeft"] = [CIVector vectorWithCGPoint:rectangleFeature.bottomLeft];
    rectangleCoordinates[@"inputBottomRight"] = [CIVector vectorWithCGPoint:rectangleFeature.bottomRight];
    return [image imageByApplyingFilter:@"CIPerspectiveCorrection" withInputParameters:rectangleCoordinates];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    
    if (self.forceStop || _isStopped || _isCapturing || !CMSampleBufferIsValid(sampleBuffer)) return;
    
    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CIImage *image = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    
    image = [self filteredImageUsingContrastFilterOnImage:image];
    
    if (self.isBorderDetectionEnabled)//开启了边缘检测
    {
        if (_borderDetectFrame)//开启了边缘识别
        {
            // 用高精度边缘识别器 识别特征
            NSArray <CIFeature *>*features = [[self highAccuracyRectangleDetector] featuresInImage:image];
            // 选取特征列表中最大的矩形
            _borderDetectLastRectangleFeature = [self biggestRectangleInRectangles:features];
            _borderDetectFrame = NO;
        }
        
        if (_borderDetectLastRectangleFeature)
        {
            _imageDedectionConfidence += .5;
            
//            image = [self drawHighlightOverlayForPoints:image topLeft:_borderDetectLastRectangleFeature.topLeft topRight:_borderDetectLastRectangleFeature.topRight bottomLeft:_borderDetectLastRectangleFeature.bottomLeft bottomRight:_borderDetectLastRectangleFeature.bottomRight];
            
            // draw border layer
            if (rectangleDetectionConfidenceHighEnough(_imageDedectionConfidence))
            {
                [self drawBorderDetectRectWithImageRect:image.extent topLeft:_borderDetectLastRectangleFeature.topLeft topRight:_borderDetectLastRectangleFeature.topRight bottomLeft:_borderDetectLastRectangleFeature.bottomLeft bottomRight:_borderDetectLastRectangleFeature.bottomRight];
            }
            
        }
        else
        {
            _imageDedectionConfidence = 0.0f;
            if (_rectOverlay) {
                _rectOverlay.path = nil;
            }
        }
    }
    
    if (self.context && _coreImageContext)
    {
        // 将捕获到的图片绘制进_coreImageContext
        [_coreImageContext drawImage:image inRect:self.bounds fromRect:image.extent];
        [self.context presentRenderbuffer:GL_RENDERBUFFER];
        
        [_glkView setNeedsDisplay];
    }
}

// 绘制边缘检测图层
- (void)drawBorderDetectRectWithImageRect:(CGRect)imageRect topLeft:(CGPoint)topLeft topRight:(CGPoint)topRight bottomLeft:(CGPoint)bottomLeft bottomRight:(CGPoint)bottomRight
{
    
    if (!_rectOverlay) {
        _rectOverlay = [CAShapeLayer layer];
        _rectOverlay.fillRule = kCAFillRuleEvenOdd;
        _rectOverlay.fillColor = [UIColor colorWithRed:73/255.0 green:130/255.0 blue:180/255.0 alpha:0.4].CGColor;
        _rectOverlay.strokeColor = [UIColor whiteColor].CGColor;
        _rectOverlay.lineWidth = 5.0f;
    }
    if (!_rectOverlay.superlayer) {
        self.layer.masksToBounds = YES;
        [self.layer addSublayer:_rectOverlay];
    }

    // 将图像空间的坐标系转换成uikit坐标系
    TransformCIFeatureRect featureRect = [self transfromRealRectWithImageRect:imageRect topLeft:topLeft topRight:topRight bottomLeft:bottomLeft bottomRight:bottomRight];
    
    // 边缘识别路径
    UIBezierPath *path = [UIBezierPath new];
    [path moveToPoint:featureRect.topLeft];
    [path addLineToPoint:featureRect.topRight];
    [path addLineToPoint:featureRect.bottomRight];
    [path addLineToPoint:featureRect.bottomLeft];
    [path closePath];
    // 背景遮罩路径
    UIBezierPath *rectPath  = [UIBezierPath bezierPathWithRect:CGRectMake(-5,
                                                                          -5,
                                                                          self.frame.size.width + 10,
                                                                          self.frame.size.height + 10)];
    [rectPath setUsesEvenOddFillRule:YES];
    [rectPath appendPath:path];
    _rectOverlay.path = rectPath.CGPath;
}

/// 拍照动作
- (void)captureImageWithCompletionHandler:(CompletionHandler)completionHandler
{
    if (_isCapturing) return;
    
    __weak typeof(self) weakSelf = self;
    
    _isCapturing = YES;
    //关闭闪光灯
    [self setEnableFlash:NO];
    
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in self.stillImageOutput.connections)
    {
        for (AVCaptureInputPort *port in [connection inputPorts])
        {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] )
            {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) break;
    }
    
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error)
     {
         __strong typeof(self) strongSelf = weakSelf;

         NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
         if (strongSelf.isBorderDetectionEnabled)
         {
             CIImage *enhancedImage = [CIImage imageWithData:imageData];
             enhancedImage = [strongSelf filteredImageUsingContrastFilterOnImage:enhancedImage];
             // 判断边缘识别度阈值, 再对拍照后的进行边缘识别
             CIRectangleFeature *rectangleFeature;
              if (rectangleDetectionConfidenceHighEnough(_imageDedectionConfidence))
              {
                  // 获取边缘识别最大矩形
                  rectangleFeature = [strongSelf biggestRectangleInRectangles:[[self highAccuracyRectangleDetector] featuresInImage:enhancedImage]];

                  if (rectangleFeature)
                  {
                      enhancedImage = [strongSelf correctPerspectiveForImage:enhancedImage withFeatures:rectangleFeature];
                  }
              }
             
             // 获取拍照图片
             UIGraphicsBeginImageContext(CGSizeMake(enhancedImage.extent.size.height, enhancedImage.extent.size.width));
             [[UIImage imageWithCIImage:enhancedImage scale:1.0 orientation:UIImageOrientationRight] drawInRect:CGRectMake(0,0, enhancedImage.extent.size.height, enhancedImage.extent.size.width)];
             UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
             UIGraphicsEndImageContext();
             
             completionHandler(image, rectangleFeature);
         }
         else//未开启边缘识别，直接返回图片
         {
             completionHandler([UIImage imageWithData:imageData], nil);
         }
         
         _isCapturing = NO;
         
         if (_rectOverlay) {
             // 移除识别边框
             _rectOverlay.path = nil;
         }
          // 隐藏照相机视图
//          [strongSelf hideGLKView:YES completion:^
//           {
//
//               [strongSelf hideGLKView:NO completion:^
//                {
//                    [strongSelf hideGLKView:YES completion:nil];
//                }];
//           }];
     }];
}


// 添加边缘识别遮盖
- (CIImage *)drawHighlightOverlayForPoints:(CIImage *)image topLeft:(CGPoint)topLeft topRight:(CGPoint)topRight bottomLeft:(CGPoint)bottomLeft bottomRight:(CGPoint)bottomRight
{
    // overlay
    CIImage *overlay = [CIImage imageWithColor:[CIColor colorWithRed:73/255.0 green:130/255.0 blue:180/255.0 alpha:0.5]];
    overlay = [overlay imageByCroppingToRect:image.extent];
    
    overlay = [overlay imageByApplyingFilter:@"CIPerspectiveTransformWithExtent" withInputParameters:@{@"inputExtent":[CIVector vectorWithCGRect:image.extent],
                              @"inputTopLeft":[CIVector vectorWithCGPoint:topLeft],
                              @"inputTopRight":[CIVector vectorWithCGPoint:topRight],
                              @"inputBottomLeft":[CIVector vectorWithCGPoint:bottomLeft],
                              @"inputBottomRight":[CIVector vectorWithCGPoint:bottomRight]}];
    
    return [overlay imageByCompositingOverImage:image];
}

/// 坐标系转换
- (TransformCIFeatureRect)transfromRealRectWithImageRect:(CGRect)imageRect topLeft:(CGPoint)topLeft topRight:(CGPoint)topRight bottomLeft:(CGPoint)bottomLeft bottomRight:(CGPoint)bottomRight
{
    CGRect previewRect = self.frame;
    
    return [MADCGTransfromHelper transfromRealCIRectInPreviewRect:previewRect imageRect:imageRect topLeft:topLeft topRight:topRight bottomLeft:bottomLeft bottomRight:bottomRight];
}

BOOL rectangleDetectionConfidenceHighEnough(float confidence)
{
    return (confidence > 1.0);
}

@end
