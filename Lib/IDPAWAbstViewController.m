//
//  IDPAWAbstViewController.m
//  IDPAuthoringWorkspace
//
//  Created by 能登 要 on 2014/10/16.
//  Copyright (c) 2014年 Irimasu Densan Planning. All rights reserved.
//

#import "IDPAWAbstViewController.h"
#import "IDPAWAbstRenderView.h"
#import "IDPAWBandView.h"
#import "IDPAWGroupView.h"
#import "IDPAWTrackerView.h"
@import AVFoundation;
#import "IDPAWGroupFrameView.h"
@import QuartzCore;
#import "IDPAWAddCommand.h"
#import "IDPAWDeleteCommand.h"
#import "IDPAWMoveCommand.h"
#import "IDPAWGroupedCommand.h"
#import "IDPAWResizeCommand.h"
#import "IDPAWTransformCommand.h"

//static double degreesToRadians(double degrees);
//static double degreesToRadians(double degrees) {return degrees * M_PI / 180;}

//static double radiansToDegrees(double radians);
//static double radiansToDegrees(double radians) {return radians * 180 / M_PI;}

static NSInteger s_hierarchyTag = 0;

typedef NS_ENUM(NSInteger, IDPAWGestureTargetType)
{
     IDPAWGestureTargetTypeNone
    ,IDPAWGestureTargetTypeGround
    ,IDPAWGestureTargetTypeRenderObject
};


@interface IDPAWEditModeObject : NSObject
@property (nonatomic) IDPAWAbstViewControllerEditMode editMode;
@property (nonatomic) NSMutableDictionary *viewsByHierarchyTag;
@property (copy,nonatomic) idp_hierarchy_compare_block_t inclutionBlock;
- (instancetype) initWithEditMode:(IDPAWAbstViewControllerEditMode)editMode;
@end

@implementation IDPAWEditModeObject
- (instancetype) initWithEditMode:(IDPAWAbstViewControllerEditMode)editMode
{
    self = [super init];
    if( self != nil ){
        _editMode = editMode;
        _viewsByHierarchyTag = [NSMutableDictionary dictionary];
    }
    return self;
}
@end


@interface IDPAWAbstViewController () <UIGestureRecognizerDelegate,IDPAWGroupViewDelegate>
{
    BOOL _initialized;
    
    UIGestureRecognizer *_groundTapGesture; // Ground用Tapジェスチャ
    UIRotationGestureRecognizer *_groundRotateGesture;
    UIPanGestureRecognizer *_groupPanGesture;
    IDPAWGestureTargetType _gestureTargetType;
    IDPAWAbstRenderView *_targetRenderView;
    
    CGPoint _startPosition; // バンドの開始位置
    IDPAWBandView *_bandView; // バンド用View
    
    NSInteger _counter;
    NSValue *_firstPoint;
    CGPoint _points[5];
    UIBezierPath *_pathLasso;
    
    IDPAWGroupView *_groupView; // グループ状態表示用View
    NSArray *_trackers; // Tracker用配列
    IDPAWTrackerView *_dummyTrackerView; // ダミートラッカー用View
    CGRect _safetyBounds; // (Trackerドラッグ用)安全領域情報
    NSValue *_locationForObjectMove; // オブジェクト移動用位置
    
    CGPoint _originalGroupCenter;
    CGRect _originalGroupFrame; // グループサイズ変更時のオリジナルサイズ
    
    NSMutableArray *_hierarchies;
    
    UIMenuController* _menu; // メニュー
    NSValue *_menuPosition;
    id _menuObserver;
    
    NSMutableArray *_commands;
    NSMutableArray *_groupCommandObjectViews;
    NSMutableArray *_groupCommands;
    NSMutableArray *_redoCommands;
    
    NSNumber *_trackerMargin;
}
@property(readonly,nonatomic) IDPAWBandView *bandView;
@property(readonly,nonatomic) IDPAWGroupFrameView *groupFrameView;
@property(readonly,nonatomic) NSArray *trackers;
@property(readonly,nonatomic) IDPAWTrackerView *dummyTrackerView;

@property(readonly,nonatomic) UIPanGestureRecognizer *objectPanGestureRecognizer;
@property(readonly,nonatomic) UITapGestureRecognizer *objectTapGestureRecognizer;
//@property(readonly,nonatomic) DegreeInputView *degreeInputView;
@property(readonly,nonatomic) NSMutableArray *hierarchies;
@property (readonly,nonatomic) NSMutableArray *commands;
@property (readonly,nonatomic) NSMutableArray *redoCommands;
@end

@implementation IDPAWAbstViewController

- (UIRotationGestureRecognizer *)rotateGestureRecognizer
{
    return _groundRotateGesture;
}

- (NSMutableArray *)hierarchies
{
    if( _hierarchies == nil ){
        _hierarchies = [NSMutableArray array];
    }
    return _hierarchies;
}

- (NSMutableArray *)commands
{
    if( _commands == nil ){
        _commands = [NSMutableArray array];
    }
    return _commands;
}

- (NSMutableArray *)redoCommands
{
    if( _redoCommands == nil ){
        _redoCommands = [NSMutableArray array];
    }
    return _redoCommands;
}

- (IBAction)firedDelete:(id)sender
{
    [self deleteSelectedObject];
}

/**
 *  BandViewの生成
 *
 *  @return BandViewのインスタンス
 */
- (IDPAWBandView *)bandView
{
    if( _bandView == nil ){
        _bandView = [[IDPAWBandView alloc] initWithFrame:CGRectZero];
        _bandView.backgroundColor = [UIColor clearColor];
        _bandView.opaque = NO;
        _bandView.userInteractionEnabled = NO;
    }
    return _bandView;
}

/**
 *  GroupFrameViewのインスタンス
 *
 *  @return GroupFrameViewのインスタンス
 */
- (IDPAWGroupFrameView *)groupFrameView
{
    return _groupView.subviews.count > 0 ? _groupView.subviews[0] : nil;
}


/**
 *  アーカイブからレジューム
 *
 *  @param objectView アーカイブしたオブジェクト
 */
- (void) resumeObjectFromArchivedData:(UIView *)view
{
    IDPAWAbstRenderView *renderView = [view isKindOfClass:[IDPAWAbstRenderView class]] ? (IDPAWAbstRenderView *)view : nil;
    [self addGestureWithView:renderView];
    
}


/**
 *  GroupViewのインスタンスを返す
 *
 *  @return GroupViewのインスタンス
 */
- (IDPAWGroupView *)groupView
{
    if( _groupView == nil ){
        _groupView = [[IDPAWGroupView alloc] initWithFrame:(CGRect){CGPointZero,CGSizeMake(20.0, 20.0f)}];
        _groupView.delegate = self;
        _groupView.backgroundColor = [UIColor clearColor];
        _groupView.opaque = NO;
        _groupView.userInteractionEnabled = YES;
        
        _groupPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(firedGroupPan:)];
        _groupPanGesture.delegate = self;
        [_groupView addGestureRecognizer:_groupPanGesture];
        
        if( [self.groundView.superview isKindOfClass:[UIScrollView class]] ){
            UIScrollView *scrolView = (UIScrollView * )self.groundView.superview;
            [scrolView.panGestureRecognizer requireGestureRecognizerToFail:_groupPanGesture];
        }
        
        // GroupFrameViewを生成しsubviewとして追加
        IDPAWGroupFrameView *groupFrameView = [[IDPAWGroupFrameView alloc] initWithFrame:(CGRect){CGPointZero,CGSizeMake(20.0, 20.0f)}];
        groupFrameView.backgroundColor = [UIColor clearColor];
        groupFrameView.opaque = NO;
        groupFrameView.userInteractionEnabled = NO;
        groupFrameView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [_groupView addSubview:groupFrameView];
    }
    return _groupView;
}

/**
 *  Trackerのコレクションの生成
 *
 *  @return TrackerViewのコレクション
 */
- (NSArray *)trackers
{
    if( _trackers == nil ){
        UIPanGestureRecognizer *lowPriorityPanGesture = _groupPanGesture;
        
        NSMutableArray *trackers = [NSMutableArray array];
        for( NSInteger i = 0;i < 4;i++){
#define IDPAW_TRACKER_EDGE 23.0
            IDPAWTrackerView *trackerView= [[IDPAWTrackerView alloc] initWithFrame:(CGRect){CGPointZero,CGSizeMake(IDPAW_TRACKER_EDGE,IDPAW_TRACKER_EDGE)}];
            trackerView.backgroundColor = [UIColor clearColor];
            trackerView.opaque = NO;
            trackerView.userInteractionEnabled = YES;
            trackers[trackers.count] = trackerView;
            
            UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(firedTrackerPan:)];
            [trackerView addGestureRecognizer:panGesture];
            
            if( [self.groundView.superview isKindOfClass:[UIScrollView class]] ){
                UIScrollView *scrolView = (UIScrollView * )self.groundView.superview;
                [scrolView.panGestureRecognizer requireGestureRecognizerToFail:panGesture];
            }
            
            
            [lowPriorityPanGesture requireGestureRecognizerToFail:panGesture];
            lowPriorityPanGesture = panGesture;
        }
        _trackers = [NSArray arrayWithArray:trackers];
    }
    return _trackers;
}

