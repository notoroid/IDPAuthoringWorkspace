//
//  IDPAWDeleteCommand.m
//  IDPAuthoringWorkspace
//
//  Created by 能登 要 on 2014/11/14.
//  Copyright (c) 2014年 Irimasu Densan Planning. All rights reserved.
//

#import "IDPAWDeleteCommand.h"
#import "IDPAWAbstRenderView.h"
#import "IDPAWAddCommand.h"

@interface IDPAWDeleteCommand ()
@property (strong,nonatomic) IDPAWAbstRenderView *view;
@property (weak,nonatomic) UIView *superView;
@property (copy,nonatomic) IDPAWCommandPrepareBlock block;
@end

@implementation IDPAWDeleteCommand

+ (IDPAWDeleteCommand *) deleteCommandWithView:(IDPAWAbstRenderView *)renderView block:(IDPAWCommandPrepareBlock)block
{
    IDPAWDeleteCommand* deleteCommand = [[IDPAWDeleteCommand alloc] init];
    deleteCommand.view = renderView;
    deleteCommand.block = block;
    return deleteCommand;
}

- (IDPAWAbstCommand *) execute
{
    IDPAWAddCommand *command = [IDPAWAddCommand addCommandWithView:self.view block:self.block];
    
    if( self.block != nil ){
        self.block(self,self.view);
    }
    
//    self.view.proxyRender = NO;
    [self.view removeFromSuperview];
        // オブジェクトを削除
    
    return command;
}


@end
