//
//  IDPAWAbstCommand.h
//  IDPAuthoringWorkspace
//
//  Created by 能登 要 on 2014/11/14.
//  Copyright (c) 2014年 Irimasu Densan Planning. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IDPAWAbstRenderView;
@class IDPAWAbstCommand;
typedef void (^IDPAWCommandPrepareBlock)(IDPAWAbstCommand *command,IDPAWAbstRenderView *objectView);

@interface IDPAWAbstCommand : NSObject

- (IDPAWAbstCommand *) execute; // コマンドの実行

@end