/**
 *  DummyTrackerの生成
 *
 *  @return TrackerViewを生成する
 */
- (IDPAWTrackerView *) dummyTrackerView
{
    if( _dummyTrackerView == nil ){
        _dummyTrackerView = [[IDPAWTrackerView alloc] initWithFrame:(CGRect){CGPointZero,CGSizeMake(IDPAW_TRACKER_EDGE,IDPAW_TRACKER_EDGE)}];
        _dummyTrackerView.backgroundColor = [UIColor clearColor];
        _dummyTrackerView.opaque = NO;
        _dummyTrackerView.userInteractionEnabled = YES;
    }
    return _dummyTrackerView;
}

/**
 *  地のviewを返す
 *
 *  @return 地のオブジェクトのインスタンス
 */
- (UIView *) groundView
{
    return self.view;
}

/**
 *  編集スペースの構築
 */
- (void) constructionAuthoringWorkspace
{
    _groundTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(firedGroundTap:)];
    _groundTapGesture.delegate = self;
    [self.groundView addGestureRecognizer:_groundTapGesture];
        // Tapジェスチャを追加
    
    _authoringWorkspacePanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanHandle:)];
    _authoringWorkspacePanGestureRecognizer.delegate = self;
    [self.groundView addGestureRecognizer:_authoringWorkspacePanGestureRecognizer];
        // Panジェスチャを追加
    if( [self.groundView.superview isKindOfClass:[UIScrollView class]] ){
        UIScrollView *scrolView = (UIScrollView * )self.groundView.superview;
        [scrolView.panGestureRecognizer requireGestureRecognizerToFail:_authoringWorkspacePanGestureRecognizer];
    }
    
    _groundRotateGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(firedGroundRotate:)];
    _groundRotateGesture.delegate = self;
    [self.groundView addGestureRecognizer:_groundRotateGesture];
        // Rotateジェスチャを追加
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:_menuObserver];
}

- (void)groupViewArchiveDataWithObjectViews:(NSArray *)objectViews
{
    [self archiveDataWithObjectViews:objectViews];
}

- (void) addGestureWithView:(UIView *)view
{
    UITapGestureRecognizer *tapGestureRecognizer = view != nil ? [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(firedObjectTap:)] : nil;
    tapGestureRecognizer.delegate = self;
    [view addGestureRecognizer:tapGestureRecognizer];
        // ジェスチャを追加
}

- (NSArray *) menuItemsWithMenuType:(IDPAWAbstViewControllerMenuType)menuType view:(UIView *)view
{
    return nil;
}

- (void) archiveDataWithObjectViews:(NSArray *)objectViews
{
    // 空実装
}

- (BOOL) hasPasteObjects
{
    return NO;
}

- (NSArray *) pasteObjectsWithLocation:(CGPoint)location
{
    return nil;
}

- (CGPoint) lastMenuLocation
{
    return [_menuPosition CGPointValue];
}

- (IDPAWCommandPrepareBlock) commandBlock
{
    __weak IDPAWAbstViewController *weakSelf = self;
    
    IDPAWCommandPrepareBlock block = ^(IDPAWAbstCommand *command,NSArray *objectViews) {
        if( [command isKindOfClass:[IDPAWAddCommand class]] ){
            IDPAWAbstRenderView *addObjectView = objectViews.count > 0 ? objectViews[0] : nil;
            
            [weakSelf addGestureWithView:addObjectView];
                // GestureRecognizer を付与
            
            // 衝突判定
            [weakSelf selectedObjectViewWithBlock:^BOOL(IDPAWAbstRenderView *objectView) {
                return addObjectView == objectView ? YES : NO;
            }];
        }else if( [command isKindOfClass:[IDPAWDeleteCommand class]] ){
            IDPAWAbstRenderView *objectView = objectViews.count > 0 ? objectViews[0] : nil;
            
            // GestureRecognizer を削除
            while (objectView.gestureRecognizers.count) {
                [objectView removeGestureRecognizer:objectView.gestureRecognizers[0]];
            }
            
            // グループを除外
            [weakSelf.groupView removeFromSuperview];
            [weakSelf synchronizeTracker];
                // グループに合わせてトラッカーを無効化
        }else if( [command isKindOfClass:[IDPAWMoveCommand class]] ){
            IDPAWAbstRenderView *movedObjectView = objectViews.count > 0 ? objectViews[0] : nil;
            
            // 衝突判定
            [weakSelf selectedObjectViewWithBlock:^BOOL(IDPAWAbstRenderView *objectView) {
                return movedObjectView == objectView ? YES : NO;
            }];
        }else if( [command isKindOfClass:[IDPAWResizeCommand class]] ){
            IDPAWAbstRenderView *resizedObjectView = objectViews.count > 0 ? objectViews[0] : nil;
            
            // 衝突判定
            [weakSelf selectedObjectViewWithBlock:^BOOL(IDPAWAbstRenderView *objectView) {
                return resizedObjectView == objectView ? YES : NO;
            }];
        }else if( [command isKindOfClass:[IDPAWGroupedCommand class]] ){
            // 衝突判定
            [weakSelf selectedObjectViewWithBlock:^BOOL(IDPAWAbstRenderView *objectView) {
                return [objectViews containsObject:objectView];
            }];
        }
        
        [weakSelf customCommandPrepare:command objectViews:objectViews];

    };
    return block;
}
             
- (void)customCommandPrepare:(IDPAWAbstCommand *)command objectViews:(NSArray *)objectViews
{

}

// Grouped commands for object operations
- (void) beginGroupCommand
{
    _groupCommandObjectViews = [NSMutableArray array];
    _groupCommands = [NSMutableArray array];
}

- (void) pushGroupedComannd:(IDPAWAbstCommand *)command objectView:(IDPAWAbstRenderView *) objectView
{
    if( _groupCommands != nil ){
        _groupCommandObjectViews[_groupCommandObjectViews.count] = objectView;
        _groupCommands[_groupCommands.count] = command;
    }
}

- (void) endGroupCommand
{
    if( _groupCommands != nil ){
        [self pushCommand:[IDPAWGroupedCommand groupedCommandWithCommands:_groupCommands objectViews:_groupCommandObjectViews block:[self commandBlock]]];
        
        _groupCommandObjectViews = nil;
        _groupCommands = nil;
    }
}

- (void) addObjectView:(IDPAWAbstRenderView *) objectView
{
    [self addGestureWithView:objectView];
    // GestureRecognizer を付与
    
    [self.groundView addSubview:objectView];
    
    IDPAWAbstCommand *command = [IDPAWDeleteCommand deleteCommandWithView:objectView block:[self commandBlock]];
    if( _groupCommands != nil ){
        _groupCommandObjectViews[_groupCommandObjectViews.count] = objectView;
        _groupCommands[_groupCommands.count] = command;
    }else{
        [self pushCommand:command];
        // commandを追加
    }
}

- (void) insertObjectView:(IDPAWAbstRenderView *) objectView belowSubview:(UIView *)siblingSubview
{
    [self addGestureWithView:objectView];
    // GestureRecognizer を付与
    
    [self.groundView insertSubview:objectView belowSubview:siblingSubview];
    
    
    IDPAWAbstCommand *command = [IDPAWDeleteCommand deleteCommandWithView:objectView block:[self commandBlock]];
    if( _groupCommands != nil ){
        _groupCommandObjectViews[_groupCommandObjectViews.count] = objectView;
        _groupCommands[_groupCommands.count] = command;
    }else{
        [self pushCommand:command];
        // commandを追加
    }
}

- (void) insertObjectView:(IDPAWAbstRenderView *) objectView aboveSubview:(UIView *)siblingSubview
{
    [self addGestureWithView:objectView];
    // GestureRecognizer を付与
    
    [self.groundView insertSubview:objectView aboveSubview:siblingSubview];
    
    IDPAWAbstCommand *command = [IDPAWDeleteCommand deleteCommandWithView:objectView block:[self commandBlock]];
    if( _groupCommands != nil ){
        _groupCommandObjectViews[_groupCommandObjectViews.count] = objectView;
        _groupCommands[_groupCommands.count] = command;
    }else{
        [self pushCommand:command];
        // commandを追加
    }
    
}


