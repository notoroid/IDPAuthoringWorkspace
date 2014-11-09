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
//#import "DegreeInputView.h"
@import QuartzCore;

//static double degreesToRadians(double degrees);
//static double degreesToRadians(double degrees) {return degrees * M_PI / 180;}

//static double radiansToDegrees(double radians);
//static double radiansToDegrees(double radians) {return radians * 180 / M_PI;}

static NSInteger s_hierarchyTag = 0;

@interface IDPAWEditModeObject : NSObject
@property (nonatomic) IDPAWAbstViewControllerEditMode editMode;
@property (nonatomic) NSMutableDictionary *viewsByHierarchyTag;
@property (copy,nonatomic) idp_hierarchy_compare_block_t compare;
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


@interface IDPAWAbstViewController () <UIGestureRecognizerDelegate>
{
    BOOL _initialized;
    
    UIGestureRecognizer *_groundTapGesture; // Ground用Tapジェスチャ
    UIPanGestureRecognizer *_groundPanGesture; // Ground用Panジェスチャ
    UIRotationGestureRecognizer *_groundRotateGesture;
 
    UIPanGestureRecognizer *_groupPanGesture;
    
    
    CGPoint _startPosition; // バンドの開始位置
    IDPAWBandView *_bandView; // バンド用View
    IDPAWGroupView *_groupView; // グループ状態表示用View
    NSArray *_trackers; // Tracker用配列
    IDPAWTrackerView *_dummyTrackerView; // ダミートラッカー用View
    
    CGPoint _originalGroupCenter;
    CGRect _originalGroupFrame; // グループサイズ変更時のオリジナルサイズ
    
    NSMutableArray *_hierarchies;
}
@property(readonly,nonatomic) IDPAWBandView *bandView;
@property(readonly,nonatomic) IDPAWGroupFrameView *groupFrameView;
@property(readonly,nonatomic) NSArray *trackers;
@property(readonly,nonatomic) IDPAWTrackerView *dummyTrackerView;

@property(readonly,nonatomic) UIPanGestureRecognizer *objectPanGestureRecognizer;
@property(readonly,nonatomic) UITapGestureRecognizer *objectTapGestureRecognizer;
//@property(readonly,nonatomic) DegreeInputView *degreeInputView;
@property(readonly,nonatomic) NSMutableArray *hierarchies;
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

//- (IBAction)firedCloseDegree:(id)sender
//{
//    self.groupView.transform = CGAffineTransformMakeRotation(degreesToRadians(_sliderView.value) );
//    
//    UIView *testView = [[UIView alloc] initWithFrame:(CGRect){CGPointZero,CGSizeMake(10,10)}];
//    
//    [self.groundView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//        IDPAWAbstRenderView *renderView = [obj isKindOfClass:[IDPAWAbstRenderView class]] ? obj : nil;
//        if( renderView.selected == YES ){
//            // 回転を適用
//            CGAffineTransform transform = CGAffineTransformConcat(renderView.transform, self.groupView.transform);
//            renderView.transform = transform;
//            
//            // 位置を変更
//            /*CGAffineTransform*/ transform = self.groupView.transform;
//            self.groupView.transform = CGAffineTransformIdentity;
//            
//            
//            testView.center = [self.groupView convertPoint:renderView.center fromView:self.groundView];
//            [self.groupView addSubview:testView];
//            
//            NSLog(@"testView.center=%@",[NSValue valueWithCGPoint:[self.groundView convertPoint:testView.center fromView:self.groupView]]);
//            
//            self.groupView.transform = transform;
//
//            NSLog(@"testView.center=%@",[NSValue valueWithCGPoint:[self.groundView convertPoint:testView.center fromView:self.groupView]]);
//
//            renderView.center = [self.groundView convertPoint:testView.center fromView:self.groupView];
//                // 変換
//
//            [testView removeFromSuperview];
//        }
//    }];
//    
//    self.groupView.transform = CGAffineTransformIdentity;
//
//    // サイズを正規化
//    __block CGRect rectGroup = CGRectNull;
//    [self.groundView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//        IDPAWAbstRenderView *renderView = [obj isKindOfClass:[IDPAWAbstRenderView class]] ? obj : nil;
//        if (renderView.selected == YES ) {
//            if( CGRectIsNull(rectGroup) ){
//                rectGroup =  renderView.frame;
//            }else{
//                rectGroup =  CGRectUnion(rectGroup,renderView.frame);
//            }
//        }
//    }];
//    
//    self.groupView.frame = _originalGroupFrame = rectGroup;
//    [self.groupView setNeedsDisplay];
//    [self synchronizeTracker];
//    
//    
//    
//    [self.degreeInputView removeFromSuperview];
//}

