# MADRectDetect

`CoreImage `下`CIDetector.h`自带了四种识别功能
```swift
/ * 人脸识别 */
CORE_IMAGE_EXPORT NSString* const CIDetectorTypeFace NS_AVAILABLE(10_7, 5_0);

/ * 矩形边缘识别 */
CORE_IMAGE_EXPORT NSString* const CIDetectorTypeRectangle NS_AVAILABLE(10_10, 8_0);

/* 二维码识别 */
CORE_IMAGE_EXPORT NSString* const CIDetectorTypeQRCode NS_AVAILABLE(10_10, 8_0);

/* 文本识别 */
#if __OBJC2__
CORE_IMAGE_EXPORT NSString* const CIDetectorTypeText NS_AVAILABLE(10_11, 9_0);
```

项目采用原生`CoreImage`框架下`CIDetector`进行边缘检测

![边缘检测](https://github.com/madaoCN/MADRectDetect/blob/master/pic_1.PNG)

![不规则四边形转换成矩形](https://github.com/madaoCN/MADRectDetect/blob/master/pic_2.PNG)