- (void) removeObjectView:(IDPAWAbstRenderView *) objectView
{
    IDPAWAbstCommand *command = [IDPAWAddCommand addCommandWithView:objectView block:[self commandBlock]];
    if( _groupCommands != nil ){
        _groupCommandObjectViews[_groupCommandObjectViews.count] = objectView;
        _groupCommands[_groupCommands.count] = command;
    }else{
        [self pushCommand:command];
        // commandを追加
    }
    
    while (objectView.gestureRecognizers.count) {
        [objectView removeGestureRecognizer:objectView.gestureRecognizers[0]];
    }
    
    [objectView removeFromSuperview];
}

- (NSArray *)selectedObjectViews
{
    NSMutableArray *selectedTargets = [NSMutableArray array];

    // 選択オブジェクトを抽出する
    [self.groundView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        IDPAWAbstRenderView *renderView = [obj isKindOfClass:[IDPAWAbstRenderView class]] ? obj : nil;
        if( renderView.selected == YES ){
            selectedTargets[selectedTargets.count] = renderView;
        }
    }];
    
    return [NSArray arrayWithArray:selectedTargets];
}

- (NSArray *)objectViews
{
    NSMutableArray *objects = [NSMutableArray array];
    
    // オブジェクトを抽出する
    [self.groundView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        IDPAWAbstRenderView *renderView = [obj isKindOfClass:[IDPAWAbstRenderView class]] ? obj : nil;
        if( renderView != nil ){
            objects[objects.count] = renderView;
        }
    }];
    return objects;
}

- (void) deleteSelectedObject
{
    NSMutableArray *deleteTarget = [NSMutableArray array];
    
    // 既存の選択状態を無効化
    [self.groundView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        IDPAWAbstRenderView *renderView = [obj isKindOfClass:[IDPAWAbstRenderView class]] ? obj : nil;
        if( renderView.selected == YES ){
            renderView.selected = NO;
            
            renderView.proxyRender = NO;
                // proxyRenderを無効にする
            
            deleteTarget[deleteTarget.count] = renderView;
        }
    }];
    
    [self beginGroupCommand];
    {
        [deleteTarget enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [self removeObjectView:obj];
        }];
    }
    [self endGroupCommand];

    // グループを除外
    [self.groupView removeFromSuperview];
    [self synchronizeTracker];
        // グループに合わせてトラッカーを無効化
}

- (void) rotateSelectedObjectWithRotations:(NSArray *)rotations
{
    NSMutableArray *commands = [NSMutableArray array];
    NSMutableArray *objectViews = [NSMutableArray array];
    
    [rotations enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGFloat rotation = [(NSNumber *)obj doubleValue];
        self.groupView.transform = CGAffineTransformMakeRotation(rotation);
        
        UIView *testView = [[UIView alloc] initWithFrame:(CGRect){CGPointZero,CGSizeMake(10,10)}];
        
        [self.groundView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            IDPAWAbstRenderView *renderView = [obj isKindOfClass:[IDPAWAbstRenderView class]] ? obj : nil;
            if( renderView.selected == YES ){
                objectViews[objectViews.count] = renderView;
                commands[commands.count] = [IDPAWTransformCommand transformCommandWithView:renderView location:renderView.center transform:renderView.transform block:[self commandBlock]];
                    // コマンドを作成
                
                // 回転を適用
                CGAffineTransform transform = CGAffineTransformConcat(renderView.transform, self.groupView.transform);
                renderView.transform = transform;
                
                // 位置を変更
                /*CGAffineTransform*/ transform = self.groupView.transform;
                self.groupView.transform = CGAffineTransformIdentity;
                
                testView.center = [self.groupView convertPoint:renderView.center fromView:self.groundView];
                [self.groupView addSubview:testView];
                
//                NSLog(@"testView.center=%@",[NSValue valueWithCGPoint:[self.groundView convertPoint:testView.center fromView:self.groupView]]);
                
                self.groupView.transform = transform;
                
//                NSLog(@"testView.center=%@",[NSValue valueWithCGPoint:[self.groundView convertPoint:testView.center fromView:self.groupView]]);
                
                renderView.center = [self.groundView convertPoint:testView.center fromView:self.groupView];
                // 変換
                
                [testView removeFromSuperview];
            }
        }];
        
        
        self.groupView.transform = CGAffineTransformIdentity;
        
        // サイズを正規化
        __block CGRect rectGroup = CGRectNull;
        [self.groundView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            IDPAWAbstRenderView *renderView = [obj isKindOfClass:[IDPAWAbstRenderView class]] ? obj : nil;
            if (renderView.selected == YES ) {
                if( CGRectIsNull(rectGroup) ){
                    rectGroup =  renderView.frame;
                }else{
                    rectGroup =  CGRectUnion(rectGroup,renderView.frame);
                }
            }
        }];
        
        self.groupView.frame = _originalGroupFrame = rectGroup;
    }];
    
    
    [self pushCommand:[IDPAWGroupedCommand groupedCommandWithCommands:commands objectViews:objectViews block:[self commandBlock]]];
        // コマンド追加
    
    [self.groupView setNeedsDisplay];
    [self synchronizeTracker];
    
}

- (void) moveSelectedObjectWithOffset:(CGPoint)offset
{
    NSMutableArray *commands = [NSMutableArray array];
    NSMutableArray *objectViews = [NSMutableArray array];
    
    [self.groundView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        IDPAWAbstRenderView *renderView = [obj isKindOfClass:[IDPAWAbstRenderView class]] ? obj : nil;
        if( renderView.selected == YES ){
            objectViews[objectViews.count] = renderView;
            
            commands[commands.count] = [IDPAWMoveCommand moveCommandWithView:renderView location:renderView.center block:[self commandBlock]];
                    // コマンドを作成
            
            CGPoint location = CGPointMake(renderView.center.x + offset.x,renderView.center.y + offset.y);
            
            renderView.center = location;
                // 変換
        }
    }];
    
    [self pushCommand:[IDPAWGroupedCommand groupedCommandWithCommands:commands objectViews:objectViews block:[self commandBlock]]];
    // コマンド追加
    
    CGPoint location = CGPointMake(self.groupView.center.x + offset.x,self.groupView.center.y + offset.y);
    self.groupView.center = location;
    
    [self.groupView setNeedsDisplay];
    [self synchronizeTracker];
    
}

- (void) clearSelection
{
    // 既存の選択状態を無効化
    [self.groundView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        IDPAWAbstRenderView *renderView = [obj isKindOfClass:[IDPAWAbstRenderView class]] ? obj : nil;
        if( renderView.selected == YES ){
            renderView.selected = NO;
        }
    }];
    
    // グループを除外
    [self.groupView removeFromSuperview];
    [self synchronizeTracker];
        // グループに合わせてトラッカーを無効化
}

- (void) selectObjectViews:(NSArray *)objectViews
{
    [objectViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        IDPAWAbstRenderView *renderView = [obj isKindOfClass:[IDPAWAbstRenderView class]] ? obj : nil;
        renderView.selected = YES;
    }];
    
    // コード整理必須
    __block CGRect rectGroup = CGRectNull;
    [self.groundView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        IDPAWAbstRenderView *renderView = [obj isKindOfClass:[IDPAWAbstRenderView class]] ? obj : nil;
        // subviewからRenderViewを用意
        
        if (renderView != nil ) {
            // 矩形衝突が認められた場合
            if( renderView.selected ){
                renderView.selected = YES;
                [renderView setNeedsDisplay];
                
                if( CGRectIsNull(rectGroup) ){
                    rectGroup =  renderView.frame;
                }else{
                    rectGroup =  CGRectUnion(rectGroup,renderView.frame);
                }
                
            }else{
                renderView.selected = NO;
                renderView.proxyRender = NO;
                [renderView setNeedsDisplay];
            }
        }
        
    }];
    
    // 未選択の場合
    if( CGRectIsNull(rectGroup) ){
        // 選択状態を解除
        [self.groundView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            IDPAWAbstRenderView *renderView = [obj isKindOfClass:[IDPAWAbstRenderView class]] ? obj : nil;
            if( renderView.selected == YES ){
                renderView.proxyRender = NO;
                [renderView setNeedsDisplay];
            }
        }];
        
        // グループを除外
        [self.groupView removeFromSuperview];
        [self synchronizeTracker];
    }else{
        // グループ領域を設定
        self.groupView.frame = _originalGroupFrame = rectGroup;
        [self.groupView setNeedsDisplay];
        [self.groupFrameView setNeedsDisplay];
        
        // グループをgroundViewのsubviewに設定
        [self.groundView addSubview:self.groupView];
        [self synchronizeTracker];
        
        if( objectViews.count == 1 ){
            IDPAWAbstRenderView *renderView = objectViews[0];
            if( renderView.supportToolType & IDPAWAbstRenderViewSupportToolTypeNoTracker ){
                [self removeTrackers];
                    // トラッカーを除外
            }
        }
        
        // 選択状態を有効化
        [self.groundView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            IDPAWAbstRenderView *renderView = [obj isKindOfClass:[IDPAWAbstRenderView class]] ? obj : nil;
            if( renderView.selected == YES ){
                renderView.proxyRender = YES;
                [renderView setNeedsDisplay];
            }
        }];
    }
    
}

