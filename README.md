# MADRectDetect

`CoreImage `下`CIDetector.h`自带了四种识别功能
```swift
/* 人脸识别 */
CORE_IMAGE_EXPORT NSString* const CIDetectorTypeFace NS_AVAILABLE(10_7, 5_0);

/* 矩形边缘识别 */
CORE_IMAGE_EXPORT NSString* const CIDetectorTypeRectangle NS_AVAILABLE(10_10, 8_0);

/* 二维码识别 */
CORE_IMAGE_EXPORT NSString* const CIDetectorTypeQRCode NS_AVAILABLE(10_10, 8_0);

/* 文本识别 */
#if __OBJC2__
CORE_IMAGE_EXPORT NSString* const CIDetectorTypeText NS_AVAILABLE(10_11, 9_0);
```

项目采用原生`CoreImage`框架下`CIDetector`进行边缘检测 
```swift
[CIDetector detectorOfType:CIDetectorTypeRectangle context:nil options:@{CIDetectorAccuracy : CIDetectorAccuracyHigh}];
```

识别到边缘之后使用`CAShapeLayer`将边缘绘制并显示
```swift
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
```

![边缘检测](https://github.com/madaoCN/MADRectDetect/blob/master/pic_1.PNG)

![不规则四边形转换成矩形](https://github.com/madaoCN/MADRectDetect/blob/master/pic_2.PNG)
