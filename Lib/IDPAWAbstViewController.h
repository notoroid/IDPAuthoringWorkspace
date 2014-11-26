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
typedef BOOL (^idp_selected_objecv_view_block_t)(IDPAWAbstRenderView *objectView);

typedef NS_ENUM(NSInteger, IDPAWAbstViewControllerEditMode )
{
    IDPAWAbstViewControllerEditModeHierarchy // 階層をpush
};

typedef NS_ENUM(NSInteger, IDPAWAbstViewControllerCommandOption )
{
     IDPAWAbstViewControllerCommandOptionDefault
    ,IDPAWAbstViewControllerCommandOptionNoEffect
};

typedef NS_ENUM(NSInteger, IDPAWAbstViewControllerMenuType )
{
     IDPAWAbstViewControllerMenuTypeGroundView
    ,IDPAWAbstViewControllerMenuTypeGroupView
};

typedef NS_ENUM(NSInteger, IDPAWAbstViewControllerSelectToolMode )
{
     IDPAWAbstViewControllerSelectToolModeRectArea
    ,IDPAWAbstViewControllerSelectToolModeLasso
};

@interface IDPAWAbstViewController : UIViewController

// GestureRecognizer
@property (readonly,nonatomic) UIRotationGestureRecognizer *rotateGestureRecognizer;

// object collection
@property (readonly,nonatomic) NSArray *selectedObjectViews;
@property (readonly,nonatomic) NSArray *objectViews;

@property (assign,nonatomic) IDPAWAbstViewControllerSelectToolMode selectToolMode;

// please override unser methods
- (UIView *) groundView; // view for gound

// Utility method
- (void) constructionAuthoringWorkspace;

- (void) addObjectView:(IDPAWAbstRenderView *) objectView;
- (void) insertObjectView:(IDPAWAbstRenderView *) objectView belowSubview:(UIView *)siblingSubview;
- (void) insertObjectView:(IDPAWAbstRenderView *) objectView aboveSubview:(UIView *)siblingSubview;
- (void) removeObjectView:(IDPAWAbstRenderView *) objectView; // for objectview recycle

// Grouped commands for object operations
- (void) beginGroupCommand;
- (void) endGroupCommand;

// removeObject
- (void) deleteSelectedObject;

// rotate object
- (void) rotateSelectedObjectWithRotation:(CGFloat)rotation;

// clear selection
- (void) clearSelection;

// select object
- (void) selectObjectViews:(NSArray *)objectViews;

// overwride method(s)
- (void)customCommandPrepare:(IDPAWAbstCommand *)command objectViews:(NSArray *)objectViews;
- (NSArray *) menuItemsWithMenuType:(IDPAWAbstViewControllerMenuType)menuType view:(UIView *)view;

// paste utilities
- (void) archiveDataWithObjectViews:(NSArray *)objectViews;
- (BOOL) hasPasteObjects;
- (NSArray *) pasteObjectsWithLocation:(CGPoint)location;
- (CGPoint) lastMenuLocation;

@property(readonly,nonatomic) IDPAWGroupView *groupView;

- (void) pushEditMode:(IDPAWAbstViewControllerEditMode)editMode inclutionBlock:(idp_hierarchy_compare_block_t)inclutionBlock exclusionBlock:(idp_hierarchy_compare_block_t)exclusionBlock;
- (void) popEditMode;

- (void) pushCommand:(IDPAWAbstCommand *)command;
- (void) popCommand;
- (void) popCommandWithOption:(IDPAWAbstViewControllerCommandOption)option;
- (NSInteger) commandNumber;
- (void) popFrontCommand;

@end