- (void) pushEditMode:(IDPAWAbstViewControllerEditMode)editMode inclutionBlock:(idp_hierarchy_compare_block_t)inclutionBlock exclusionBlock:(idp_hierarchy_compare_block_t)exclusionBlock
{
    switch (editMode) {
        case IDPAWAbstViewControllerEditModeHierarchy:
        {
            IDPAWEditModeObject *editModeObject = [[IDPAWEditModeObject alloc] initWithEditMode:editMode];
            editModeObject.inclutionBlock = inclutionBlock;
                // 比較オブジェクトを複製
            self.hierarchies[self.hierarchies.count] = editModeObject;
                // 階層を追加

            NSInteger lastUndoNumber = [self commandNumber];
            
            NSMutableArray *selecteObjectViews = [NSMutableArray array];

            NSArray *objectViews = self.objectViews;
            
            NSMutableArray *sortObjectViews = [NSMutableArray array];
            
            [objectViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                IDPAWAbstRenderView *renderView = [obj isKindOfClass:[IDPAWAbstRenderView class]] ? obj : nil;
                
                if( renderView != nil ){
                    // 順番を記憶
                    if( exclusionBlock(renderView) != YES ){
                        NSUInteger originalIndex = idx;
                            // インデックスを保存
                        
                        s_hierarchyTag++;
                            // タグを発行
                        
                        renderView.parentHierarchyTag = s_hierarchyTag;
                            // タグを関連づけ
                        
                        NSArray *subViews = [renderView.subviews copy];
                        [subViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                            IDPAWAbstRenderView *renderSubView = inclutionBlock(obj) ? obj : nil;
                            
                            if( renderSubView != nil ){
                                renderSubView.hierarchyTag = s_hierarchyTag;
                                
                                CGPoint center = [self.groundView convertPoint:renderSubView.center fromView:renderView];
                                
                                [renderSubView removeFromSuperview];
                                renderSubView.center = center;
                                
                                [self addObjectView:renderSubView];
                                
                                if( renderView.selected ){
                                    selecteObjectViews[selecteObjectViews.count] = renderSubView;
                                }
                                
                                renderSubView.proxyRender = NO;
                                [renderSubView setNeedsDisplay];
                                
                                NSString *sortTag = [NSString stringWithFormat:@"%06ld%06ld",originalIndex,idx];
                                [sortObjectViews addObject:@{@"renderView":renderSubView,@"sortTag":sortTag}];
                            }
                        }];
                        
                        [self removeObjectView:renderView];
                        editModeObject.viewsByHierarchyTag[@(s_hierarchyTag)] = renderView;
                    }else{
                        NSString *sortTag = [NSString stringWithFormat:@"%06ld000000",idx];
                        [sortObjectViews addObject:@{@"renderView":renderView,@"sortTag":sortTag}];
                    }
                }
            }];
            
            // Viewの順序を更新
            [sortObjectViews sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                NSDictionary *dict = obj1;
                NSString *sortTag = dict[@"sortTag"];
                NSDictionary *dict2 = obj2;
                NSString *sortTag2 = dict2[@"sortTag"];
                return [sortTag compare:sortTag2];
            }];
            
            [sortObjectViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSDictionary *dict = obj;
                IDPAWAbstRenderView *renderView = dict[@"renderView"];

                [renderView.superview bringSubviewToFront:renderView];
            }];
            
            while ([self commandNumber] > lastUndoNumber) {
                [self popCommandWithOption:IDPAWAbstViewControllerCommandOptionNoEffect];
            }
            
            [self selectObjectViews:selecteObjectViews];
                // 選択状態を更新
        }
            break;
        default:
            break;
    }
}

- (void) popEditMode
{
    IDPAWEditModeObject *editModeObject = [self.hierarchies lastObject];
        // 最後の階層を取得
    [self.hierarchies removeObject:[self.hierarchies lastObject]];
        // 階層から削除

    switch (editModeObject.editMode) {
        case IDPAWAbstViewControllerEditModeHierarchy:
        {
            NSArray *objectViews = self.objectViews;
            
            NSMutableDictionary *dictObjectViews = [NSMutableDictionary dictionary];
                // hierarchyTagをキー値としてコレクションを作成
            
            
            idp_hierarchy_compare_block_t inclutionBlock = editModeObject.inclutionBlock;
            editModeObject.inclutionBlock = nil;
                // 比較オブジェクトを解放
            
            
            [objectViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                
                IDPAWAbstRenderView *renderSubView = inclutionBlock(obj) ? obj : nil;
                
                if( renderSubView != nil ){
                    NSMutableArray *targetObjectViews = dictObjectViews[@(renderSubView.hierarchyTag)];
                    // hierarchyTagに合致した
                    if( targetObjectViews == nil ){
                        targetObjectViews = [NSMutableArray array];
                        dictObjectViews[@(renderSubView.hierarchyTag)] = targetObjectViews;
                        // コレクションに追加
                    }
                    targetObjectViews[targetObjectViews.count] = renderSubView;
                }
            }];

            NSInteger lastUndoNumber = [self commandNumber];
            
            NSMutableSet *setSelectedViews = [NSMutableSet set];
                // 選択済みviewを集めるコレクションを作成
            
            [editModeObject.viewsByHierarchyTag enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                IDPAWAbstRenderView* renderView = obj;
                
                NSMutableArray *targetObjectViews = dictObjectViews[@(renderView.parentHierarchyTag)];
                if( targetObjectViews.count ){
                    
                    // viewの矩形を再計算
                    __block CGRect rectFrame = CGRectNull;
                    [targetObjectViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        IDPAWAbstRenderView *renderSubView = obj;
                        if( CGRectIsNull(rectFrame) ){
                            rectFrame = renderSubView.frame;
                        }else{
                            rectFrame = CGRectUnion(rectFrame, renderSubView.frame);
                        }
                    }];
                    renderView.frame = rectFrame;
                    
                    [self insertObjectView:renderView belowSubview:targetObjectViews[0]];
                    // オブジェクトを追加
                    
                    [targetObjectViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        IDPAWAbstRenderView *renderSubView = obj;
                        
                        CGPoint center = [self.groundView convertPoint:renderSubView.center toView:renderView];
                        
                        // renderSubViewを一時作成
                        [self removeObjectView:renderSubView];
                        renderSubView.center = center;
                        
                        [renderView addSubview:renderSubView];
                        // renderSubVieを移動
                        
                        if (renderSubView.selected) {
                            if( [setSelectedViews containsObject:renderView] != YES ){
                                [setSelectedViews addObject:renderView];
                            }
                        }
                        renderSubView.selected = NO;
                        
                        renderSubView.proxyRender = NO;
                        [renderSubView setNeedsDisplay];
                        // 再描画を指定
                    }];
                }
            }];
            
            while ([self commandNumber] > lastUndoNumber) {
                [self popCommandWithOption:IDPAWAbstViewControllerCommandOptionNoEffect];
            }
            
            [self selectObjectViews:setSelectedViews.allObjects];
                // 選択状態を更新

        }
            break;
        default:
            break;
    }
    
}

- (void) pushCommand:(IDPAWAbstCommand *)command
{
    [self.commands addObject:command];
}

- (void) popCommand
{
    [self popCommandWithOption:IDPAWAbstViewControllerCommandOptionDefault];
}

- (void) popCommandWithOption:(IDPAWAbstViewControllerCommandOption)option
{
    switch (option) {
        case IDPAWAbstViewControllerCommandOptionDefault:
        {
            IDPAWAbstCommand *command = [self.commands lastObject];
            [self.commands removeObject:self.commands.lastObject];
            IDPAWAbstCommand *redoCommand = [command execute];
            
            if( redoCommand != nil ){
                self.redoCommands[self.redoCommands.count] = redoCommand;
                    // Redocommandを追加
            }
        }
            break;
        case IDPAWAbstViewControllerCommandOptionNoEffect:
        {
            [self.commands removeObject:self.commands.lastObject];
        }
            break;
        default:
            break;
    }
}

