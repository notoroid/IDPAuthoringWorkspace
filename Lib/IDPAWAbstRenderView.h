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
- (void) drawProxyRenderRect:(CGRect)rect;
- (void) resizeSubViewWithBounds:(CGRect)bounds originalBounds:(CGRect)originalBounds;
@end


