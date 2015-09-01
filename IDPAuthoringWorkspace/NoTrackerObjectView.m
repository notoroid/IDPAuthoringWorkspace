//
//  NoTrackerObjectView.m
//  IDPAuthoringWorkspace
//
//  Created by 能登 要 on 2015/09/01.
//  Copyright (c) 2015年 Irimasu Densan Planning. All rights reserved.
//

#import "NoTrackerObjectView.h"

@implementation NoTrackerObjectView

- (void)drawRenderWithFrame: (CGRect)frame selected: (BOOL)selected;
{
    if (selected)
    {
        //// Rectangle Drawing
        UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRect: CGRectMake(CGRectGetMinX(frame) + 0.5, CGRectGetMinY(frame) + 0.5, CGRectGetWidth(frame) - 1, CGRectGetHeight(frame) - 1)];
        [UIColor.redColor setStroke];
        rectanglePath.lineWidth = 1;
        [rectanglePath stroke];
    }
}

- (void)drawRect:(CGRect)rect {
    if(self.proxyRender != YES){
        [[UIColor lightGrayColor] setFill];
        [[UIBezierPath bezierPathWithRect:rect] fill];
        
        [self drawRenderWithFrame:rect selected:self.selected];
    }
}

- (void) drawProxyRenderRect:(CGRect)rect
{
    [[UIColor lightGrayColor] setFill];
    [[UIBezierPath bezierPathWithRect:rect] fill];
    
    [self drawRenderWithFrame:rect selected:self.selected];
}

- (NSInteger) supportToolType
{
    return IDPAWAbstRenderViewSupportToolTypeNoTracker | IDPAWAbstRenderViewSupportToolTypeNoRotation;
}

@end
