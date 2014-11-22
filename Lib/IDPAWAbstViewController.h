//
//  IDPAWAbstViewController.h
//  IDPAuthoringWorkspace
//
//  Created by 能登 要 on 2014/10/16.
//  Copyright (c) 2014年 Irimasu Densan Planning. All rights reserved.
//

#import <UIKit/UIKit.h>

@class IDPAWAbstRenderView;
@class IDPAWGroupView;
@class IDPAWAbstCommand;

typedef BOOL (^idp_hierarchy_compare_block_t)(IDPAWAbstRenderView *objectView);

typedef NS_ENUM(NSInteger, IDPAWAbstViewControllerEditMode )
{
    IDPAWAbstViewControllerEditModeHierarchy // 階層をpush
};

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

// removeObject
- (void) deleteSelectedObject;

// rotate object
- (void) rotateSelectedObjectWithRotation:(CGFloat)rotation;

// clear selection
- (void) clearSelection;

// select object
- (void) selectObjectViews:(NSArray *)objectViews;

@property(readonly,nonatomic) IDPAWGroupView *groupView;

- (void) pushEditMode:(IDPAWAbstViewControllerEditMode)editMode compare:(idp_hierarchy_compare_block_t)compare;
- (void) popEditMode;

- (void) pushCommand:(IDPAWAbstCommand *)command;
- (void) popCommand;
- (NSInteger) commandNumber;
- (void) popFrontCommand;

@end

