//
//  IDPAWMoveCommand.m
//  IDPAuthoringWorkspace
//
//  Created by 能登 要 on 2014/11/23.
//  Copyright (c) 2014年 Irimasu Densan Planning. All rights reserved.
//

#import "IDPAWMoveCommand.h"
#import "IDPAWAbstRenderView.h"

@interface IDPAWMoveCommand ()
@property (strong,nonatomic) IDPAWAbstRenderView *view;
@property (copy,nonatomic) IDPAWCommandPrepareBlock block;
@property (assign,nonatomic) CGPoint location;
@end

@implementation IDPAWMoveCommand

+ (IDPAWMoveCommand *) moveCommandWithView:(IDPAWAbstRenderView *)renderView location:(CGPoint)location block:(IDPAWCommandPrepareBlock)block
{
    IDPAWMoveCommand* moveCommand = [[IDPAWMoveCommand alloc] init];
    
    moveCommand.view = renderView;
    moveCommand.location = location;
    moveCommand.block = block;
    
    return moveCommand;
}

- (IDPAWAbstCommand *) execute
{
    CGPoint redoLocation = self.view.center;
    
    self.view.center = self.location;

    if( self.block != nil ){
        self.block(self,@[self.view]);
    }
    
    IDPAWAbstCommand *command = [IDPAWMoveCommand moveCommandWithView:self.view location:redoLocation block:self.block];
    self.view = nil;
    
    return command;
}

@end
