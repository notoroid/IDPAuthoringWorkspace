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

// GestureRecognizer
@property (readonly,nonatomic) UIRotationGestureRecognizer *rotateGestureRecognizer;

// object collection
@property (readonly,nonatomic) NSArray *selectedObjectViews;
@property (readonly,nonatomic) NSArray *objectViews;

// please override unser methods
- (UIView *) groundView; // view for gound

// Utility method
- (void) constructionAuthoringWorkspace;

- (void) addObjectView:(IDPAWAbstRenderView *) objectView;
- (void) insertObjectView:(IDPAWAbstRenderView *) objectView belowSubview:(UIView *)siblingSubview;
- (void) insertObjectView:(IDPAWAbstRenderView *) objectView aboveSubview:(UIView *)siblingSubview;
- (void) removeObjectView:(IDPAWAbstRenderView *) objectView; // for objectview recycle

- (void) deleteSelectedObject;

- (void) rotateSelectedObjectWithRotation:(CGFloat)rotation;

- (void) clearSelection;

- (void) selectObjectViews:(NSArray *)objectViews;

@end

