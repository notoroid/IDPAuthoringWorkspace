//
//  IDPAWResizeCommand.m
//  IDPAuthoringWorkspace
//
//  Created by 能登 要 on 2014/11/23.
//  Copyright (c) 2014年 Irimasu Densan Planning. All rights reserved.
//

#import "IDPAWResizeCommand.h"
#import "IDPAWAbstRenderView.h"

@interface IDPAWResizeCommand ()
@property (strong,nonatomic) IDPAWAbstRenderView *view;
@property (copy,nonatomic) IDPAWCommandPrepareBlock block;
@property (assign,nonatomic) CGPoint location;
@property (assign,nonatomic) CGSize size;
@end

@implementation IDPAWResizeCommand

+ (IDPAWResizeCommand *) resizeCommandWithView:(IDPAWAbstRenderView *)renderView location:(CGPoint)location size:(CGSize)size block:(IDPAWCommandPrepareBlock)block
{
    IDPAWResizeCommand* resizeCommand = [[IDPAWResizeCommand alloc] init];

    resizeCommand.view = renderView;
    resizeCommand.location = location;
    resizeCommand.size = size;
    resizeCommand.block = block;
    
    return resizeCommand;    return nil;
}

- (IDPAWAbstCommand *) execute
{
    CGPoint redoLocation = self.view.center;
    CGSize redoSize = self.view.bounds.size;

    self.view.bounds = (CGRect){self.view.bounds.origin,self.size};
    self.view.center = self.location;
    
    if( self.block != nil ){
        self.block(self,@[self.view]);
    }
    
    IDPAWAbstCommand *command = [IDPAWResizeCommand resizeCommandWithView:self.view location:redoLocation size:redoSize block:self.block];
    self.view = nil;
    
    return command;
}

@end
