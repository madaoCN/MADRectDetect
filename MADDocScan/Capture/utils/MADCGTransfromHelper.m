//
//  MADCGTransfromHelper.m
//  MADDocScan
//
//  Created by 梁宪松 on 2017/11/3.
//  Copyright © 2017年 梁宪松. All rights reserved.
//

#import "MADCGTransfromHelper.h"

@implementation MADCGTransfromHelper

+ (TransformCIFeatureRect)transfromRealCIRectInPreviewRect:(CGRect)previewRect imageRect:(CGRect)imageRect topLeft:(CGPoint)topLeft topRight:(CGPoint)topRight bottomLeft:(CGPoint)bottomLeft bottomRight:(CGPoint)bottomRight
{
    
    return [MADCGTransfromHelper md_transfromRealRectInPreviewRect:previewRect imageRect:imageRect isUICoordinate:NO topLeft:topLeft topRight:topRight bottomLeft:bottomLeft bottomRight:bottomRight];
}

+ (TransformCIFeatureRect)transfromRealCGRectInPreviewRect:(CGRect)previewRect imageRect:(CGRect)imageRect topLeft:(CGPoint)topLeft topRight:(CGPoint)topRight bottomLeft:(CGPoint)bottomLeft bottomRight:(CGPoint)bottomRight
{
    
    return [MADCGTransfromHelper md_transfromRealRectInPreviewRect:previewRect imageRect:imageRect isUICoordinate:YES topLeft:topLeft topRight:topRight bottomLeft:bottomLeft bottomRight:bottomRight];
}


+ (TransformCIFeatureRect)md_transfromRealRectInPreviewRect:(CGRect)previewRect imageRect:(CGRect)imageRect  isUICoordinate:(BOOL)isUICoordinate topLeft:(CGPoint)topLeft  topRight:(CGPoint)topRight bottomLeft:(CGPoint)bottomLeft bottomRight:(CGPoint)bottomRight
{
    
    // find ratio between the video preview rect and the image rect; rectangle feature coordinates are relative to the CIImage
    CGFloat deltaX = CGRectGetWidth(previewRect)/CGRectGetWidth(imageRect);
    CGFloat deltaY = CGRectGetHeight(previewRect)/CGRectGetHeight(imageRect);
    
    // transform to UIKit coordinate system
    CGAffineTransform transform = CGAffineTransformMakeTranslation(0.f, CGRectGetHeight(previewRect));
    if (!isUICoordinate) {
        transform = CGAffineTransformScale(transform, 1, -1);
    }
    // apply preview to image scaling
    transform = CGAffineTransformScale(transform, deltaX, deltaY);
    
//    CGPoint points[4];
//    points[0] = CGPointApplyAffineTransform(topLeft, transform);
//    points[1] = CGPointApplyAffineTransform(topRight, transform);
//    points[2] = CGPointApplyAffineTransform(bottomRight, transform);
//    points[3] = CGPointApplyAffineTransform(bottomLeft, transform);
//    return @[
//             [NSValue valueWithCGPoint:points[0]],
//             [NSValue valueWithCGPoint:points[1]],
//             [NSValue valueWithCGPoint:points[2]],
//             [NSValue valueWithCGPoint:points[3]],
//             ];
    
    TransformCIFeatureRect featureRect;
    featureRect.topLeft = CGPointApplyAffineTransform(topLeft, transform);
    featureRect.topRight = CGPointApplyAffineTransform(topRight, transform);
    featureRect.bottomRight = CGPointApplyAffineTransform(bottomRight, transform);
    featureRect.bottomLeft = CGPointApplyAffineTransform(bottomLeft, transform);

    return featureRect;
}

@end
