//
//  GroupFrameView.m
//  IDPAuthoringWorkspace
//
//  Created by 能登 要 on 2014/10/20.
//  Copyright (c) 2014年 Irimasu Densan Planning. All rights reserved.
//

#import "IDPAWGroupFrameView.h"

@implementation IDPAWGroupFrameView

- (void)drawGroupWithFrame: (CGRect)frame;
{
    //// Color Declarations
    UIColor* color = [UIColor colorWithRed: 0.262 green: 0.871 blue: 0.312 alpha: 1];
    
    //// Rectangle Drawing
    UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRect: CGRectMake(CGRectGetMinX(frame) + 0.5, CGRectGetMinY(frame) + 0.5, CGRectGetWidth(frame) - 1, CGRectGetHeight(frame) - 1)];
    [color setStroke];
    rectanglePath.lineWidth = 1;
    [rectanglePath stroke];
}

- (void)drawRect:(CGRect)rect
{
    [self drawGroupWithFrame:rect];
}
@end