- (void) popRedoCommand
{
    IDPAWAbstCommand *redoCommand = [self.redoCommands lastObject];
    [self.redoCommands removeObject:self.redoCommands.lastObject];
    IDPAWAbstCommand *command = [redoCommand execute];
    
    if( command != nil ){
        self.commands[self.commands.count] = command;
            // commandを追加
    }
}

- (NSInteger) commandNumber
{
    return self.commands.count;
}

- (void) popFrontCommand
{
    if( self.commands.count > 0){
        [self.commands removeObject:self.commands.firstObject];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    __block BOOL continued = YES;
    
    if( gestureRecognizer == _groundRotateGesture ){
        if( self.groupView.superview == self.groundView ){
            // 空実装
            
            NSMutableArray *selectedObjectViews = [NSMutableArray array];
            [self.groundView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                IDPAWAbstRenderView *renderView = [obj isKindOfClass:[IDPAWAbstRenderView class]] ? obj : nil;
                if( renderView.selected ){
                    [selectedObjectViews addObject:renderView];
                }
            }];

            if( selectedObjectViews.count == 1 ){
                IDPAWAbstRenderView *renderView = selectedObjectViews[0];
                if( renderView.supportToolType & IDPAWAbstRenderViewSupportToolTypeNoRotation ){
                    continued = NO;
                }
            }
        }else{
            continued = NO;
        }
    }

    if( gestureRecognizer == _authoringWorkspacePanGestureRecognizer ){
        // 一度ターゲット情報を初期化
        _gestureTargetType = IDPAWGestureTargetTypeNone;
        _targetRenderView = nil;
        
        [self.groundView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            IDPAWAbstRenderView *renderView = [obj isKindOfClass:[IDPAWAbstRenderView class]] ? obj : nil;
            if( renderView != nil ){
                CGPoint location = [_authoringWorkspacePanGestureRecognizer locationInView:renderView.superview];
                if( CGRectContainsPoint(renderView.frame, location) ){
                    _gestureTargetType = IDPAWGestureTargetTypeRenderObject;
                    _targetRenderView = renderView;
                    continued = YES;
                }
            }
        }];
        
        if( _targetRenderView == nil ){
            _gestureTargetType = IDPAWGestureTargetTypeGround;
            
            continued = YES;
        }
        
    }
    
    if( gestureRecognizer == _groupPanGesture ){
        UIView *targetView = gestureRecognizer.view;
        IDPAWGroupView *groupView = [targetView isKindOfClass:[IDPAWGroupView class]] ? (IDPAWGroupView *)targetView : nil;
        
        CGPoint location = [_authoringWorkspacePanGestureRecognizer locationInView:groupView];
        continued = [groupView hittestWithLocation:location];
    }
    
    return continued;
}

- (void) onPanHandle:(UIPanGestureRecognizer *)panGestureRecognizer
{
    switch (_gestureTargetType) {
        case IDPAWGestureTargetTypeGround:
            [self firedGroundPan:panGestureRecognizer];
            break;
        case IDPAWGestureTargetTypeRenderObject:
            [self firedObjectPan:panGestureRecognizer renderView:_targetRenderView];
            break;
        default:
            break;
    }
    
    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled:
            _gestureTargetType = IDPAWGestureTargetTypeNone;
            _targetRenderView = nil;
            break;
        default:
            break;
    }
}

- (void)firedGroundTap:(UITapGestureRecognizer *)tapGestureRecognizer
{
    // hittestを実行
    __block BOOL hitTest = NO;
    [self.groundView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        IDPAWAbstRenderView *renderView = [obj isKindOfClass:[IDPAWAbstRenderView class]] ? obj : nil;
        if( renderView.selected == YES ){
            CGPoint location = [tapGestureRecognizer locationInView:renderView.superview];
            if( [renderView hittestWithLocation:location] ){
                hitTest = YES;
            }
        }
    }];
    
    if( hitTest != YES ){
        // 既存の選択状態を無効化
        [self.groundView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            IDPAWAbstRenderView *renderView = [obj isKindOfClass:[IDPAWAbstRenderView class]] ? obj : nil;
            if( renderView.selected == YES ){
                renderView.selected = NO;
                renderView.proxyRender = NO;
                [renderView setNeedsDisplay];
            }
        }];

        // グループを除外
        [self.groupView removeFromSuperview];
        [self synchronizeTracker];
            // グループに合わせてトラッカーを無効化
        
        CGPoint location = [tapGestureRecognizer locationInView:self.groundView];
        // メニューを表示
        [self toggleMenuWithView:self.groundView location:location type:IDPAWAbstViewControllerMenuTypeGroundView];
    }else{
        CGPoint location = [tapGestureRecognizer locationInView:self.groupView];
            // メニューを表示
        [self toggleMenuWithView:self.groupView location:location type:IDPAWAbstViewControllerMenuTypeGroupView];
    }

}

- (void) toggleMenuWithView:(UIView *)view location:(CGPoint)location type:(IDPAWAbstViewControllerMenuType)menuType
{
    if( [view becomeFirstResponder] && _menu.menuVisible != YES ){
        [[NSNotificationCenter defaultCenter] removeObserver:_menuObserver];
        _menu = [UIMenuController sharedMenuController];
        
        NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
        _menuObserver = [dnc addObserverForName:UIMenuControllerWillHideMenuNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            [[NSNotificationCenter defaultCenter] removeObserver:_menuObserver];
            _menuObserver = nil;
            _menu = nil;
        }];
        
        CGRect minRect = CGRectNull;
        
        minRect.origin = location;
        
        _menuPosition = [NSValue valueWithCGPoint:location];
            // 位置を記憶しておく
        
        [_menu setTargetRect:minRect inView:view];
        
        _menu.menuItems = [self menuItemsWithMenuType:menuType view:view];
        
        [_menu setMenuVisible:YES animated:YES];
    }else{
        [_menu setMenuVisible:NO animated:YES];
    }
}


/**
 *  キャンバスサイズを返す
 *
 *  @return キャンバスサイズ
 */
- (CGSize) canvasSize
{
    return self.groundView.frame.size;
}

/**
 *  Trackerとグループの同期
 */
- (void) synchronizeTracker
{
    // 親viewの状態を確認
    if( self.groupView.superview == self.groundView ){
        if( _targetRenderView.supportToolType & IDPAWAbstRenderViewSupportToolTypeNoTracker ){
            [self removeTrackers];
        }else{
            [self.trackers[0] setCenter:CGPointMake(CGRectGetMinX(self.groupView.frame),CGRectGetMinY(self.groupView.frame))];
            [self.trackers[1] setCenter:CGPointMake(CGRectGetMaxX(self.groupView.frame),CGRectGetMinY(self.groupView.frame))];
            [self.trackers[2] setCenter:CGPointMake(CGRectGetMaxX(self.groupView.frame),CGRectGetMaxY(self.groupView.frame))];
            [self.trackers[3] setCenter:CGPointMake(CGRectGetMinX(self.groupView.frame),CGRectGetMaxY(self.groupView.frame))];
            // 4点(左上、右上、右下、左下)にトラッカーを合わせる
            
            if(CGRectIntersectsRect([self.trackers[0] frame],[self.trackers[3] frame]) ){
                _trackerMargin = @(10);
                CGFloat trackerMargin = [_trackerMargin doubleValue];
                
                [self.trackers[0] setCenter:CGPointMake(CGRectGetMinX(self.groupView.frame) - trackerMargin,CGRectGetMinY(self.groupView.frame) - trackerMargin)];
                [self.trackers[1] setCenter:CGPointMake(CGRectGetMaxX(self.groupView.frame) + trackerMargin,CGRectGetMinY(self.groupView.frame) - trackerMargin)];
                [self.trackers[2] setCenter:CGPointMake(CGRectGetMaxX(self.groupView.frame) + trackerMargin,CGRectGetMaxY(self.groupView.frame) + trackerMargin)];
                [self.trackers[3] setCenter:CGPointMake(CGRectGetMinX(self.groupView.frame) - trackerMargin,CGRectGetMaxY(self.groupView.frame) + trackerMargin)];
                // 4点(左上、右上、右下、左下)にトラッカーを合わせる
            }else{
                _trackerMargin = nil;
            }
            
            // groundViewのsubviewとしてTrackerを追加
            [self.trackers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                IDPAWTrackerView *trackerView = obj;
                if( trackerView.superview != self.groundView){
                    [self.groundView addSubview:trackerView];
                }else{
                    [self.groundView bringSubviewToFront:trackerView];
                }
            }];
        }
    }else{
        [self removeTrackers];
    }
}

