//
//  IDPAWBandView.m
//  IDPAuthoringWorkspace
//
//  Created by 能登 要 on 2014/09/11.
//  Copyright (c) 2014年 com.irimasu. All rights reserved.
//

#import "IDPAWBandView.h"

@implementation IDPAWBandView

- (void)drawBandWithFrame: (CGRect)frame;
{
    //// Rectangle Drawing
    UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRect: CGRectMake(CGRectGetMinX(frame) + 0.5, CGRectGetMinY(frame) + 0.5, CGRectGetWidth(frame) - 1, CGRectGetHeight(frame) - 1)];
    [UIColor.redColor setStroke];
    rectanglePath.lineWidth = 1;
    [rectanglePath stroke];
}

- (void)drawRect:(CGRect)rect
{
    [self drawBandWithFrame:rect];
//    [_strokeColor setStroke];
//    [_bezierPath stroke];
}

@end
