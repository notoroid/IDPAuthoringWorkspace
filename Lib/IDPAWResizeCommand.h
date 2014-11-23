//
//  IDPAWResizeCommand.h
//  IDPAuthoringWorkspace
//
//  Created by 能登 要 on 2014/11/23.
//  Copyright (c) 2014年 Irimasu Densan Planning. All rights reserved.
//

#import "IDPAWAbstCommand.h"

@interface IDPAWResizeCommand : IDPAWAbstCommand

+ (IDPAWResizeCommand *) resizeCommandWithView:(IDPAWAbstRenderView *)renderView location:(CGPoint)location size:(CGSize)size block:(IDPAWCommandPrepareBlock)block;

@end
