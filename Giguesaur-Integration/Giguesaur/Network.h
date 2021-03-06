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
#import "Debug.h"

@class Graphics;

@interface Network : NSObject


@property (nonatomic) void* socket;
@property (nonatomic) void* context;
@property (nonatomic) void* recvSocket;
@property (nonatomic) void* recvBoard;
@property (nonatomic) NSString *address;
@property (nonatomic) int heldPiece;
@property (nonatomic) NSString *name;
@property (nonatomic) int wantedPiece;
@property (nonatomic) int recvMessagesCount;
@property NSDate *lastRequest;
@property (nonatomic) NSDate *lastHeard;
@property (nonatomic) NSMutableArray *buttons;
@property BOOL hasImage;
@property BOOL timedOut;

@property Graphics* graphics;

-(void)prepare:(NSString*) address;
-(void)droppedPiece:(float)xNum WithY:(float)yNum WithRotation:(float)rotationNum;
-(void)requestPiece:(int)pieceNum;
-(void)checkMessages;
-(void)setUpMode:(BOOL)withImage;
-(NSString *)messageToNSString:(zmq_msg_t) message;

@end