//- (IBAction)firedChangeDegree:(id)sender
//{
//    if( sender == _sliderView ){
//        NSLog(@"_sliderView.value=%@",@(_sliderView.value));
//        
//        self.groupView.transform = CGAffineTransformMakeRotation(degreesToRadians(_sliderView.value) );
//
//        UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRect:self.groupView.bounds];
//        [bezierPath applyTransform:CGAffineTransformMakeRotation(degreesToRadians(_sliderView.value) )];
//        [bezierPath applyTransform:CGAffineTransformMakeTranslation(self.groupView.center.x - bezierPath.bounds.size.width * 0.5,self.groupView.center.y - bezierPath.bounds.size.height * 0.5)];
//        
//        [self.trackers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//            [obj removeFromSuperview];
//        }];
//    }
//    
//}

//- (DegreeInputView *) degreeInputView
//{
//    if( _degreeInputView == nil ){
//        [[UINib nibWithNibName:@"DegreeInputView" bundle:nil] instantiateWithOwner:self options:nil];
//        
//        [_degreeInputView.layer setShadowRadius:4.0f];
//        [_degreeInputView.layer setShadowOffset:CGSizeMake(1.5f, 2.3f)];
//        [_degreeInputView.layer setShadowOpacity:0.7f];
//        
//    }
//    return _degreeInputView;
//}


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
 *  GroupViewのインスタンスを返す
 *
 *  @return GroupViewのインスタンス
 */
- (IDPAWGroupView *)groupView
{
    if( _groupView == nil ){
        _groupView = [[IDPAWGroupView alloc] initWithFrame:(CGRect){CGPointZero,CGSizeMake(20.0, 20.0f)}];
        _groupView.backgroundColor = [UIColor clearColor];
        _groupView.opaque = NO;
//        _groupView.userInteractionEnabled = NO;
        
        _groupPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(firedGroupPan:)];
        _groupPanGesture.delegate = self;
        [_groupView addGestureRecognizer:_groupPanGesture];
        
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
        NSMutableArray *trackers = [NSMutableArray array];
        for( NSInteger i = 0;i < 4;i++){
            IDPAWTrackerView *trackerView= [[IDPAWTrackerView alloc] initWithFrame:(CGRect){CGPointZero,CGSizeMake(23.0,23.0)}];
            trackerView.backgroundColor = [UIColor clearColor];
            trackerView.opaque = NO;
            trackerView.userInteractionEnabled = YES;
            trackers[trackers.count] = trackerView;
            
            UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(firedTrackerPan:)];
            [trackerView addGestureRecognizer:panGesture];
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
        _dummyTrackerView = [[IDPAWTrackerView alloc] initWithFrame:(CGRect){CGPointZero,CGSizeMake(23.0,23.0)}];
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
    
    _groundPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(firedGroundPan:)];
    _groundPanGesture.delegate = self;
    [self.groundView addGestureRecognizer:_groundPanGesture];
    // Panジェスチャを追加
    
    _groundRotateGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(firedGroundRotate:)];
    _groundRotateGesture.delegate = self;
    [self.groundView addGestureRecognizer:_groundRotateGesture];
    // Rotateジェスチャを追加
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _groundTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(firedGroundTap:)];
    _groundTapGesture.delegate = self;
    [self.groundView addGestureRecognizer:_groundTapGesture];
        // Tapジェスチャを追加
    
    _groundPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(firedGroundPan:)];
    _groundPanGesture.delegate = self;
    [self.groundView addGestureRecognizer:_groundPanGesture];
        // Panジェスチャを追加
    
    _groundRotateGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(firedGroundRotate:)];
    _groundRotateGesture.delegate = self;
    [self.groundView addGestureRecognizer:_groundRotateGesture];
        // Rotateジェスチャを追加
    
}

