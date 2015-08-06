//
//  main.m
//  TestServer
//
//  Created by Shahne Rodgers on 3/16/15.
//  Modified by Ashley Manson
//  Copyright (c) 2015 Shahne Rodgers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "zmq.h"
#import "PublishingDelegate.h"
#import "zhelpers.h"
#import "Giguesaur/Puzzle.h"
#import "Giguesaur/PieceNeighbours.h"
#import "SimpleMath/SimpleMath.h"

double TIMEOUT = 6;

CFNetServiceRef broadcaster;
PublishingDelegate *delegate;
PieceNeighbours *pieceNeighbours;
SimpleMath *simpleMath;
void *boardState;
NSMutableArray *heldPieces;
NSMutableArray *players;
Piece pieces[NUM_OF_PIECES];
void *publisher;
void *receiver;
int imageLen;
NSDate *lastSent;

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

const char* getStringFromFloat(float num){
    return [[[NSString alloc] initWithFormat:@"%f", num] UTF8String];
}

const char* getStringFromInt(int num){
    return [[[NSString alloc] initWithFormat:@"%d", num] UTF8String];
}

void sendBoard(){
    zmq_send(publisher, "SetupMode", 9, ZMQ_SNDMORE);
    int pic = zmq_send(publisher, boardState, imageLen, ZMQ_SNDMORE);
    char *numRows = (char *)getStringFromInt(NUM_OF_ROWS);
    char *numCols = (char *)getStringFromInt(NUM_OF_COLS);
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

void dropPiece(int pieceNum, float x, float y, float r){
    if (pieceNum >= [heldPieces count]){
        return;
    }
    heldPieces[pieceNum] = [NSNull null];
    const char *piece = getStringFromFloat(pieceNum);
    
    //Fix pieceLocations array to store new correct locations
    pieces[pieceNum].x_location = x;
    pieces[pieceNum].y_location = y;
    pieces[pieceNum].rotation = r;
    pieces[pieceNum].held = P_FALSE;

    // Check Piece Neighbours
    [pieceNeighbours checkThenSnapPiece:pieceNum andPieces:pieces];
    [pieceNeighbours checkThenCloseEdge:pieceNum andPieces:pieces];
    
    
    //Locations may have been changed by Ash's methods so reset messages
    const char* newX = getStringFromFloat(pieces[pieceNum].x_location);
    const char* newY = getStringFromFloat(pieces[pieceNum].y_location);
    const char* newR = getStringFromFloat(pieces[pieceNum].rotation);
    
    //Inform everyone of the new location
    zmq_send(publisher, "Drop", 4, ZMQ_SNDMORE);
    zmq_send(publisher, piece, sizeof(piece), ZMQ_SNDMORE);
    zmq_send(publisher, newX, sizeof(newX), ZMQ_SNDMORE);
    zmq_send(publisher, newY, sizeof(newY), ZMQ_SNDMORE);
    zmq_send(publisher, newR, sizeof(newR), 0);
    lastSent = [NSDate date];
}

NSString* messageToNSString(zmq_msg_t message){
    char charIdent[zmq_msg_size(&message)+1];
    memcpy(charIdent, zmq_msg_data(&message), sizeof(charIdent));
    charIdent[zmq_msg_size(&message)] = '\0';
    return [[NSString alloc] initWithFormat:@"%s", charIdent];
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
    NSString *stringType = messageToNSString(type);
    
    //If the message is a pickup request
    if ([stringType hasPrefix:@"PickUp"]){
        //store which piece needs to be picked up.
        int pieceNum = getIntFromMessage();
        const char* pieceString = getStringFromInt(pieceNum);
        
        //If the piece is not being held
        if ([heldPieces[pieceNum] isEqual:[NSNull null]]){

            // Open Piece Edges when it is picked up
            resetEdgesOfPiece(pieceNum, pieces);
            
            //NSLog(@"%s picked up %i", zmq_msg_data(&identity), pieceNum);
            //Inform everyone that a piece has been picked up.
            zmq_send(publisher, "PickUp", 6, ZMQ_SNDMORE);
            
            //Send the identity of the picker-upperer.
            const char* iden = zmq_msg_data(&identity);
            NSLog(@"Picked up by %@", messageToNSString(identity));
            zmq_send(publisher, iden, ilen, ZMQ_SNDMORE);
            
            //Send the piece that has been taken
            zmq_send(publisher, pieceString, sizeof(pieceString), 0);
            
            //Update the lastSent
            lastSent = [NSDate date];
            
            //Set the timestamp of the piece
            heldPieces[pieceNum] = [NSDate date];
            //Set the location of the piece
            pieces[pieceNum].held = P_TRUE;
        } else {
            NSLog(@"Piece %i has already been taken %@", pieceNum, heldPieces[pieceNum]);
        }
        
        //If the message is a notification that a piece has been dropped
    } else if ([stringType hasPrefix:@"Drop"]){
        //Receive pieceNum
        int pieceNum = getIntFromMessage();
        
        //Receive x
        zmq_msg_t xMes;
        zmq_msg_init(&xMes);
        zmq_msg_recv(&xMes, receiver, 0);
        float x = atof(zmq_msg_data(&xMes));
        //Receive y
        zmq_msg_init(&xMes);
        zmq_msg_recv(&xMes, receiver, 0);
        float y = atof(zmq_msg_data(&xMes));
        //Receive rotation
        zmq_msg_init(&xMes);
        zmq_msg_recv(&xMes, receiver, 0);
        float r = atof(zmq_msg_data(&xMes));
        zmq_msg_close(&xMes);
        
        dropPiece(pieceNum, x, y, r);
    //If the message is to inform the server that the client is still around
    } else if ([stringType hasPrefix:@"KeepAlive"]){
        int pieceNum = getIntFromMessage();
        //Check that the piece hasn't already been dropped.
        if (![heldPieces[pieceNum] isEqual:[NSNull null]])
            heldPieces[pieceNum] = [NSDate date];
    /*Ensure no duplicate names
    } else if ([stringType hasPrefix:@"Intro"]){
        NSString *name = messageToNSString(identity);
        int clash = 0;
        for (NSString *p in players){
            if ([name isEqualToString:p]){
                clash++;
            }
        }
        [players addObject:name];
        if (clash > 0){
            NSLog(@"Name clash");
            //sleep(3); //THERE HAS TO BE A BETTER FIX THAN THIS! TODO
            const char *num = [[[NSString alloc] initWithFormat:@"%d", clash] UTF8String];
            
            zmq_send(publisher, "Error", 5, ZMQ_SNDMORE);
            zmq_send(publisher, zmq_msg_data(&identity), zmq_msg_size(&identity), ZMQ_SNDMORE);
            zmq_send(publisher, num, sizeof(num), 0);
            name = [[NSString alloc]initWithFormat:@"%@%s", name, num];
        }
        NSLog(@"Name %@", name);
    //Otherwise we'll assume it's a chat message. */
    } else {
    }
    //NSLog(@"Held pieces: %@", heldPieces);
}

/* A method used by the server when it hasn't heard from any player
 * in a while to inform everyone that they haven't lost connection
 */
void sendAlive(){
    zmq_send(publisher, "Error", 5, 0);
}

void checkPieces(){
    for (int i = 0; i < [heldPieces count]; i++){
        id piece = heldPieces[i];
        if (! [piece isEqual:[NSNull null]]){
            NSTimeInterval interval = -1 * [piece timeIntervalSinceNow];
            if (interval > TIMEOUT){
                dropPiece(i, pieces[i].x_location, pieces[i].y_location, pieces[i].rotation);
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
        if ([date timeIntervalSinceNow] < -TIMEOUT/3){
            sendBoard();
            date = [NSDate date];
            checkPieces();
        }
        receiveMessage();
        if ([lastSent timeIntervalSinceNow] < -TIMEOUT/2)
            sendAlive();
        
    }
    
}

void readImage(NSString *path){
    NSError *errorPtr;
    NSData *image = [NSData dataWithContentsOfFile:path options:NSDataReadingUncached error:&errorPtr];
    if (errorPtr != NULL) {
        NSLog(@"Error reading file: %@", errorPtr);
        NSLog(@"Ensure an image is located at: %@", path);
    }
    imageLen = (int)[image length];
    boardState = malloc(imageLen);
    memcpy(boardState, [image bytes], imageLen);
}

int main(int argc, const char * argv[]) {
    NSLog(@"Remember to check the address");
    publishService();
    pieceNeighbours = [[PieceNeighbours alloc] init];
    simpleMath = [[SimpleMath alloc] init];
    NSString *path = [[NSMutableString alloc] initWithFormat:@"%@/puppy.png", [[NSBundle mainBundle] resourcePath]];
    readImage(path);
    players = [NSMutableArray array];
    heldPieces = [NSMutableArray array];
    generatePieces(pieces);

    for (int i = 0; i < NUM_OF_PIECES; i++){
        [heldPieces addObject:[NSNull null]];
        
    }
    startServer();
    free(boardState);
    
    return 0;
}
