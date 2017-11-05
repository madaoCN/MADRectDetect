//
//  MADCGTransfromHelper.h
//  MADDocScan
//
//  Created by 梁宪松 on 2017/11/3.
//  Copyright © 2017年 梁宪松. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>
@interface MADCGTransfromHelper : NSObject

+ (NSArray *)transfromRealCIRectInPreviewRect:(CGRect)previewRect imageRect:(CGRect)imageRect topLeft:(CGPoint)topLeft topRight:(CGPoint)topRight bottomLeft:(CGPoint)bottomLeft bottomRight:(CGPoint)bottomRight;

+ (NSArray *)transfromRealCGRectInPreviewRect:(CGRect)previewRect imageRect:(CGRect)imageRect topLeft:(CGPoint)topLeft topRight:(CGPoint)topRight bottomLeft:(CGPoint)bottomLeft bottomRight:(CGPoint)bottomRight;

@end
