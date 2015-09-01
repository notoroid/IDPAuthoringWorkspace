//
//  IDPAWAbstRenderView.h
//  IDPAuthoringWorkspace
//
//  Created by 能登 要 on 2014/10/16.
//  Copyright (c) 2014年 Irimasu Densan Planning. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_OPTIONS(NSInteger, IDPAWAbstRenderViewSupportToolType )
{
     IDPAWAbstRenderViewSupportToolTypeNoTracker = 0x1
//    ,IDPAWAbstRenderViewSupportToolTypeNoRotation = 0x2
};

@interface IDPAWAbstRenderView : UIView

@property(assign,nonatomic) BOOL selected;
@property(assign,nonatomic) BOOL proxyRender;
@property(assign,nonatomic) NSInteger parentHierarchyTag;
@property(assign,nonatomic) NSInteger hierarchyTag;
- (void) drawProxyRenderRect:(CGRect)rect;
- (void) resizeSubViewWithBounds:(CGRect)bounds originalBounds:(CGRect)originalBounds;
- (BOOL) hittestWithRect:(CGRect)rect;
- (BOOL) hittestWithLocation:(CGPoint)location;
- (BOOL) hittestWithPath:(UIBezierPath *)path;
- (BOOL) isReplicableObject;
- (NSInteger) supportToolType;
@end