- (void) removeTrackers
{
    [self.trackers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj removeFromSuperview];
    }];
}

- (void) selectedObjectViewWithBlock:(idp_selected_objecv_view_block_t)block
{
    __block CGRect rectGroup = CGRectNull;
    NSMutableArray *selectedObjectViews = [NSMutableArray array];
    [self.groundView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        IDPAWAbstRenderView *objectView = [obj isKindOfClass:[IDPAWAbstRenderView class]] ? obj : nil;
        // subviewからRenderViewを用意
        
        if (objectView != nil ) {
            // 矩形衝突が認められた場合
            if( block(objectView) ){
                objectView.selected = YES;
                [objectView setNeedsDisplay];
                
                if( CGRectIsNull(rectGroup) ){
                    rectGroup =  objectView.frame;
                }else{
                    rectGroup =  CGRectUnion(rectGroup,objectView.frame);
                }
                
                [selectedObjectViews addObject:objectView];
            }else{
                objectView.selected = NO;
                objectView.proxyRender = NO;
                [objectView setNeedsDisplay];
                
            }
        }
    }];
    
    // 未選択の場合
    if( CGRectIsNull(rectGroup) ){
        // 選択状態を解除
        [self.groundView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            IDPAWAbstRenderView *objectView = [obj isKindOfClass:[IDPAWAbstRenderView class]] ? obj : nil;
            if( objectView.selected == YES ){
                objectView.proxyRender = NO;
                [objectView setNeedsDisplay];
            }
        }];
        
        // グループを除外
        [self.groupView removeFromSuperview];
        [self synchronizeTracker];
    }else{
        // グループ領域を設定
        self.groupView.frame = _originalGroupFrame = rectGroup;
        [self.groupView setNeedsDisplay];
        [self.groupFrameView setNeedsDisplay];
        
        // グループをgroundViewのsubviewに設定
        [self.groundView addSubview:self.groupView];
        [self synchronizeTracker];
        
        IDPAWAbstRenderView *renderView = selectedObjectViews.count == 1 ? selectedObjectViews[0] : nil;
        if( renderView.supportToolType & IDPAWAbstRenderViewSupportToolTypeNoTracker ){
            [self removeTrackers];
                // トラッカーを除外
        }
        
        // 選択状態を有効化
        [self.groundView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            IDPAWAbstRenderView *objectView = [obj isKindOfClass:[IDPAWAbstRenderView class]] ? obj : nil;
            if( objectView.selected == YES ){
                objectView.proxyRender = YES;
                [objectView setNeedsDisplay];
            }else{
                objectView.proxyRender = NO;
                [objectView setNeedsDisplay];
            }
        }];
    }
}


- (void)firedGroundPan:(UIPanGestureRecognizer *)panGestureRecognizer
{
    if(  _selectToolMode == IDPAWAbstViewControllerSelectToolModeRectArea ){
        CGPoint translation = [panGestureRecognizer translationInView:self.groundView];
        CGPoint location = [panGestureRecognizer locationInView:self.groundView];

        //    NSLog(@"translation=%@",[NSValue valueWithCGPoint:translation] );
        //    NSLog(@"location=%@",[NSValue valueWithCGPoint:location] );

        CGRect bandFrame = CGRectMake(_startPosition.x, _startPosition.y, translation.x, translation.y);
        bandFrame = CGRectStandardize(bandFrame);

        switch (panGestureRecognizer.state) {
            case UIGestureRecognizerStateBegan:
            {
                _startPosition = location;
                    // バンド用の開始位置を記憶
            }
                break;
            case UIGestureRecognizerStateChanged:
            {
                // bandViewをgroundViewのsubviewとして設定
                if( self.bandView.superview != self.groundView ){
                    [self.groundView addSubview:self.bandView];
                }
                self.bandView.frame = bandFrame;
                [self.bandView setNeedsDisplay];
            }
                break;
            case UIGestureRecognizerStateEnded:
            {
                CGRect testRect = self.bandView.frame;
                    // hitTest用のRectを用意

                [self.bandView removeFromSuperview];
                _startPosition = CGPointZero;

                // 衝突判定
                [self selectedObjectViewWithBlock:^BOOL(IDPAWAbstRenderView *objectView) {
                    return [objectView hittestWithRect:testRect];
                }];
            }
                break;
            case UIGestureRecognizerStateFailed:
            case UIGestureRecognizerStateCancelled:
            {
                // Bandを除外のみ
                [self.bandView removeFromSuperview];
                _startPosition = CGPointZero;
            }
                break;
            default:
                break;
        }
    }
    
    if(  _selectToolMode == IDPAWAbstViewControllerSelectToolModeLasso ){
        switch (panGestureRecognizer.state) {
            case UIGestureRecognizerStateBegan:
            {
                if( _pathLasso == nil ){
                    _pathLasso = [UIBezierPath bezierPath];
                }
                
                _counter = 0;
                _points[0] = [panGestureRecognizer locationInView:self.groundView];
            }
                break;
            case UIGestureRecognizerStateChanged:
            {
                CGPoint p = [panGestureRecognizer locationInView:self.groundView];
                _counter++;
                _points[_counter] = p;
                if (_counter == 4)
                {
                    _points[3] = CGPointMake((_points[2].x + _points[4].x)/2.0, (_points[2].y + _points[4].y)/2.0);
                    if( _firstPoint == nil ){
                        [_pathLasso moveToPoint:_points[0]];
                    }
                    [_pathLasso addCurveToPoint:_points[3] controlPoint1:_points[1] controlPoint2:_points[2]]; // add a cubic Bezier from pt[0] to pt[3], with control points pt[1] and pt[2]
                    
                    // 最初の点を登録
                    if( _firstPoint == nil ){
                        _firstPoint = [NSValue valueWithCGPoint:_points[0]];
                    }
                    
                    // bandViewをgroundViewのsubviewとして設定
                    if( self.bandView.superview != self.groundView ){
                        [self.groundView addSubview:self.bandView];
                    }
    #define IDP_AW_BAND_VIEW_PATH_MARGINE 1
                    self.bandView.frame = CGRectUnion(CGRectOffset(_pathLasso.bounds,-IDP_AW_BAND_VIEW_PATH_MARGINE, -IDP_AW_BAND_VIEW_PATH_MARGINE),CGRectOffset(_pathLasso.bounds,IDP_AW_BAND_VIEW_PATH_MARGINE, IDP_AW_BAND_VIEW_PATH_MARGINE));
                    
                    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithCGPath:_pathLasso.CGPath];
                    [bezierPath applyTransform:CGAffineTransformMakeTranslation(-_pathLasso.bounds.origin.x + IDP_AW_BAND_VIEW_PATH_MARGINE,-_pathLasso.bounds.origin.y +IDP_AW_BAND_VIEW_PATH_MARGINE)];
                    
                    self.bandView.bezierPath = bezierPath;
                    [self.bandView setNeedsDisplay];
                    
                    // replace points and get ready to handle the next segment
                    _points[0] = _points[3];
                    _points[1] = _points[4];
                    _counter = 1;
                }
            }
                break;
            case UIGestureRecognizerStateEnded:
            {
                [_pathLasso closePath];
                // パスを閉じる
                
                // 衝突判定
                [self selectedObjectViewWithBlock:^BOOL(IDPAWAbstRenderView *objectView) {
                    return [objectView hittestWithPath:_pathLasso];
                }];
                
                // bandViewをgroundViewのsubviewとして設定
                if( self.bandView.superview != self.groundView ){
                    [self.groundView addSubview:self.bandView];
                }
                self.bandView.bezierPath = nil;
                    // pathをクリア
                [self.bandView removeFromSuperview];
                    // 画面から除外
                
                [_pathLasso removeAllPoints];
                _firstPoint = nil;
                _counter = 0;
            }
                break;
            case UIGestureRecognizerStateCancelled:
            case UIGestureRecognizerStateFailed:
            {
                self.bandView.bezierPath = nil;
                    // pathをクリア
                [self.bandView removeFromSuperview];
                    // 画面から除外
                
                [_pathLasso removeAllPoints];
                _firstPoint = nil;
                _counter = 0;
            }
                break;
            default:
                break;
        }
    }
}

