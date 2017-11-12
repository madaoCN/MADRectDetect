//
//  MADCropScaleView.m
//  MADDocScan
//
//  Created by 梁宪松 on 2017/11/8.
//  Copyright © 2017年 梁宪松. All rights reserved.
//

#import "MADCropScaleView.h"

CGFloat distanceBetweenPoints (CGPoint first, CGPoint second) {
    CGFloat deltaX = second.x - first.x;
    CGFloat deltaY = second.y - first.y;
    return sqrt(deltaX*deltaX + deltaY*deltaY );
};


typedef NS_ENUM(NSInteger, kNearstPointType)
{
    kNearstPointType_topLeft = 0,
    kNearstPointType_topRight = 1,
    kNearstPointType_bottomLeft = 2,
    kNearstPointType_bottomRight = 3,
};


@interface MADCropScaleView()
{
    CGVector _transformVector;//平移向量
}
@property (nonatomic, assign) kNearstPointType nearstPointType;

@property (nonatomic, assign) CGPoint topLeftPoint;
@property (nonatomic, assign) CGPoint topRightPoint;
@property (nonatomic, assign) CGPoint bottomLeftPoint;
@property (nonatomic, assign) CGPoint bottomRightPoint;

@property (nonatomic, strong) CAShapeLayer *maskLayer;

@end

@implementation MADCropScaleView

+ (Class)layerClass{
    return [CAShapeLayer class];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self loadNormalProperty];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self loadNormalProperty];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self loadNormalProperty];
    }

    return self;
}

///默认变量
- (void) loadNormalProperty {
    _panWidth = 3;
    _cornerCircleRedis = 8.0f;
    _panStrokColor = [UIColor whiteColor];
//    _cropperFrame = CGRectZero;
    self.backgroundColor = [UIColor clearColor];
    
    CAShapeLayer *layer = (CAShapeLayer *)(self.layer);
    layer.fillColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.4].CGColor;
    layer.strokeColor = [UIColor whiteColor].CGColor;
}

- (void)setCornerPointsWithTopLeft:(CGPoint)topLeft topRight:(CGPoint)topRight bottomLeft:(CGPoint)bottomLeft bottomRight:(CGPoint)bottomRight
{
    _topLeftPoint = CGPointMake(topLeft.x,
                                 topLeft.y);
    _topRightPoint = CGPointMake(topRight.x,
                                  topRight.y);
    _bottomLeftPoint = CGPointMake(bottomLeft.x,
                                    bottomLeft.y);
    _bottomRightPoint = CGPointMake(bottomRight.x,
                                     bottomRight.y);
    [self setNeedsDisplay];
}

- (void)setCropperFrame:(CGRect)cropperFrame
{
    _cropperFrame = cropperFrame;
    // 四个点赋值
    _topLeftPoint = CGPointMake(cropperFrame.origin.x,
                                 cropperFrame.origin.y);
    _topRightPoint = CGPointMake(cropperFrame.origin.x + CGRectGetWidth(cropperFrame),
                                  cropperFrame.origin.y);
    _bottomLeftPoint = CGPointMake(cropperFrame.origin.x,
                                    cropperFrame.origin.y + CGRectGetHeight(cropperFrame));
    _bottomRightPoint = CGPointMake(cropperFrame.origin.x + CGRectGetWidth(cropperFrame),
                                     cropperFrame.origin.y + CGRectGetHeight(cropperFrame));
    [self setNeedsDisplay];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([self.delegate respondsToSelector:@selector(beforeScaleViewTouched:)]) {
        [self.delegate beforeScaleViewTouched:self];
    }
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    //计算最相近的点, 直线距离
    CGFloat nearstLen = CGFLOAT_MAX;
    CGPoint p[4] = {_topLeftPoint,
                    _topRightPoint,
                    _bottomLeftPoint,
                    _bottomRightPoint};
    for (NSInteger i = 0; i < sizeof(p)/sizeof(CGPoint); i++) {
        
        CGPoint pt = p[i];
        CGFloat distance = distanceBetweenPoints(point, pt);
        if (distance <= nearstLen) {
            nearstLen = distance;
            _nearstPointType = (kNearstPointType)i;
            _transformVector = CGVectorMake(point.x - pt.x,
                                            point.y - pt.y
                                            );
        }
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    
    CGPoint newPoint = CGPointMake(point.x - _transformVector.dx,
                                   point.y - _transformVector.dy);
    
    switch (_nearstPointType) {
        case kNearstPointType_topLeft:
            _topLeftPoint = newPoint;
            break;
        case kNearstPointType_topRight:
            _topRightPoint = newPoint;
            break;
        case kNearstPointType_bottomLeft:
            _bottomLeftPoint =newPoint;
            break;
        case kNearstPointType_bottomRight:
            _bottomRightPoint =newPoint;
            break;
        default:
            break;
    }
    
    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self setNeedsDisplay];
}

- (void)drawCornerCircleAtPoint:(CGPoint)point radius:(CGFloat)radius
{
    // 绘制四角按钮位置
    UIBezierPath* ovalPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(point.x, point.y) radius:radius startAngle:0 endAngle:M_PI * 2 clockwise:YES];
    [[_panStrokColor colorWithAlphaComponent:0.5] setFill];
    [ovalPath fill];
    
    UIBezierPath* innerOvalPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(point.x, point.y) radius:radius*3/4 startAngle:0 endAngle:M_PI * 2 clockwise:YES];
    [_panStrokColor setFill];
    [innerOvalPath fill];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];

    CAShapeLayer *_maskLayer = (CAShapeLayer *)(self.layer);
    //绘制遮罩和边缘识别路径
    UIBezierPath* rectPath = [UIBezierPath bezierPathWithRect:rect];
    UIBezierPath* iregularPath = [UIBezierPath bezierPath];
    [iregularPath moveToPoint: _topLeftPoint];
    [iregularPath addLineToPoint: _topRightPoint];
    [iregularPath addLineToPoint: _bottomRightPoint];
    [iregularPath addLineToPoint: _bottomLeftPoint];
    [iregularPath closePath];
    [rectPath appendPath:iregularPath];
    [_maskLayer setFillRule:kCAFillRuleEvenOdd];
    _maskLayer.path = rectPath.CGPath;

    CGContextRef context = UIGraphicsGetCurrentContext();
    // 绘制边缘识别矩形
    CGContextMoveToPoint(context, _topLeftPoint.x, _topLeftPoint.y);
    CGContextAddLineToPoint(context, _topRightPoint.x, _topRightPoint.y);
    CGContextAddLineToPoint(context, _bottomRightPoint.x, _bottomRightPoint.y);
    CGContextAddLineToPoint(context, _bottomLeftPoint.x, _bottomLeftPoint.y);
    CGContextAddLineToPoint(context, _topLeftPoint.x, _topLeftPoint.y);

    CGContextSetLineWidth(context, _panWidth);
    CGContextSetStrokeColorWithColor(context, _panStrokColor.CGColor);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineJoin(context, kCGLineJoinRound);
    CGContextStrokePath(context);
    // 绘制四个点
    [self drawCornerCircleAtPoint:_topLeftPoint radius:_cornerCircleRedis];
    [self drawCornerCircleAtPoint:_topRightPoint radius:_cornerCircleRedis];
    [self drawCornerCircleAtPoint:_bottomLeftPoint radius:_cornerCircleRedis];
    [self drawCornerCircleAtPoint:_bottomRightPoint radius:_cornerCircleRedis];
}

@end
