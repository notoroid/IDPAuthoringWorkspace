//
//  GroupView.m
//  IDPAuthoringWorkspace
//
//  Created by 能登 要 on 2014/10/18.
//  Copyright (c) 2014年 Irimasu Densan Planning. All rights reserved.
//

#import "IDPAWGroupView.h"
#import "IDPAWAbstRenderView.h"

@interface IDPAWGroupView ()
{
    NSMutableArray *_hittestBezier;
}
@end

@implementation IDPAWGroupView

- (BOOL) canBecomeFirstResponder
{
    return YES;
}

- (void)copy:(id)sender
{
    NSMutableArray *renderViews = [NSMutableArray array];
    
    [self.superview.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if( obj != self ){
            IDPAWAbstRenderView *renderView = [obj isKindOfClass:[IDPAWAbstRenderView class]] ? obj : nil;
            if( [renderView isReplicableObject] ){
                renderViews[renderViews.count] = renderView;
            }
        }
    }];
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:renderViews];
    [_delegate groupViewClipboardData:data];
        // コピー作成通知
}

- (BOOL) canPerformAction:(SEL)action withSender:(id)sender
{
    BOOL result = NO;
    if( action == @selector(copy:) ){
        result = [self hasReplicableObjects];
    }
    return result;
}


- (BOOL) hasReplicableObjects
{
    __block BOOL result = NO;
    [self.superview.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if( obj != self ){
            IDPAWAbstRenderView *renderView = [obj isKindOfClass:[IDPAWAbstRenderView class]] ? obj : nil;
            if( [renderView isReplicableObject] ){
                result = YES;
                *stop = YES;
            }
        }
    }];
    return result
    ;
}

- (BOOL) hittestWithLocation:(CGPoint)location
{
    __block BOOL hitTest = NO;
    
    if( _hittestBezier == nil ){
        _hittestBezier = [NSMutableArray array];
        
        [self.superview.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if( obj != self ){
                IDPAWAbstRenderView *renderView = [obj isKindOfClass:[IDPAWAbstRenderView class]] ? obj : nil;
                const CGRect renderFrame = [self convertRect:renderView.frame fromView:renderView.superview];
                
                if( renderView.proxyRender ){
                    const CGRect renderBounds = renderView.bounds;
                    
                    UIBezierPath *bezier = [UIBezierPath bezierPathWithRect:renderBounds];
                    [bezier applyTransform:renderView.transform];
                    CGRect bezierBounds = bezier.bounds;
                    
                    CGFloat deltaX = -CGRectGetMinX(bezierBounds);
                    CGFloat deltaY = -CGRectGetMinY(bezierBounds);
                    
                    [bezier applyTransform:CGAffineTransformMakeTranslation(renderFrame.origin.x + deltaX , renderFrame.origin.y + deltaY)];
                    
                    NSLog(@"bezier.bounds=%@",[NSValue valueWithCGRect:bezier.bounds] );
                    
                    _hittestBezier[_hittestBezier.count] = bezier;
                }
            }
        }];
    }
    
    [_hittestBezier enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIBezierPath *bezier = obj;
        
        if( [bezier containsPoint:location] ){
            hitTest = YES;
            *stop = YES;
        }
    }];
    
    return hitTest;
}

- (void)drawRect:(CGRect)rect
{
    _hittestBezier = nil;
    
    [self.superview.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if( obj != self ){
            IDPAWAbstRenderView *renderView = [obj isKindOfClass:[IDPAWAbstRenderView class]] ? obj : nil;
            if( renderView.proxyRender ){
                CGContextRef context = UIGraphicsGetCurrentContext();
                CGContextSaveGState(context);

                const CGRect renderFrame = [self convertRect:renderView.frame fromView:renderView.superview];
                const CGRect renderBounds = renderView.bounds;
                
//                if( CGAffineTransformEqualToTransform(renderView.transform, CGAffineTransformIdentity) ){
//                    CGContextTranslateCTM(context,renderFrame.origin.x, renderFrame.origin.y);
//                }else{
                    UIBezierPath *bezier = [UIBezierPath bezierPathWithRect:renderBounds];
                    [bezier applyTransform:renderView.transform];
                    CGRect bezierBounds = bezier.bounds;
                    
                    CGFloat deltaX = -CGRectGetMinX(bezierBounds);
                    CGFloat deltaY = -CGRectGetMinY(bezierBounds);
                    CGContextTranslateCTM(context,renderFrame.origin.x + deltaX , renderFrame.origin.y + deltaY);
                    
                    CGAffineTransform transform = renderView.transform;
                    CGContextConcatCTM(context,transform);
//                }

                [renderView drawProxyRenderRect:(CGRect){CGPointZero,renderBounds.size}];
                
                CGContextRestoreGState(context);
            }
        }
    }];
    
//    [self drawGroupWithFrame:rect];
}

@end
