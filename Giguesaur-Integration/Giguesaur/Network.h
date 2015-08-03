//
//  ChatController.h
//  Giguesaur
//
//  Created by Local Shahne on 4/9/15.
//  Copyright (c) 2015 Local Shahne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "zmq.h"
#import "Graphics.h"

@class Graphics;

@interface Network : NSObject


@property (nonatomic) void* socket;
@property (nonatomic) void* context;
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
@property Graphics* graphics;

-(void)prepare:(NSString*) address called:(NSString *)name;
-(void)droppedPiece:(int)xNum WithY:(int)yNum WithRotation:(int)rotationNum;
-(void)requestPiece:(int)pieceNum;


-(void)checkMessages;

-(NSString *)messageToNSString:(zmq_msg_t) message;

@end
