//
//  IDPAWTrackerView.m
//  IDPAuthoringWorkspace
//
//  Created by 能登 要 on 2014/10/19.
//  Copyright (c) 2014年 Irimasu Densan Planning. All rights reserved.
//

#import "IDPAWTrackerView.h"

@implementation IDPAWTrackerView

- (void)drawTrackerWithFrame: (CGRect)frame;
{
    //// Color Declarations
    UIColor* color = [UIColor colorWithRed: 0.262 green: 0.871 blue: 0.312 alpha: 1];
    
    //// Rectangle Drawing
    UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(CGRectGetMinX(frame) + floor(CGRectGetWidth(frame) * 0.26087 + 0.5), CGRectGetMinY(frame) + floor(CGRectGetHeight(frame) * 0.26087 + 0.5), floor(CGRectGetWidth(frame) * 0.73913 + 0.5) - floor(CGRectGetWidth(frame) * 0.26087 + 0.5), floor(CGRectGetHeight(frame) * 0.73913 + 0.5) - floor(CGRectGetHeight(frame) * 0.26087 + 0.5)) cornerRadius: 4];
    [UIColor.whiteColor setFill];
    [rectanglePath fill];
    [color setStroke];
    rectanglePath.lineWidth = 2;
    [rectanglePath stroke];
}

- (void)drawRect:(CGRect)rect
{
    if( _enterTraking != YES ){
        [self drawTrackerWithFrame:rect];
    }
}

@end
