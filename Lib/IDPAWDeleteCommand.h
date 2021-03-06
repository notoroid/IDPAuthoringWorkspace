//
//  IDPAWDeleteCommand.h
//  IDPAuthoringWorkspace
//
//  Created by 能登 要 on 2014/11/14.
//  Copyright (c) 2014年 Irimasu Densan Planning. All rights reserved.
//

#import "IDPAWAbstCommand.h"

@interface IDPAWDeleteCommand : IDPAWAbstCommand

+ (IDPAWDeleteCommand *) deleteCommandWithView:(IDPAWAbstRenderView *)renderView block:(IDPAWCommandPrepareBlock)block;

@end
