//
//  main.m
//  TestServer
//
//  Created by Shahne Rodgers on 3/16/15.
//  Copyright (c) 2015 Shahne Rodgers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "zmq.h"
#import "PublishingDelegate.h"
#import "zhelpers.h"
#import "Puzzle.h"
#import "SimpleMath.h"

#define PIECES_ROW NUM_OF_ROWS
#define PIECES_COLUMN NUM_OF_COLS

double TIMEOUT = 200;

CFNetServiceRef broadcaster;
PublishingDelegate *delegate;
SimpleMath *simpleMath;
void *boardState;
NSMutableArray *heldPieces;
NSMutableArray *players;
int pieceLocations[PIECES_ROW*PIECES_COLUMN][3];
Piece pieces[NUM_OF_PIECES];
void *publisher;
void *receiver;
int imageLen;

void checkThenSnapPiece(int pieceID);
void checkThenCloseEdge(int pieceID);
void openClosedEdges(int pieceID);


void registerCallback (
                       CFNetServiceRef theService,
                       CFStreamError* error,
                       void* info)
{
    NSLog(@"Service registered: %@", error);
}

void publishService(){
    broadcaster = CFNetServiceCreate(NULL, CFSTR(""), CFSTR("_zeromq._tcp"), CFSTR("Giguesaur"), 5555);
    CFStreamError error;
    CFNetServiceClientContext context = {0, NULL, NULL, NULL, NULL};
    CFNetServiceSetClient(broadcaster, registerCallback, &context);
    CFNetServiceScheduleWithRunLoop(broadcaster, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    
    if (!CFNetServiceRegisterWithOptions(broadcaster, 0, &error)){
        NSLog(@"Error registering the service %i", error.error);
    }
    
}

const char* getStringFromInt(int num){
    return [[[NSString alloc] initWithFormat:@"%d", num] UTF8String];
}

void sendBoard(){
    zmq_send(publisher, "SetupMode", 9, ZMQ_SNDMORE);
    int pic = zmq_send(publisher, boardState, imageLen, ZMQ_SNDMORE);
    char *numRows = (char *)getStringFromInt(PIECES_ROW);
    char *numCols = (char *)getStringFromInt(PIECES_COLUMN);
    zmq_send(publisher, numRows, sizeof(numRows), ZMQ_SNDMORE);
    zmq_send(publisher, numCols, sizeof(numCols), ZMQ_SNDMORE);
    int arr = zmq_send(publisher, pieces, sizeof(pieces), 0);
    if (pic < 0 || arr < 0)
        NSLog(@"%s", strerror(errno));
    
}

int getIntFromMessage(){
    zmq_msg_t message;
    zmq_msg_init(&message);
    
    int size = zmq_msg_recv(&message, receiver, 0);
    char buf[size+1];
    memcpy(buf, zmq_msg_data(&message), size);
    buf[size] = '\0';
    int num = atoi(buf);
    if (num < 0){
        NSLog(@"Error converting num: %s", zmq_msg_data(&message));
    }
    zmq_msg_close(&message);
    return num;
}

void dropPiece(int pieceNum, zmq_msg_t x, zmq_msg_t y, zmq_msg_t r){
    if (pieceNum >= [heldPieces count]){
        return;
    }
    heldPieces[pieceNum] = [NSNull null];
    const char *piece = getStringFromInt(pieceNum);
    
    //Fix pieceLocations array to store new correct locations
    pieceLocations[pieceNum][0] = atoi(zmq_msg_data(&x));
    pieceLocations[pieceNum][1] = atoi(zmq_msg_data(&y));
    pieceLocations[pieceNum][2] = atoi(zmq_msg_data(&r));
    
    checkThenSnapPiece(pieceNum);
    checkThenCloseEdge(pieceNum);
    
    //Inform everyone of the new location
    zmq_send(publisher, "Drop", 4, ZMQ_SNDMORE);
    zmq_send(publisher, piece, sizeof(piece), ZMQ_SNDMORE);
    zmq_send(publisher, zmq_msg_data(&x), zmq_msg_size(&x), ZMQ_SNDMORE);
    zmq_send(publisher, zmq_msg_data(&y), zmq_msg_size(&y), ZMQ_SNDMORE);
    zmq_send(publisher, zmq_msg_data(&r), zmq_msg_size(&r), 0);
    
    zmq_msg_close(&x);
    zmq_msg_close(&y);
    zmq_msg_close(&r);
}


void receiveMessage(){
    zmq_msg_t type;
    zmq_msg_init(&type);
    zmq_msg_t identity;
    zmq_msg_init(&identity);
    
    //Receive the message sender.
    int ilen = zmq_msg_recv(&identity, receiver, ZMQ_DONTWAIT);
    //If there's no message, return.
    if (ilen < 0){
        zmq_msg_close(&type);
        zmq_msg_close(&identity);
        return;
    }
    //Receive the message type.
    zmq_msg_recv(&type, receiver, 0);
    NSString *stringType = [[NSString alloc] initWithFormat:@"%s", zmq_msg_data(&type)];
    
    //If the message is a pickup request
    if ([stringType hasPrefix:@"PickUp"]){
        //store which piece needs to be picked up.
        int pieceNum = getIntFromMessage();
        const char* pieceString = getStringFromInt(pieceNum);
        
        //If the piece is not being held
        if ([heldPieces[pieceNum] isEqual:[NSNull null]]){
            openClosedEdges(pieceNum);
            //NSLog(@"%s picked up %i", zmq_msg_data(&identity), pieceNum);
            //Inform everyone that a piece has been picked up.
            zmq_send(publisher, "PickUp", 6, ZMQ_SNDMORE);
            
            //Send the identity of the picker-upperer.
            const char* iden = zmq_msg_data(&identity);
            zmq_send(publisher, iden, ilen, ZMQ_SNDMORE);
            
            //Send the piece that has been taken
            zmq_send(publisher, pieceString, sizeof(pieceString), 0);
            
            //Set the timestamp of the piece
            heldPieces[pieceNum] = [NSDate date];
            //Set the location of the piece
            pieceLocations[pieceNum][0] = -1;
            pieceLocations[pieceNum][1] = -1;
        } else {
            NSLog(@"Piece %i has already been taken %@", pieceNum, heldPieces[pieceNum]);
        }
        
        //If the message is a notification that a piece has been dropped
    } else if ([stringType hasPrefix:@"Drop"]){
        //Receive pieceNum
        int pieceNum = getIntFromMessage();
        
        //Receive x
        zmq_msg_t x;
        zmq_msg_init(&x);
        zmq_msg_recv(&x, receiver, 0);
        //Receive y
        zmq_msg_t y;
        zmq_msg_init(&y);
        zmq_msg_recv(&y, receiver, 0);
        //Receive rotation
        zmq_msg_t rotation;
        zmq_msg_init(&rotation);
        zmq_msg_recv(&rotation, receiver, 0);
        
        dropPiece(pieceNum, x, y, rotation);
        //NSLog(@"%s dropped %i", zmq_msg_data(&identity), pieceNum);
        
        
        //If the message is to inform the server that the client is still around
    } else if ([stringType hasPrefix:@"KeepAlive"]){
        int pieceNum = getIntFromMessage();
        if (![heldPieces[pieceNum] isEqual:[NSNull null]])
            heldPieces[pieceNum] = [NSDate date];
    //Ensure no duplicate names
    } else if ([stringType hasPrefix:@"Intro"]){
        NSString *name = [[NSString alloc]initWithFormat:@"%s", zmq_msg_data(&identity)];
        NSLog(@"Name %@", name);
        for (NSString *p in players){
            if ([name hasPrefix:p]){
                NSLog(@"Pre-existing name");
                zmq_send(publisher, "Error", 5, ZMQ_SNDMORE);
                zmq_send(publisher, zmq_msg_data(&identity), zmq_msg_size(&identity), 0);
                return;
            }
        }
        [players addObject:name];
    //Otherwise we'll assume it's a chat message.
    } else {
    }
    //NSLog(@"Held pieces: %@", heldPieces);
}

void checkPieces(){
    for (int i = 0; i < [heldPieces count]; i++){
        id piece = heldPieces[i];
        if (! [piece isEqual:[NSNull null]]){
            NSTimeInterval interval = -1 * [piece timeIntervalSinceNow];
            if (interval > TIMEOUT){
                zmq_msg_t xMes;
                char* x = (char*)getStringFromInt(arc4random() % BOARD_WIDTH);
                zmq_msg_init_data(&xMes, x, sizeof(x), nil, nil);
                zmq_msg_t yMes;
                char* y = (char *)getStringFromInt(arc4random() % BOARD_HEIGHT);
                zmq_msg_init_data(&yMes, y, sizeof(y), nil, nil);
                zmq_msg_t rMes;
                char* r = (char *)getStringFromInt(arc4random() % 360);
                zmq_msg_init_data(&rMes, r, sizeof(r), nil, nil);
                
                dropPiece(i, xMes, yMes, rMes);
                NSLog(@"Dropped piece %i after interval %f", i, interval);
            }
        }
    }
}

void startServer(){
    //  Socket to talk to clients
    void *context = zmq_ctx_new ();
    receiver = zmq_socket(context, ZMQ_ROUTER);
    zmq_setsockopt(receiver, ZMQ_SNDHWM, "", 1);
    zmq_setsockopt(receiver, ZMQ_RCVHWM, "", 50000);
    publisher = zmq_socket(context, ZMQ_PUB);
    int rb = zmq_bind(receiver, "tcp://*:5555");
    int pb = zmq_bind(publisher, "tcp://*:5556");
    if (rb < 0 || pb < 0){
        NSLog(@"Error binding: %s", strerror(errno));
        return;
    }
    
    NSLog(@"Listening on port 5555. Publishing on port 5556");
    NSDate *date = [NSDate date];
    
    while (true){
        //This loops too quickly if no messages are being received.
        if ([date timeIntervalSinceNow] < -TIMEOUT){
            sendBoard();
            date = [NSDate date];
            checkPieces();
        }
        receiveMessage();
        
    }
    
}

void readImage(NSString *path){
    NSError *errorPtr;
    NSData *image = [NSData dataWithContentsOfFile:path options:NSDataReadingUncached error:&errorPtr];
    if (errorPtr != NULL)
        NSLog(@"Error reading file: %@", errorPtr);
    imageLen = (int)[image length];
    boardState = malloc(imageLen);
    memcpy(boardState, [image bytes], imageLen);
}

void checkThenSnapPiece(int pieceID) {
    
    CGPoint newPoints;
    int upID = pieces[pieceID].neighbourPiece.up_piece;
    int downID = pieces[pieceID].neighbourPiece.down_piece;
    int leftID = pieces[pieceID].neighbourPiece.left_piece;
    int rightID = pieces[pieceID].neighbourPiece.right_piece;
    
    if (upID >= 0 &&
        [simpleMath shouldPieceSnap:pieces[pieceID]
                     withOtherPiece:pieces[upID]
                          whichSide:P_UP
                 distanceBeforeSnap:DISTANCE_BEFORE_SNAP]) {
            
            newPoints = [simpleMath newCoordinates:pieces[upID] whichSide:P_UP];
            pieces[pieceID].x_location = newPoints.x;
            pieces[pieceID].y_location = newPoints.y;
            pieces[pieceID].rotation = pieces[upID].rotation;
            
        }
    
    if (downID >= 0 &&
        [simpleMath shouldPieceSnap:pieces[pieceID]
                     withOtherPiece:pieces[downID]
                          whichSide:P_DOWN
                 distanceBeforeSnap:DISTANCE_BEFORE_SNAP]) {
            
            newPoints = [simpleMath newCoordinates:pieces[downID] whichSide:P_DOWN];
            pieces[pieceID].x_location = newPoints.x;
            pieces[pieceID].y_location = newPoints.y;
            pieces[pieceID].rotation = pieces[downID].rotation;
            
        }
    
    if (leftID >= 0 &&
        [simpleMath shouldPieceSnap:pieces[pieceID]
                     withOtherPiece:pieces[leftID]
                          whichSide:P_LEFT
                 distanceBeforeSnap:DISTANCE_BEFORE_SNAP]) {
            
            newPoints = [simpleMath newCoordinates:pieces[leftID] whichSide:P_LEFT];
            pieces[pieceID].x_location = newPoints.x;
            pieces[pieceID].y_location = newPoints.y;
            pieces[pieceID].rotation = pieces[leftID].rotation;
            
            
        }
    
    if (rightID >= 0 &&
        [simpleMath shouldPieceSnap:pieces[pieceID]
                     withOtherPiece:pieces[rightID]
                          whichSide:P_RIGHT
                 distanceBeforeSnap:DISTANCE_BEFORE_SNAP]) {
            
            newPoints = [simpleMath newCoordinates:pieces[rightID] whichSide: P_RIGHT];
            pieces[pieceID].x_location = newPoints.x;
            pieces[pieceID].y_location = newPoints.y;
            pieces[pieceID].rotation = pieces[rightID].rotation;
            
        }
}

// Check if a piece joined its neighbours then closes their edges
void checkThenCloseEdge(int pieceID) {
    
    int upID = pieces[pieceID].neighbourPiece.up_piece;
    int downID = pieces[pieceID].neighbourPiece.down_piece;
    int leftID = pieces[pieceID].neighbourPiece.left_piece;
    int rightID = pieces[pieceID].neighbourPiece.right_piece;
    
    if (upID >= 0 &&
        [simpleMath didPieceConnect:pieces[pieceID]
                     withOtherPiece:pieces[upID]
                          whichSide:P_UP]) {
            
            pieces[pieceID].openEdge.up_open = isClosed;
            pieces[upID].openEdge.down_open = isClosed;
            
        }
    
    if (downID >= 0 &&
        [simpleMath didPieceConnect:pieces[pieceID]
                     withOtherPiece:pieces[downID]
                          whichSide:P_DOWN]) {
            
            pieces[pieceID].openEdge.down_open = isClosed;
            pieces[downID].openEdge.up_open = isClosed;
            
        }
    
    if (leftID >= 0 &&
        [simpleMath didPieceConnect:pieces[pieceID]
                     withOtherPiece:pieces[leftID]
                          whichSide:P_LEFT]) {
            
            pieces[pieceID].openEdge.left_open = isClosed;
            pieces[leftID].openEdge.right_open = isClosed;
            
            
        }
    
    if (rightID >= 0 &&
        [simpleMath didPieceConnect:pieces[pieceID]
                     withOtherPiece:pieces[rightID]
                          whichSide:P_RIGHT]) {
            
            pieces[pieceID].openEdge.right_open = isClosed;
            pieces[rightID].openEdge.left_open = isClosed;
            
        }
}

// Open closed edges of pickedup piece and neighbouring edges
void openClosedEdges(int pieceID) {
    
    int upID = pieces[pieceID].neighbourPiece.up_piece;
    int downID = pieces[pieceID].neighbourPiece.down_piece;
    int leftID = pieces[pieceID].neighbourPiece.left_piece;
    int rightID = pieces[pieceID].neighbourPiece.right_piece;
    
    if (upID >= 0) {
        pieces[pieceID].openEdge.up_open = isOpen;
        pieces[upID].openEdge.down_open = isOpen;
        
    }
    if (downID >= 0) {
        pieces[pieceID].openEdge.down_open = isOpen;
        pieces[downID].openEdge.up_open = isOpen;
        
    }
    if (leftID >= 0) {
        pieces[pieceID].openEdge.left_open = isOpen;
        pieces[leftID].openEdge.right_open = isOpen;
        
    }
    if (rightID >= 0) {
        pieces[pieceID].openEdge.right_open = isOpen;
        pieces[rightID].openEdge.left_open = isOpen;
        
    }
}



int main(int argc, const char * argv[]) {
    NSLog(@"Remember to check the address");
    publishService();
    simpleMath = [[SimpleMath alloc] init];
    NSString *path = [[NSMutableString alloc] initWithFormat:@"%@/IMAGE.jpg", [[NSBundle mainBundle] resourcePath]];
    readImage(path);
    players = [NSMutableArray array];
    heldPieces = [NSMutableArray array];
    generatePieces(pieces);
    
    for (int i = 0; i < PIECES_COLUMN*PIECES_ROW; i++){
        [heldPieces addObject:[NSNull null]];
        
    }
    startServer();
    free(boardState);
    
    return 0;
}


