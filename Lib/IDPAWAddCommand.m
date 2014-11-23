//
//  IDPAWAddCommand.m
//  IDPAuthoringWorkspace
//
//  Created by 能登 要 on 2014/11/14.
//  Copyright (c) 2014年 Irimasu Densan Planning. All rights reserved.
//

#import "IDPAWAddCommand.h"
#import "IDPAWAbstRenderView.h"
#import "IDPAWDeleteCommand.h"

@interface IDPAWAddCommand ()
@property (strong,nonatomic) IDPAWAbstRenderView *view;
@property (weak,nonatomic) UIView *superView;
@property (copy,nonatomic) IDPAWCommandPrepareBlock block;
@end

@implementation IDPAWAddCommand

+ (IDPAWAddCommand *) addCommandWithView:(IDPAWAbstRenderView *)renderView block:(IDPAWCommandPrepareBlock)block
{
    IDPAWAddCommand* addCommand = [[IDPAWAddCommand alloc] init];
    addCommand.view = renderView;
    addCommand.superView = renderView.superview;
    addCommand.block = block;
    return addCommand;
}

- (IDPAWAbstCommand *) execute
{
    self.view.proxyRender = NO;
    [self.superView addSubview:self.view];
        // 親に追加
    
    if( self.block != nil ){
        self.block(self,@[self.view]);
    }
    
    IDPAWAbstCommand *command = [IDPAWDeleteCommand deleteCommandWithView:self.view block:self.block];
    
    
    self.superView = nil;
    self.view = nil;
    
    return command;
}

@end
