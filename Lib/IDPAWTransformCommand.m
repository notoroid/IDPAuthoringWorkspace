//
//  IDPAWTransformCommand.m
//  IDPAuthoringWorkspace
//
//  Created by 能登 要 on 2014/11/23.
//  Copyright (c) 2014年 Irimasu Densan Planning. All rights reserved.
//

#import "IDPAWTransformCommand.h"
#import "IDPAWAbstRenderView.h"

@interface IDPAWTransformCommand ()
@property (strong,nonatomic) IDPAWAbstRenderView *view;
@property (copy,nonatomic) IDPAWCommandPrepareBlock block;
@property (assign,nonatomic) CGPoint location;
@property (assign,nonatomic) CGAffineTransform transform;
@end

@implementation IDPAWTransformCommand

+ (IDPAWTransformCommand *) transformCommandWithView:(IDPAWAbstRenderView *)renderView location:(CGPoint)location transform:(CGAffineTransform)transform block:(IDPAWCommandPrepareBlock)block
{
    IDPAWTransformCommand* transformCommand = [[IDPAWTransformCommand alloc] init];
    
    transformCommand.view = renderView;
    transformCommand.location = location;
    transformCommand.transform = transform;
    transformCommand.block = block;
    
    return transformCommand;
}

- (IDPAWAbstCommand *) execute
{
    CGPoint redoLocation = self.view.center;
    CGAffineTransform redoTransform = self.view.transform;
    
    self.view.transform = self.transform;
    self.view.center = self.location;
    
    
    if( self.block != nil ){
        self.block(self,@[self.view]);
    }
    
    IDPAWAbstCommand *command = [IDPAWTransformCommand transformCommandWithView:self.view location:redoLocation transform:redoTransform block:self.block];
    self.view = nil;
    
    return command;
}

@end