- (void) addGestureWithView:(UIView *)view
{
    UIPanGestureRecognizer *panPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(firedObjectPan:)];
    panPanGestureRecognizer.delegate = self;
    [view addGestureRecognizer:panPanGestureRecognizer];
        // ジェスチャを追加
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(firedObjectTap:)];
    tapGestureRecognizer.delegate = self;
    [view addGestureRecognizer:tapGestureRecognizer];
        // ジェスチャを追加
}

- (void) addObjectView:(IDPAWAbstRenderView *) objectView
{
    [self addGestureWithView:objectView];
        // GestureRecognizer を付与
    
    [self.groundView addSubview:objectView];
}

- (void) insertObjectView:(IDPAWAbstRenderView *) objectView belowSubview:(UIView *)siblingSubview
{
    [self addGestureWithView:objectView];
        // GestureRecognizer を付与
    
    [self.groundView insertSubview:objectView belowSubview:siblingSubview];
}

- (void) insertObjectView:(IDPAWAbstRenderView *) objectView aboveSubview:(UIView *)siblingSubview
{
    [self addGestureWithView:objectView];
        // GestureRecognizer を付与
    
    [self.groundView insertSubview:objectView aboveSubview:siblingSubview];
}


- (void) removeObjectView:(IDPAWAbstRenderView *) objectView
{
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
            deleteTarget[deleteTarget.count] = renderView;
        }
    }];
    
    [deleteTarget enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj removeFromSuperview];
    }];
    
    
    // グループを除外
    [self.groupView removeFromSuperview];
    [self synchronizeTracker];
        // グループに合わせてトラッカーを無効化
}

