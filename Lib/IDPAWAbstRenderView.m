//
//  SARenderView.m
//  IDPAuthoringWorkspace
//
//  Created by 能登 要 on 2014/10/16.
//  Copyright (c) 2014年 Irimasu Densan Planning. All rights reserved.
//

#import "IDPAWAbstRenderView.h"

@interface IDPAWAbstRenderView ()
{
    BOOL _selected;
}
@end

@implementation IDPAWAbstRenderView

- (NSData *) serializeData
{
    return nil;
}

- (BOOL) isReplicableObject
{
    return NO;
}

- (BOOL) selected
{
    return _selected;
}

- (void) setSelected:(BOOL)selected
{
    _selected = selected;
}

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
    if(_proxyRender != YES){
        [[UIColor lightGrayColor] setFill];
        [[UIBezierPath bezierPathWithRect:rect] fill];
        
        [self drawRenderWithFrame:rect selected:_selected];
    }
}

- (void) drawProxyRenderRect:(CGRect)rect
{
    [[UIColor lightGrayColor] setFill];
    [[UIBezierPath bezierPathWithRect:rect] fill];
    
    [self drawRenderWithFrame:rect selected:_selected];
}

- (void) resizeSubViewWithBounds:(CGRect)bounds originalBounds:(CGRect)originalBounds
{
        // 空実装
}

- (BOOL) hittestWithRect:(CGRect)rect
{
    BOOL hittest = CGRectIntersectsRect(self.frame, rect);
    return hittest;
}

- (BOOL) hittestWithLocation:(CGPoint)location
{
    BOOL hittest = CGRectContainsPoint(self.frame,location);
    return hittest;
}

- (BOOL) hittestWithPath:(UIBezierPath *)path
{
    BOOL hittest = [path containsPoint:self.center];
    return hittest;
}

- (NSInteger) supportToolType
{
    return 0;
}

@end
