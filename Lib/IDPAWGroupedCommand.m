//
//  IDPAWGroupedCommand.m
//  IDPAuthoringWorkspace
//
//  Created by 能登 要 on 2014/11/14.
//  Copyright (c) 2014年 Irimasu Densan Planning. All rights reserved.
//

#import "IDPAWGroupedCommand.h"

@interface IDPAWGroupedCommand ()
@property (strong,nonatomic) NSMutableArray *commands;
@property (strong,nonatomic) NSArray *objectViews;
@property (copy,nonatomic) IDPAWCommandPrepareBlock block;
@end

@implementation IDPAWGroupedCommand

+ (IDPAWGroupedCommand *) groupedCommandWithCommands:(NSArray *)commands objectViews:(NSArray *)objectViews block:(IDPAWCommandPrepareBlock)block
{
    IDPAWGroupedCommand *groupedCommand = [[IDPAWGroupedCommand alloc] init];
    groupedCommand.commands = [NSMutableArray arrayWithArray:commands];
    groupedCommand.objectViews = objectViews;
    groupedCommand.block = block;
    return groupedCommand;
}

- (IDPAWAbstCommand *) execute
{
    NSMutableArray *array = [NSMutableArray array];
    
    NSArray *objectViews = self.objectViews;
    
    while (self.commands.count) {
        IDPAWAbstCommand *command = self.commands.lastObject;
        [self.commands removeObject:self.commands.lastObject];
        
        IDPAWAbstCommand *undoCommand = [command execute];
        if( undoCommand != nil ){
            array[array.count] = undoCommand;
        }
    }
    
    if( self.block != nil ){
        self.block(self,objectViews);
    }
    
    self.commands = nil;
    self.objectViews = nil;
    
    return [IDPAWGroupedCommand groupedCommandWithCommands:array objectViews:objectViews block:self.block];
}



@end