- (void) rotateSelectedObjectWithRotation:(CGFloat)rotation
{
    self.groupView.transform = CGAffineTransformMakeRotation(rotation );
    
    UIView *testView = [[UIView alloc] initWithFrame:(CGRect){CGPointZero,CGSizeMake(10,10)}];
    
    [self.groundView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        IDPAWAbstRenderView *renderView = [obj isKindOfClass:[IDPAWAbstRenderView class]] ? obj : nil;
        if( renderView.selected == YES ){
            // 回転を適用
            CGAffineTransform transform = CGAffineTransformConcat(renderView.transform, self.groupView.transform);
            renderView.transform = transform;
            
            // 位置を変更
            /*CGAffineTransform*/ transform = self.groupView.transform;
            self.groupView.transform = CGAffineTransformIdentity;
            
            testView.center = [self.groupView convertPoint:renderView.center fromView:self.groundView];
            [self.groupView addSubview:testView];
            
            NSLog(@"testView.center=%@",[NSValue valueWithCGPoint:[self.groundView convertPoint:testView.center fromView:self.groupView]]);
            
            self.groupView.transform = transform;
            
            NSLog(@"testView.center=%@",[NSValue valueWithCGPoint:[self.groundView convertPoint:testView.center fromView:self.groupView]]);
            
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

- (void) pushEditMode:(IDPAWAbstViewControllerEditMode)editMode compare:(idp_hierarchy_compare_block_t)compare
{
    switch (editMode) {
        case IDPAWAbstViewControllerEditModeHierarchy:
        {
            IDPAWEditModeObject *editModeObject = [[IDPAWEditModeObject alloc] initWithEditMode:editMode];
            editModeObject.compare = compare;
                // 比較オブジェクトを複製
            self.hierarchies[self.hierarchies.count] = editModeObject;
                // 階層を追加
            
            NSMutableArray *selecteObjectViews = [NSMutableArray array];

            NSArray *objectViews = self.objectViews;
            [objectViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                IDPAWAbstRenderView *renderView = [obj isKindOfClass:[IDPAWAbstRenderView class]] ? obj : nil;
                if( renderView != nil ){
                    s_hierarchyTag++;
                        // タグを発行
                    
                    renderView.parentHierarchyTag = s_hierarchyTag;
                        // タグを関連づけ
                    
                    NSArray *subViews = [renderView.subviews copy];
                    [subViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        IDPAWAbstRenderView *renderSubView = compare(obj) ? obj : nil;
                        
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
                        }
                    }];
                    
                    [self removeObjectView:renderView];
                    editModeObject.viewsByHierarchyTag[@(s_hierarchyTag)] = renderView;
                }
            }];
            
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
            
            
            idp_hierarchy_compare_block_t compare = editModeObject.compare;
            editModeObject.compare = nil;
                // 比較オブジェクトを解放
            
            
            [objectViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                
                IDPAWAbstRenderView *renderSubView = compare(obj) ? obj : nil;
                
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
            
            [self selectObjectViews:setSelectedViews.allObjects];
                // 選択状態を更新

        }
            break;
        default:
            break;
    }
    
}

//- (void) viewWillLayoutSubviews
//{
//    [super viewDidLayoutSubviews];
//    if( _initialized != YES ){
//        _initialized = YES;
//
//        // レイアウトが決定してからテストオブジェクトを追加
//
//        NSArray *centers = @[  [NSValue valueWithCGPoint:CGPointMake(CGRectGetMidX(self.groundView.frame),CGRectGetMidY(self.groundView.frame))]
//                             ,[NSValue valueWithCGPoint:CGPointMake(CGRectGetMidX(self.groundView.frame) + 20.0f ,CGRectGetMidY(self.groundView.frame) + 20.0f)]
//                             ];
//
//        NSArray *bounds = @[ [NSValue valueWithCGRect:CGRectMake(0, 0, 120, 80)]
//                            ,[NSValue valueWithCGRect:CGRectMake(0, 0, 120, 80)]
//                            ];
//        
//        [centers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//            CGRect lineBounds = [bounds[idx] CGRectValue];;
//            CGPoint center = [obj CGPointValue] /*CGPointMake(CGRectGetMidX(self.groundView.frame),CGRectGetMidY(self.groundView.frame))*/;
//            
//            IDPAWAbstRenderView *renderView = [[IDPAWAbstRenderView alloc] initWithFrame:lineBounds];
//            renderView.center = center;
//            renderView.backgroundColor = [UIColor clearColor]/*[UIColor lightGrayColor]*/;
//            renderView.opaque = NO;
//            renderView.clipsToBounds = NO;
//            renderView.transform = CGAffineTransformMakeRotation(degreesToRadians(0.0f) );
//            
//            UIPanGestureRecognizer *panPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(firedObjectPan:)];
//            panPanGestureRecognizer.delegate = self;
//            [renderView addGestureRecognizer:panPanGestureRecognizer];
//            // ジェスチャを追加
//            
//            UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(firedObjectTap:)];
//            tapGestureRecognizer.delegate = self;
//            [renderView addGestureRecognizer:tapGestureRecognizer];
//            // ジェスチャを追加
//            
//            [/*_editView*/self.groundView addSubview:renderView];
//            
//        }];
//    }
//}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

//- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    /*__block*/ BOOL continued = YES;
    
    if( gestureRecognizer == _groundRotateGesture ){
        if( self.groupView.superview == self.groundView ){
            // 空実装
        }else{
            continued = NO;
        }
    }

    if( gestureRecognizer == _groupPanGesture ){
        UIView *targetView = gestureRecognizer.view;
        IDPAWGroupView *groupView = [targetView isKindOfClass:[IDPAWGroupView class]] ? (IDPAWGroupView *)targetView : nil;
        
        CGPoint location = [_groundPanGesture locationInView:groupView];
        continued = [groupView hittestWithLocation:location];
    }
    
    if( [gestureRecognizer.view isKindOfClass:[IDPAWAbstRenderView class]] && ( [gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] || [gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] ) ){
        IDPAWAbstRenderView *renderView = (IDPAWAbstRenderView *)gestureRecognizer.view;
        CGPoint location = [gestureRecognizer locationInView:renderView.superview];
        continued = [renderView hittestWithLocation:location];
    }
    
//    if( _groundTapGesture == gestureRecognizer ){
//        CGPoint location = [touch locationInView:self.groundView];
//        
//        __block BOOL hitTestSubView = NO;
//        [self.groundView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//            UIView *subview = obj;
//            
//            if( CGRectContainsPoint(subview.frame,location)  ){
//                hitTestSubView = YES;
//                *stop = YES;
//            }
//        }];
//     
//        continued = hitTestSubView ? NO : YES;
//    }
    
    return continued;
}