- (void)firedGroundRotate:(UIRotationGestureRecognizer *)rotationGestureRecognizer
{
    switch (rotationGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
//            NSLog(@"_sliderView.value=%@",@(_sliderView.value));
            
            self.groupView.transform = CGAffineTransformMakeRotation(rotationGestureRecognizer.rotation );
            
//            UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRect:self.groupView.bounds];
//            [bezierPath applyTransform:CGAffineTransformMakeRotation(degreesToRadians(_sliderView.value) )];
//            [bezierPath applyTransform:CGAffineTransformMakeTranslation(self.groupView.center.x - bezierPath.bounds.size.width * 0.5,self.groupView.center.y - bezierPath.bounds.size.height * 0.5)];
            
            [self.trackers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [obj removeFromSuperview];
            }];
        }
            break;
        case UIGestureRecognizerStateEnded:
        {
            [self rotateSelectedObjectWithRotations:@[@(rotationGestureRecognizer.rotation)]];
                // 回転を適用
            
            
//            [self.degreeInputView removeFromSuperview];
        }
            break;
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled:
        {
            self.groupView.transform = CGAffineTransformIdentity;
            [self.groupView setNeedsDisplay];
            [self synchronizeTracker];
        }
            break;
        default:
            break;
    }
}

-(void) firedObjectTap:(UITapGestureRecognizer *)tapGestureRecognizer
{
    UIView *targetView = tapGestureRecognizer.view;
        // ターゲットを特定

    // targetView以外の選択状態を無効にする
    [self.groundView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        IDPAWAbstRenderView *renderView = [obj isKindOfClass:[IDPAWAbstRenderView class]] ? obj : nil;
        if( renderView.selected == YES ){
            renderView.selected = NO;
            renderView.proxyRender = NO;
            [renderView setNeedsDisplay];
        }
    }];
    
    IDPAWAbstRenderView *renderView = [targetView isKindOfClass:[IDPAWAbstRenderView class]] ? (IDPAWAbstRenderView *)targetView : nil;
    renderView.selected = YES;
    renderView.proxyRender = YES;
    [renderView setNeedsDisplay];
    
    if( renderView.selected != YES ){
        // 選択状態が無効(targetViewがRenderViewではない場合)
        [self.groupView removeFromSuperview];
        [self synchronizeTracker];
            // グループを解除
    }else{
        //　グループを選択したオブジェクトに同期
        self.groupView.frame = _originalGroupFrame = renderView.frame;
        [self.groundView addSubview:self.groupView];
        [self.groupView setNeedsDisplay];
            // グループの描画を更新する
        [self.groupFrameView setNeedsDisplay];
            // グレープフレームの描画を更新する
        [self synchronizeTracker];

        if( renderView.supportToolType & IDPAWAbstRenderViewSupportToolTypeNoTracker ){
            [self removeTrackers];
                // トラッカーを除外
        }
        
        CGPoint location = [tapGestureRecognizer locationInView:self.groupView];
        // メニューを表示
        [self toggleMenuWithView:self.groupView location:location type:IDPAWAbstViewControllerMenuTypeGroupView];
    }
}

- (void)firedGroupPan:(UIPanGestureRecognizer *)panGestureRecognizer 
{
    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:
        case UIGestureRecognizerStateEnded:
        {
            UIView *targetView = panGestureRecognizer.view;
                //targetを特定
            
            // 回転を考慮して
            CGPoint p = CGPointZero;
            {
                CGAffineTransform oldAffineTransform = targetView.transform;
                targetView.transform = CGAffineTransformIdentity;
                /*CGPoint*/ p = [panGestureRecognizer translationInView:targetView];
                targetView.transform = oldAffineTransform;
            }
            
            if( panGestureRecognizer.state == UIGestureRecognizerStateBegan ){
                _originalGroupCenter = targetView.center;
            }
            
            
            CGPoint movedPoint = CGPointMake(targetView.center.x + p.x, targetView.center.y + p.y);
            // 移動距離を計算
            
            targetView.center = movedPoint;
            [panGestureRecognizer setTranslation:CGPointZero inView:targetView];
                // ジェスチャをリセット
            
            // 終了後に要素に位置変更を適用
            if( panGestureRecognizer.state == UIGestureRecognizerStateEnded ){
                CGPoint deltaPoint = CGPointMake( _originalGroupCenter.x - targetView.center.x,_originalGroupCenter.y - targetView.center.y);
                
                NSMutableArray *commands = [NSMutableArray array];
                NSMutableArray *objectViews = [NSMutableArray array];
                
                [targetView.superview.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    IDPAWAbstRenderView *renderView = [obj isKindOfClass:[IDPAWAbstRenderView class]] ? obj : nil;
                    if( renderView.selected == YES && targetView != renderView){
                        
                        commands[commands.count] = [IDPAWMoveCommand moveCommandWithView:renderView location:renderView.center block:nil];
                            // commandを作成
                        objectViews[objectViews.count] = renderView;
                        
                        renderView.center = CGPointMake(renderView.center.x - deltaPoint.x, renderView.center.y - deltaPoint.y);
                    }
                    _originalGroupFrame = self.groupView.frame;
                }];
                
                [self pushCommand:[IDPAWGroupedCommand groupedCommandWithCommands:commands objectViews:objectViews block:[self commandBlock]]];
                    // コマンド追加
                
            }
            [self synchronizeTracker];
        }
            break;
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled:
            break;
        default:
            break;
    }
}

- (void)firedObjectPan:(UIPanGestureRecognizer *)panGestureRecognizer renderView:(IDPAWAbstRenderView *)renderView
{
    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:
        case UIGestureRecognizerStateEnded:
        {
            UIView *targetView = /*panGestureRecognizer.view*/ renderView;
                //targetを特定

            // 回転を考慮して
            CGPoint p = CGPointZero;
            {
                CGAffineTransform oldAffineTransform = targetView.transform;
                targetView.transform = CGAffineTransformIdentity;
                /*CGPoint*/ p = [panGestureRecognizer translationInView:targetView];
                targetView.transform = oldAffineTransform;
            }
            
            CGPoint movedPoint = CGPointMake(targetView.center.x + p.x, targetView.center.y + p.y);
                // 移動距離を計算
            
            CGPoint deltaPoint = CGPointMake(targetView.center.x - movedPoint.x,targetView.center.y - movedPoint.y);
            targetView.center = movedPoint;
            [panGestureRecognizer setTranslation:CGPointZero inView:renderView];
                // ジェスチャをリセット
            
            IDPAWAbstRenderView *renderView = [targetView isKindOfClass:[IDPAWAbstRenderView class]] ? (IDPAWAbstRenderView *)targetView : nil;
            
            if (panGestureRecognizer.state == UIGestureRecognizerStateBegan) {
                _locationForObjectMove = renderView != nil ? [NSValue valueWithCGPoint:renderView.center] : nil;
            }
            
            // ターゲットが未選択なのにPanを開始した場合はいったん解除
            if( renderView.selected != YES ){
                [self.groundView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    IDPAWAbstRenderView *renderView = [obj isKindOfClass:[IDPAWAbstRenderView class]] ? obj : nil;
                    if( renderView != nil && renderView != targetView ){
                        if( renderView.selected != NO ){
                            renderView.selected = NO;
                            renderView.proxyRender = NO;
                            [renderView setNeedsDisplay];
                        }
                    }
                }];
                
                // 選択状態を再設定
                renderView.selected = YES;
                renderView.proxyRender = YES;
                [renderView setNeedsDisplay];
                
                //　グループ状態を再設定
                self.groupView.frame = _originalGroupFrame = renderView.frame;
                [self.groupView setNeedsDisplay];
                [self.groupFrameView setNeedsDisplay];
                [self.groundView addSubview:self.groupView];
                [self synchronizeTracker];
            }
            
            // ドラッグ呼び出し
            if( panGestureRecognizer.state == UIGestureRecognizerStateChanged || panGestureRecognizer.state == UIGestureRecognizerStateEnded){
                [targetView.superview.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    IDPAWAbstRenderView *renderView = [obj isKindOfClass:[IDPAWAbstRenderView class]] ? obj : nil;
                    if( renderView.selected == YES && targetView != renderView){
                        renderView.center = CGPointMake(renderView.center.x - deltaPoint.x, renderView.center.y - deltaPoint.y);
                    }
                }];
                
                self.groupView.center = CGPointMake(self.groupView.center.x - deltaPoint.x, self.groupView.center.y - deltaPoint.y);
                _originalGroupFrame = self.groupView.frame;
                
                [self synchronizeTracker];
            }
            
            if( panGestureRecognizer.state == UIGestureRecognizerStateEnded ){
                if( _locationForObjectMove != nil ){
                    [self pushCommand:[IDPAWMoveCommand moveCommandWithView:renderView location:[_locationForObjectMove CGPointValue] block:[self commandBlock]]];
                        // commandを追加
                    _locationForObjectMove = nil;
                }
            }
        }
            break;
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled:
            break;
        default:
            break;
    }
}

