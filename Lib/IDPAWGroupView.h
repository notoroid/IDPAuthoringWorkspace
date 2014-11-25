//
//  IDPAWGroupView.h
//  IDPAuthoringWorkspace
//
//  Created by 能登 要 on 2014/10/18.
//  Copyright (c) 2014年 Irimasu Densan Planning. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol IDPAWGroupViewDelegate;

@interface IDPAWGroupView : UIView
- (BOOL) hittestWithLocation:(CGPoint)location;
- (BOOL) hasReplicableObjects;
@property (weak,nonatomic) id<IDPAWGroupViewDelegate>delegate;
@end

@protocol IDPAWGroupViewDelegate <NSObject>
- (void)groupViewArchiveDataWithObjectViews:(NSArray *)objectViews;
@end