// 同じオブジェクトに登録されたジェスチャの順序を決定するために使用する
//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer NS_AVAILABLE_IOS(7_0)
//{
//    __block BOOL result = NO;
//
//    RenderView *renderView = [gestureRecognizer.view isKindOfClass:[RenderView class]] ? (RenderView *)gestureRecognizer.view : nil;
//    RenderView *otherRenderView = [otherGestureRecognizer.view isKindOfClass:[RenderView class]] ? (RenderView *)otherGestureRecognizer.view : nil;
//    
//    if( renderView != nil && otherRenderView != nil ){
//        if( renderView != otherRenderView ){
//            // RenderView同士の動作
//            NSLog(@"renderView.selected=%@", renderView.selected ? @"YES" : @"NO");
//            NSLog(@"otherRenderView.selected=%@", otherRenderView.selected ? @"YES" : @"NO" );
//        }else{
//            NSLog(@"同じオブジェクトのジェスチャ");
//        }
//    }
//    
//    return result;
//}


- (void)firedGroundTap:(id)sender
{
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
        [self.trackers[0] setCenter:CGPointMake(CGRectGetMinX(self.groupView.frame),CGRectGetMinY(self.groupView.frame))];
        [self.trackers[1] setCenter:CGPointMake(CGRectGetMaxX(self.groupView.frame),CGRectGetMinY(self.groupView.frame))];
        [self.trackers[2] setCenter:CGPointMake(CGRectGetMaxX(self.groupView.frame),CGRectGetMaxY(self.groupView.frame))];
        [self.trackers[3] setCenter:CGPointMake(CGRectGetMinX(self.groupView.frame),CGRectGetMaxY(self.groupView.frame))];
            // 4点(左上、右上、右下、左下)にトラッカーを合わせる
        
        // groundViewのsubviewとしてTrackerを追加
        [self.trackers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            IDPAWTrackerView *trackerView = obj;
            if( trackerView.superview != self.groundView){
                [self.groundView addSubview:trackerView];
            }else{
                [self.groundView bringSubviewToFront:trackerView];
            }
        }];
    
    }else{
        [self.trackers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [obj removeFromSuperview];
        }];
    }
}

