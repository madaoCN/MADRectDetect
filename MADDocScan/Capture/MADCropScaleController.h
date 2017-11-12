//
//  MADCropScaleController.h
//  MADDocScan
//
//  Created by 梁宪松 on 2017/11/8.
//  Copyright © 2017年 梁宪松. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MADCropScaleView.h"

@interface MADCropScaleController : UIViewController

@property (nonatomic, strong) UIImage *cropImage;
@property (nonatomic, strong) CIRectangleFeature *borderDetectFeature;

@end
