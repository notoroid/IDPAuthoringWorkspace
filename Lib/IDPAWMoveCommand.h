//
//  IDPAWMoveCommand.h
//  IDPAuthoringWorkspace
//
//  Created by 能登 要 on 2014/11/23.
//  Copyright (c) 2014年 Irimasu Densan Planning. All rights reserved.
//

#import "IDPAWAbstCommand.h"

@interface IDPAWMoveCommand : IDPAWAbstCommand

+ (IDPAWMoveCommand *) moveCommandWithView:(IDPAWAbstRenderView *)renderView location:(CGPoint)location block:(IDPAWCommandPrepareBlock)block;

@end