- (void)firedGroundPan:(UIPanGestureRecognizer *)panGestureRecognizer
{
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
            
            // コード整理必須
            __block CGRect rectGroup = CGRectNull;
            [self.groundView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                IDPAWAbstRenderView *renderView = [obj isKindOfClass:[IDPAWAbstRenderView class]] ? obj : nil;
                    // subviewからRenderViewを用意
                
                if (renderView != nil ) {
                    // 矩形衝突が認められた場合
                    if( [renderView hittestWithRect:testRect] ){
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
            [self rotateSelectedObjectWithRotation:rotationGestureRecognizer.rotation];
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
            // グループを買い解除
    }else{
        //　グループを選択したオブジェクトに同期
        self.groupView.frame = _originalGroupFrame = renderView.frame;
        [self.groundView addSubview:self.groupView];
        [self.groupView setNeedsDisplay];
            // グループの描画を更新する
        [self.groupFrameView setNeedsDisplay];
            // グレープフレームの描画を更新する
        [self synchronizeTracker];    }
    
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
                
                [targetView.superview.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    IDPAWAbstRenderView *renderView = [obj isKindOfClass:[IDPAWAbstRenderView class]] ? obj : nil;
                    if( renderView.selected == YES && targetView != renderView){
                        renderView.center = CGPointMake(renderView.center.x - deltaPoint.x, renderView.center.y - deltaPoint.y);
                    }
                    
                    _originalGroupFrame = self.groupView.frame;
                }];
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

- (void)firedObjectPan:(UIPanGestureRecognizer *)panGestureRecognizer
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
            
            CGPoint movedPoint = CGPointMake(targetView.center.x + p.x, targetView.center.y + p.y);
                // 移動距離を計算
            
            CGPoint deltaPoint = CGPointMake(targetView.center.x - movedPoint.x,targetView.center.y - movedPoint.y);
            targetView.center = movedPoint;
            [panGestureRecognizer setTranslation:CGPointZero inView:targetView];
                // ジェスチャをリセット
            
            IDPAWAbstRenderView *renderView = [targetView isKindOfClass:[IDPAWAbstRenderView class]] ? (IDPAWAbstRenderView *)targetView : nil;
            
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
                
                
            }else if( panGestureRecognizer.state == UIGestureRecognizerStateEnded ){

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
        {
            UIView *targetView = panGestureRecognizer.view;
            
            CGPoint p = CGPointZero;
            /*CGPoint*/ p = [panGestureRecognizer translationInView:targetView];
            
            CGPoint movedPoint = CGPointMake(targetView.center.x + p.x, targetView.center.y + p.y);
            targetView.center = movedPoint;
            [panGestureRecognizer setTranslation:CGPointZero inView:targetView];
                // トラッカーの位置を変更
            
            if( panGestureRecognizer.state == UIGestureRecognizerStateChanged || panGestureRecognizer.state == UIGestureRecognizerStateEnded){
                NSInteger index = [self.trackers indexOfObject:targetView];
                NSInteger diagonalIndex = (index + 2) % 4; // 対角線上の位置を取得

                UIBezierPath *beziePath = [[UIBezierPath alloc] init];
                [beziePath moveToPoint:[self.trackers[index] center]];
                [beziePath addLineToPoint:[self.trackers[diagonalIndex] center]];
                    // Pathを使ってサイズを計算
                
                CGRect bounds = beziePath.bounds;
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
                        bounds =  CGRectOffset(bounds,0 ,0);
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
                [targetView != self.trackers[0] ? self.trackers[0] : self.dummyTrackerView setCenter:CGPointMake(CGRectGetMinX(self.groupView.frame),CGRectGetMinY(self.groupView.frame))];
                
                [targetView != self.trackers[1] ? self.trackers[1] : self.dummyTrackerView setCenter:CGPointMake(CGRectGetMaxX(self.groupView.frame),CGRectGetMinY(self.groupView.frame))];
                
                [targetView != self.trackers[2] ? self.trackers[2] : self.dummyTrackerView setCenter:CGPointMake(CGRectGetMaxX(self.groupView.frame),CGRectGetMaxY(self.groupView.frame))];
                
                [targetView != self.trackers[3] ? self.trackers[3] : self.dummyTrackerView setCenter:CGPointMake(CGRectGetMinX(self.groupView.frame),CGRectGetMaxY(self.groupView.frame))];
             
                // 終了後にDummtTrackerをTrackerに置き換える
                if( panGestureRecognizer.state == UIGestureRecognizerStateEnded ){
                    
                    CGFloat ratio = CGRectGetWidth(self.groupView.frame) / CGRectGetWidth(_originalGroupFrame);
                        // 比率を計算
                    
                    NSLog(@"_originalGroupFrame=%@",[NSValue valueWithCGRect:_originalGroupFrame]);
                    NSLog(@"self.groupView.frame=%@",[NSValue valueWithCGRect:self.groupView.frame]);
                    
//                    CGPoint offset = CGPointMake(  CGRectGetMinX(_originalGroupFrame) - CGRectGetMinX(self.groupView.frame)
//                                                 , CGRectGetMinY(_originalGroupFrame) - CGRectGetMinY(self.groupView.frame) );
                    
                    // 選択状態のオブジェクトの位置を把握
                    [self.groundView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        IDPAWAbstRenderView *renderView = [obj isKindOfClass:[IDPAWAbstRenderView class]] ? obj : nil;
                        if( renderView.selected == YES ){
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
                            
                            NSLog(@"delta=%@",[NSValue valueWithCGPoint:renderView.center]);
                            
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
        case UIGestureRecognizerStateCancelled:
            break;
        default:
            break;
    }
}

@end
