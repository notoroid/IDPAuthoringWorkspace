//
//  IDPAWStyleKit.m
//  IDPAuthoringWorkspace
//
//  Created by 能登 要 on 2015/06/23.
//  Copyright (c) 2015 Irimasu Densan Planning. All rights reserved.
//
//  Generated by PaintCode (www.paintcodeapp.com)
//

#import "IDPAWStyleKit.h"


@implementation IDPAWStyleKit

#pragma mark Initialization

+ (void)initialize
{
}

#pragma mark Drawing Methods

+ (void)drawTrackerWithFrame: (CGRect)frame
{
    //// Color Declarations
    UIColor* color = [UIColor colorWithRed: 0.26 green: 0.87 blue: 0.31 alpha: 1];
    UIColor* color2 = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 1];

    //// Oval Drawing
    UIBezierPath* ovalPath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(CGRectGetMinX(frame) + floor((CGRectGetWidth(frame) - 11) * 0.50000 + 0.5), CGRectGetMinY(frame) + floor((CGRectGetHeight(frame) - 11) * 0.50000 + 0.5), 11, 11)];
    [color2 setFill];
    [ovalPath fill];
    [color setStroke];
    ovalPath.lineWidth = 2;
    [ovalPath stroke];
}

@end