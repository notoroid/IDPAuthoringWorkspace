//
//  IDPAWAbstRenderView.h
//  IDPAuthoringWorkspace
//
//  Created by 能登 要 on 2014/10/16.
//  Copyright (c) 2014年 Irimasu Densan Planning. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IDPAWAbstRenderView : UIView

@property(assign,nonatomic) BOOL selected;
@property(assign,nonatomic) BOOL proxyRender;
@property(assign,nonatomic) NSInteger parentHierarchyTag;
@property(assign,nonatomic) NSInteger hierarchyTag;
- (void) drawProxyRenderRect:(CGRect)rect;
- (void) resizeSubViewWithBounds:(CGRect)bounds originalBounds:(CGRect)originalBounds;
- (BOOL) hittestWithRect:(CGRect)rect;
- (BOOL) hittestWithLocation:(CGPoint)location;
- (BOOL) isReplicableObject;

- (NSData *) serializeData;
- (instancetype) initWithCoder:(NSCoder *)aDecoder;
@end


