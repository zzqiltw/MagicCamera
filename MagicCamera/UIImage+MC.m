//
//  UIColor+MC.m
//  MagicCamera
//
//  Created by 郑志勤 on 2017/4/10.
//  Copyright © 2017年 zzqiltw. All rights reserved.
//

#import "UIImage+MC.h"

@implementation UIImage (MC)


+ (UIImage *)imageWithColor:(UIColor *)color {
    CGFloat px = 1.f/[UIScreen mainScreen].scale;
    return [self imageWithColor:color
                           size:CGSizeMake(px, px)];
}

+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size
{
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [color setFill];
    CGContextFillRect(ctx, (CGRect){{0, 0}, size});
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [image resizableImageWithCapInsets:UIEdgeInsetsZero resizingMode:UIImageResizingModeStretch];
}

@end
