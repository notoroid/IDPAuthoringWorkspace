//
//  IDPAWTrackerView.m
//  IDPAuthoringWorkspace
//
//  Created by 能登 要 on 2014/10/19.
//  Copyright (c) 2014年 Irimasu Densan Planning. All rights reserved.
//

#import "IDPAWTrackerView.h"
#import "IDPAWStyleKit.h"

@implementation IDPAWTrackerView

- (void)drawRect:(CGRect)rect
{
    if( _enterTraking != YES ){
        [IDPAWStyleKit drawTrackerWithFrame:rect];
    }
}

@end
