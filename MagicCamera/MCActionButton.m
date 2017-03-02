//
//  ActionButton.m
//  Baobaotuan
//
//  Created by Qusic on 8/15/14.
//  Copyright (c) 2014 Baobaotuan. All rights reserved.
//

#import "MCActionButton.h"
#import <POP/POP.h>
#import "MCDefine.h"
@implementation MCActionButton

- (void)setup
{
//    self.titleLabel.textColor = ZQColor(48, 143, 255, 1.0);
    self.titleLabel.textColor = ZQColor(118, 204, 202, 1.0);
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGRect bounds = CGRectInset(self.bounds, 1, 1);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [[UIColor whiteColor] setFill];
    CGContextSetStrokeColorWithColor(context, ZQColor(168, 238, 254, 1.0).CGColor);
    CGContextSetLineWidth(context, 2);
    CGPathRef path = [UIBezierPath bezierPathWithRoundedRect:bounds cornerRadius:bounds.size.height / 2.0].CGPath;
    CGContextAddPath(context, path);
    CGContextFillPath(context);
    CGContextAddPath(context, path);
    CGContextStrokePath(context);
}

- (void)setHighlighted:(BOOL)highlighted
{
    BOOL animated = self.highlighted != highlighted;
    [super setHighlighted:highlighted];
    if (animated) {
        if (highlighted) {
            POPBasicAnimation *scaleAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPViewScaleXY];
            scaleAnimation.duration = 0.2;
            scaleAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(0.9, 0.9)];
            [self pop_addAnimation:scaleAnimation forKey:@"scaleAnimation"];
        } else {
            POPSpringAnimation *scaleAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewScaleXY];
            scaleAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(1, 1)];
            scaleAnimation.velocity = [NSValue valueWithCGPoint:CGPointMake(2, 2)];
            scaleAnimation.springBounciness = 25;
            [self pop_addAnimation:scaleAnimation forKey:@"scaleAnimation"];
        }
    }
}

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    self.alpha = enabled ? 1.0 : 0.6;
}

@end
