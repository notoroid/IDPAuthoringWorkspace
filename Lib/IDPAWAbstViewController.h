//
//  IDPAWAbstViewController.h
//  IDPAuthoringWorkspace
//
//  Created by 能登 要 on 2014/10/16.
//  Copyright (c) 2014年 Irimasu Densan Planning. All rights reserved.
//

#import <UIKit/UIKit.h>

@class IDPAWAbstRenderView;

@interface IDPAWAbstViewController : UIViewController

// please override unser methods
- (UIView *) groundView; // view for gound

// Utility method
- (void) constructionAuthoringWorkspace;

- (void) addObjectView:(IDPAWAbstRenderView *) objectView;

- (void) deleteSelectedObject;

- (void) rotateSelectedObjectWithRotation:(CGFloat)rotation;

- (void) clearSelection;

- (void) selectObjectViews:(NSArray *)objectViews;

- (NSArray *)selectedObjectViews;

@end