- (void)firedTrackerPan:(UIPanGestureRecognizer *)panGestureRecognizer
{
    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        {
            UIView *targetView = panGestureRecognizer.view;
            
            CGPoint p = CGPointZero;
            /*CGPoint*/ p = [panGestureRecognizer translationInView:targetView];
            
            CGPoint movedPoint = CGPointMake(targetView.center.x + p.x, targetView.center.y + p.y);
            targetView.center = movedPoint;
            [panGestureRecognizer setTranslation:CGPointZero inView:targetView];
                // トラッカーの位置を変更
            
            if( panGestureRecognizer.state == UIGestureRecognizerStateBegan || panGestureRecognizer.state == UIGestureRecognizerStateChanged || panGestureRecognizer.state == UIGestureRecognizerStateEnded){
                NSInteger index = [self.trackers indexOfObject:targetView];
                NSInteger diagonalIndex = (index + 2) % 4; // 対角線上の位置を取得

                UIBezierPath *beziePath = [[UIBezierPath alloc] init];
                [beziePath moveToPoint:[self.trackers[index] center]];
                [beziePath addLineToPoint:[self.trackers[diagonalIndex] center]];
                    // Pathを使ってサイズを計算

                CGFloat trackerMargin = [_trackerMargin doubleValue];
                CGRect bounds = CGRectIntersection( CGRectOffset(beziePath.bounds, -trackerMargin, -trackerMargin), CGRectOffset(beziePath.bounds, trackerMargin, trackerMargin) );
                    // Pathから領域を得る

                CGRect normalizedRect = AVMakeRectWithAspectRatioInsideRect(_originalGroupFrame.size, bounds );
                    // オリジナル矩形を元に同比率の矩形を得る
                
                CGPoint deltaPoint = CGPointMake(CGRectGetWidth(bounds) - CGRectGetWidth(normalizedRect)
                                                 ,CGRectGetHeight(bounds) - CGRectGetHeight(normalizedRect) );
                    // サイズの差分を計算
                
                bounds.size = normalizedRect.size;
                    // サイズの差分を計算した後。サイズを設定し直す
                
                // トラッキング中位置の対角線を起点としてサイズ調整するように変更
                switch (index) {
                    case 2:
                        bounds =  CGRectOffset(bounds,0,0);
                        break;
                    case 3:
                        bounds =  CGRectOffset(bounds,deltaPoint.x ,0);
                        break;
                    case 0:
                        bounds =  CGRectOffset(bounds,deltaPoint.x ,deltaPoint.y );
                        break;
                    case 1:
                        bounds =  CGRectOffset(bounds,0 ,deltaPoint.y );
                        break;
                    default:
                        break;
                }
                
                if( panGestureRecognizer.state == UIGestureRecognizerStateBegan ){
                    _safetyBounds = bounds;
                        // 安全サイズを保存
                }else if( panGestureRecognizer.state == UIGestureRecognizerStateChanged ){
                    if( bounds.size.width * bounds.size.height <= 2 ){
                        panGestureRecognizer.enabled = NO;
                        panGestureRecognizer.enabled = YES;
                        
                        bounds = _safetyBounds;
                            // 安全サイズから戻す
                    }else{
                        _safetyBounds = bounds;
                        // 安全サイズを保存
                    }
                }
                
                
                
                // トラッキングポイントのサイズを変更
                self.groupView.frame = bounds;
                [self.groupFrameView setNeedsDisplay];
                    // グループの枠のみ描画を更新する
                
                // トラッキングされてるオブジェクトの変わりにダミートラッカーを表示する
                if( self.dummyTrackerView.superview != self.groundView ){
                    [self.groundView addSubview:self.dummyTrackerView];
                }
                
                // トラッキング中のTrackerのフラグを有効化
                [self.trackers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    if( targetView == obj ){
                        if( [obj enterTraking] != YES ){
                            [obj setEnterTraking:YES];
                                 // Tracker をTracking中に設定
                            [obj setNeedsDisplay];
                                // 表示を更新
                        }
                        
                        *stop = YES;
                    }
                }];
                
                // 各トラッキング点の位置を調整
                [targetView != self.trackers[0] ? self.trackers[0] : self.dummyTrackerView setCenter:CGPointMake(CGRectGetMinX(self.groupView.frame)-trackerMargin,CGRectGetMinY(self.groupView.frame)-trackerMargin)];
                
                [targetView != self.trackers[1] ? self.trackers[1] : self.dummyTrackerView setCenter:CGPointMake(CGRectGetMaxX(self.groupView.frame)+trackerMargin,CGRectGetMinY(self.groupView.frame)-trackerMargin)];
                
                [targetView != self.trackers[2] ? self.trackers[2] : self.dummyTrackerView setCenter:CGPointMake(CGRectGetMaxX(self.groupView.frame)+trackerMargin,CGRectGetMaxY(self.groupView.frame)+trackerMargin)];
                
                [targetView != self.trackers[3] ? self.trackers[3] : self.dummyTrackerView setCenter:CGPointMake(CGRectGetMinX(self.groupView.frame)-trackerMargin,CGRectGetMaxY(self.groupView.frame)+trackerMargin)];

                // 終了後にDummyTrackerをTrackerに置き換える
                if( panGestureRecognizer.state == UIGestureRecognizerStateEnded || panGestureRecognizer.state == UIGestureRecognizerStateCancelled){
                    
                    CGFloat ratio = CGRectGetWidth(self.groupView.frame) / CGRectGetWidth(_originalGroupFrame);
                        // 比率を計算
                    
//                    NSLog(@"_originalGroupFrame=%@",[NSValue valueWithCGRect:_originalGroupFrame]);
//                    NSLog(@"self.groupView.frame=%@",[NSValue valueWithCGRect:self.groupView.frame]);
                    
//                    CGPoint offset = CGPointMake(  CGRectGetMinX(_originalGroupFrame) - CGRectGetMinX(self.groupView.frame)
//                                                 , CGRectGetMinY(_originalGroupFrame) - CGRectGetMinY(self.groupView.frame) );
                    
                    NSMutableArray *commands = [NSMutableArray array];
                    NSMutableArray *objectViews = [NSMutableArray array];
                    
                    // 選択状態のオブジェクトの位置を把握
                    [self.groundView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        IDPAWAbstRenderView *renderView = [obj isKindOfClass:[IDPAWAbstRenderView class]] ? obj : nil;
                        if( renderView.selected == YES ){

                            commands[commands.count] = [IDPAWResizeCommand resizeCommandWithView:renderView location:renderView.center size:renderView.bounds.size block:nil];
                                // commandを作成
                            objectViews[objectViews.count] = renderView;
                            
                            
                            CGPoint delta = CGPointZero;
                            {
                                CGAffineTransform oldAffineTransform = renderView.transform;
                                renderView.transform = CGAffineTransformIdentity;

                                delta = CGPointMake( CGRectGetMidX(_originalGroupFrame) - renderView.center.x
                                                            ,CGRectGetMidY(_originalGroupFrame) - renderView.center.y );
                                renderView.transform = oldAffineTransform;
                            }
                            delta = CGPointMake(delta.x  * ratio, delta.y  * ratio);
                                // 差分を計算
                            
//                            NSLog(@"delta=%@",[NSValue valueWithCGPoint:renderView.center]);
                            
                            CGRect originalBounds = renderView.bounds;
                            
                            renderView.bounds = (CGRect){renderView.bounds.origin,CGSizeMake(CGRectGetWidth(renderView.bounds) * ratio,CGRectGetHeight(renderView.bounds) * ratio)};

                            {
                                CGAffineTransform oldAffineTransform = renderView.transform;
                                renderView.transform = CGAffineTransformIdentity;
                            
                                renderView.center = CGPointMake( self.groupView.center.x - delta.x
                                                                ,self.groupView.center.y - delta.y );
                            
                                renderView.transform = oldAffineTransform;
                            }
                            [renderView resizeSubViewWithBounds:renderView.bounds originalBounds:originalBounds];
                                // サイズの再構築
                        }
                    }];
                    
                    [self pushCommand:[IDPAWGroupedCommand groupedCommandWithCommands:commands objectViews:objectViews block:[self commandBlock]]];
                        // コマンド追加
                    
                    _originalGroupFrame = self.groupView.frame;
                    [self.groupView setNeedsDisplay];
                    
                    // 位置情報を反映
                    [self.trackers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        if( targetView == obj ){
                            [obj setCenter:self.dummyTrackerView.center];
                            
                            [obj setEnterTraking:NO];
                            [obj setNeedsDisplay];
                            
                            *stop = YES;
                        }
                    }];
                    [self.dummyTrackerView removeFromSuperview];
                        // 置き換えたDummyTrackerは非表示とする
                }
            }
        }
            break;
        case UIGestureRecognizerStateFailed:
            
            break;
        default:
            break;
    }
}

@end
