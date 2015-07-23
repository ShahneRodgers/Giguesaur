//
//  ChatController.h
//  Giguesaur
//
//  Created by Local Shahne on 4/9/15.
//  Copyright (c) 2015 Local Shahne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "zmq.h"

@interface Network : NSObject


@property (nonatomic) void* socket;
@property (nonatomic) void* recvSocket;
@property (nonatomic) NSString *address;
@property (nonatomic) int heldPiece;
@property (nonatomic) NSString *name;
@property (nonatomic) int wantedPiece;
@property (nonatomic) NSDate *date;
@property (nonatomic) NSMutableArray *buttons;
@property BOOL hasImage;
@property BOOL nameIssue;
@property NSDate *lastRequest;

-(void)setAddress:(NSString *) address;
-(void)prepare:(NSString*) address;
@end
