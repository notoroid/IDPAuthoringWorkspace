//
//  IDPAWTransformCommand.h
//  IDPAuthoringWorkspace
//
//  Created by 能登 要 on 2014/11/23.
//  Copyright (c) 2014年 Irimasu Densan Planning. All rights reserved.
//

#import "IDPAWAbstCommand.h"

@interface IDPAWTransformCommand : IDPAWAbstCommand

+ (IDPAWTransformCommand *) transformCommandWithView:(IDPAWAbstRenderView *)renderView location:(CGPoint)location transform:(CGAffineTransform)transform block:(IDPAWCommandPrepareBlock)block;

@end
