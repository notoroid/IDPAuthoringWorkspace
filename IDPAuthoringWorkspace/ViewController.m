//
//  ViewController.m
//  IDPAuthoringWorkspace
//
//  Created by 能登 要 on 2014/10/23.
//  Copyright (c) 2014年 Irimasu Densan Planning. All rights reserved.
//

#import "ViewController.h"
#import "EditObjectView.h"

static double degreesToRadians(double degrees);
static double degreesToRadians(double degrees) {return degrees * M_PI / 180;}

@interface ViewController ()
{
    BOOL _initialized;
    __weak IBOutlet UIView *_groundView;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.toolbarItems = @[ [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:self action:@selector(firedAdd:)]
                           ,[[UIBarButtonItem alloc] initWithTitle:@"Delete" style:UIBarButtonItemStylePlain target:self action:@selector(firedDelete:)]
                           ];
    self.navigationController.toolbarHidden = NO;
}

- (void)firedAdd:(id)sender
{
    EditObjectView *editObjectView = [[EditObjectView alloc] initWithFrame:(CGRect){CGPointZero,CGSizeMake(200, 180)}];
    editObjectView.center = self.groundView.center;
    editObjectView.backgroundColor = [UIColor clearColor]/*[UIColor lightGrayColor]*/;
    editObjectView.opaque = NO;
    editObjectView.clipsToBounds = NO;
    editObjectView.transform = CGAffineTransformMakeRotation(degreesToRadians(0.0f) );
    
    [self addObjectView:editObjectView];
    // オブジェクトを追加
    
    [self clearSelection];
    
    [self selectObjectViews:@[editObjectView]];
}

- (void)firedDelete:(id)sender
{
    [self deleteSelectedObject];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (UIView *) groundView
{
    return _groundView;
}

- (void) viewWillLayoutSubviews
{
    [super viewDidLayoutSubviews];
    if( _initialized != YES ){
        _initialized = YES;
        
        // レイアウトが決定してからテストオブジェクトを追加
        
        NSArray *centers = @[  [NSValue valueWithCGPoint:CGPointMake(CGRectGetMidX(self.groundView.frame),CGRectGetMidY(self.groundView.frame))]
                               ,[NSValue valueWithCGPoint:CGPointMake(CGRectGetMidX(self.groundView.frame) + 20.0f ,CGRectGetMidY(self.groundView.frame) + 20.0f)]
                               ];
        
        NSArray *bounds = @[ [NSValue valueWithCGRect:CGRectMake(0, 0, 120, 80)]
                             ,[NSValue valueWithCGRect:CGRectMake(0, 0, 120, 80)]
                             ];
        
        [centers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            CGRect lineBounds = [bounds[idx] CGRectValue];;
            CGPoint center = [obj CGPointValue] /*CGPointMake(CGRectGetMidX(self.groundView.frame),CGRectGetMidY(self.groundView.frame))*/;
            
            EditObjectView *editObjectView = [[EditObjectView alloc] initWithFrame:lineBounds];
            editObjectView.center = center;
            editObjectView.backgroundColor = [UIColor clearColor]/*[UIColor lightGrayColor]*/;
            editObjectView.opaque = NO;
            editObjectView.clipsToBounds = NO;
            editObjectView.transform = CGAffineTransformMakeRotation(degreesToRadians(0.0f) );
            
            [self addObjectView:editObjectView];
            // オブジェクトを追加
        }];
    }
}

@end
