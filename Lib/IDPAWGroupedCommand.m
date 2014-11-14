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
@end

@implementation IDPAWGroupedCommand

+ (IDPAWGroupedCommand *) groupedCommandWithCommands:(NSArray *)commands
{
    IDPAWGroupedCommand *groupedCommand = [[IDPAWGroupedCommand alloc] init];
    groupedCommand.commands = [NSMutableArray arrayWithArray:commands];
    return groupedCommand;
}

- (IDPAWAbstCommand *) execute
{
    NSMutableArray *array = [NSMutableArray array];
    
    while (self.commands.count) {
        IDPAWAbstCommand *command = self.commands.lastObject;
        [self.commands removeObject:self.commands.lastObject];
        
        IDPAWAbstCommand *undoCommand = [command execute];
        if( undoCommand != nil ){
            array[array.count] = undoCommand;
        }
    }
    
    return [IDPAWGroupedCommand groupedCommandWithCommands:array];
}



@end
