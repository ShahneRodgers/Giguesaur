//
//  ChatController.m
//  Giguesaur
//
//  Created by Local Shahne on 4/9/15.
//  Copyright (c) 2015 Local Shahne. All rights reserved.
//

#import "Network.h"

int TIMEOUT = 5;
Piece *pieces;

@implementation Network

/*
 * Sets up the ClientDelegate - this method must be called manually,
 * everything else will happen automatically.
 */
-(void)prepare:(NSString*) address{
    self.address = address;
    self.heldPiece = -1;
    self.wantedPiece = -1;
    self.hasImage = NO;
    self.timedOut = NO;
    self.name = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    self.context = zmq_ctx_new();
    [self startSendSocket:self.context];
    [self startRecvSocket:self.context];
    [self startBoardRecv:self.context];
    [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)1.0
                                     target:self
                                   selector:@selector(checkMessages)
                                   userInfo:nil
                                    repeats:YES];
    
}

/* Frees the memory */
void free_data(void* data, void* hint){
    free(data);
}

/*For testing.
- (IBAction)sendMessage:(UIButton *)sender {
    for (int i = 0; i < self.buttons.count; i++){
        //NSLog(@"%i", i);
        if ([self.buttons objectAtIndex:i] == sender){
            if (self.heldPiece == i)
                return [self droppedPiece:3000 WithY:20 WithRotation:20];
            else if (self.heldPiece != -1)
                return NSLog(@"You can only hold one piece");
            else
                return [self requestPiece:i];
        }
    }
    NSLog(@"Hello");
    const char* message = [self.messages.text UTF8String];
    int len = (int)strlen(message) + 1;
    zmq_msg_t msg;
    void *data = malloc(strlen(message));
    memcpy(data, (const void*)message, len);
    
    zmq_msg_init_data(&msg, data, len, free_data, NULL);
    
    
    zmq_msg_send(&msg, self.socket, 0);
    self.messages.text = @"";
    
    zmq_msg_close(&msg);
} */


/*Creates the socket responsible for sending data and saves it to the client. */
-(void)startSendSocket:(void *)context{
    void *socket = zmq_socket(context, ZMQ_DEALER);
    const char* ip = [[[NSString alloc] initWithFormat:@"tcp://%@:5555", self.address] UTF8String];
    char* id = (char *)[self.name UTF8String];
    zmq_setsockopt (socket, ZMQ_IDENTITY, id, strlen (id));
    zmq_connect(socket, ip);
    
    self.socket = socket;
    
}

-(void)startBoardRecv:(void *)context{
    void *socket = zmq_socket(context, ZMQ_REQ);
    const char* address = [[[NSString alloc] initWithFormat:@"tcp://%@:5557", self.address] UTF8String];
    int rc = zmq_connect(socket, address);
    if (rc == -1)
        NSLog(@"Problem connecting in board receiver");
    self.recvBoard = socket;
}

/* Creates the socket responsible for receiving messages and saves it to the client. */
-(void)startRecvSocket:(void *)context{
    void *socket = zmq_socket(context, ZMQ_SUB);
    const char* address = [[[NSString alloc] initWithFormat:@"tcp://%@:5556", self.address] UTF8String];
    int rc = zmq_connect(socket, address);
    if (rc == -1)
        NSLog(@"Problem connecting");
    //zmq_setsockopt(socket, ZMQ_SUBSCRIBE, "SetupMode", 9);
    zmq_setsockopt(socket, ZMQ_SUBSCRIBE, "PickUp", 6);
    zmq_setsockopt(socket, ZMQ_SUBSCRIBE, "Drop", 4);
    zmq_setsockopt(socket, ZMQ_SUBSCRIBE, "Error", 5);
    
    self.recvSocket = socket;

}



/*For testing.
-(void)addButton:(int)x withTitle:(NSString*)title{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button addTarget:self action:@selector(sendMessage:) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:title forState:UIControlStateNormal];
    button.frame = CGRectMake(220, x, 160, 40);
    [self.view addSubview:button];
    [self.buttons addObject:button];
}

//Displays the pieces - only for testing.
-(void)displayPieces:(int[5][3])arr withSize:(int)size{
    self.buttons = [NSMutableArray array];
    for (int i = 0; i < size; i++){
        NSString *title = [[NSString alloc]initWithFormat:@"%i: %i,%i r%i",i, arr[i][0], arr[i][1], arr[i][2]];
        [self addButton:30*i+160 withTitle:title];
    }
}
 */

/* Receives the board image and initial piece locations from the server */
-(void)setUpMode:(BOOL)withImage{
    DEBUG_SAY(1, "Network.m :: setUpMode\n");
    zmq_msg_t picture;
    zmq_msg_t numRow;
    zmq_msg_t numCol;
    zmq_msg_t pieceLocations;
    zmq_msg_t numMessages;
    
    zmq_msg_init(&picture);
    zmq_msg_init(&numRow);
    zmq_msg_init(&numCol);
    zmq_msg_init(&pieceLocations);
    zmq_msg_init(&numMessages);
    
    NSData *data;
    
    if (withImage){
        zmq_send(self.recvBoard, "a", 1, 0);
        int len = zmq_msg_recv(&picture, self.recvBoard, 0);
        //Copy the image data into NSData.
        data = [NSData dataWithBytes:zmq_msg_data(&picture) length:len];
        DEBUG_PRINT(2, "Received image: %i\n", len);
    }
    
    zmq_msg_recv(&numRow, self.recvBoard, 0);
    zmq_msg_recv(&numCol, self.recvBoard, 0);
    zmq_msg_recv(&pieceLocations, self.recvBoard, 0);
    zmq_msg_recv(&numMessages, self.recvBoard, 0);
    
    //if (!self.hasImage || self.timedOut){
        DEBUG_SAY(3, "Receive the image data from Network.m\n");
    
        
        DEBUG_SAY(3, "atoi numRow and numCol from Network.m\n");
        int row = atoi(zmq_msg_data(&numRow));
        int col = atoi(zmq_msg_data(&numCol));
        
        DEBUG_SAY(3, "malloc pieces from Network.m\n");
        pieces = malloc(sizeof(Piece)*row*col);
        memcpy(pieces, zmq_msg_data(&pieceLocations), zmq_msg_size(&pieceLocations));
    
    if (withImage){
        DEBUG_SAY(2, "Call initWithPuzzle from Network.m\n");
        [self.graphics initWithPuzzle:[UIImage imageWithData:data] withPieces:pieces andNumRows:row andNumCols:col];
    } else {
        [self.graphics updateAllPieces:pieces];
    }
    
    self.hasImage = YES;
    self.recvMessagesCount = atoi(zmq_msg_data(&numMessages));
    
    zmq_msg_close(&picture);
    zmq_msg_close(&numRow);
    zmq_msg_close(&numCol);
    zmq_msg_close(&pieceLocations);
    zmq_msg_close(&numMessages);
}

/* Converts an int into a const char * so it can be sent to the server */
-(const char*)intToString:(int)num{
    return [[[NSString alloc] initWithFormat:@"%d", num] UTF8String];
}

/* Converts a float into a const char * so it can be sent to the server */
-(const char*)floatToString:(int)num{
    return [[[NSString alloc] initWithFormat:@"%d", num] UTF8String];
}

/* Asks the server for the piece specified by the number */
-(void)requestPiece:(int)pieceNum{
    DEBUG_PRINT(3, "Network::requestPiece %d\n", pieceNum);
    const char *piece = [[[NSString alloc] initWithFormat:@"%d", pieceNum] UTF8String];
    zmq_send(self.socket, "PickUp", 6, ZMQ_SNDMORE);
    zmq_send(self.socket, piece, strlen(piece), 0);
    self.wantedPiece = pieceNum;
    self.lastRequest = [NSDate date];
}


/* Drops the piece that is being held at location (x, y) with rotation r. */
-(void)droppedPiece:(float)xNum WithY:(float)yNum WithRotation:(float)rotationNum{
    //We've already asked to drop this piece
    if (self.wantedPiece == self.heldPiece && [self.lastRequest timeIntervalSinceNow] > -TIMEOUT/2)
        return;
    const char *piece = [self intToString:self.heldPiece];
    const char *x = [self floatToString:xNum];
    const char *y = [self floatToString:yNum];
    const char *rotation = [self floatToString:rotationNum];
    
    zmq_send(self.socket, "Drop", 4, ZMQ_SNDMORE);
    zmq_send(self.socket, piece, strlen(piece), ZMQ_SNDMORE);
    zmq_send(self.socket, x, strlen(x), ZMQ_SNDMORE);
    zmq_send(self.socket, y, strlen(y), ZMQ_SNDMORE);
    zmq_send(self.socket, rotation, strlen(rotation), 0);
    
    self.wantedPiece = self.heldPiece;
    self.lastRequest = [NSDate date];
}

-(NSString *)messageToNSString:(zmq_msg_t) message{
    char charIdent[zmq_msg_size(&message)+1];
    memcpy(charIdent, zmq_msg_data(&message), sizeof(charIdent));
    charIdent[zmq_msg_size(&message)] = '\0';
    return [[NSString alloc] initWithFormat:@"%s", charIdent];
}


/* Receives a message from the server to say a piece has been picked up.*/
-(void)pickUp{
    zmq_msg_t piece;
    zmq_msg_init(&piece);
    zmq_msg_t ident;
    zmq_msg_init(&ident);
    
    zmq_msg_recv(&ident, self.recvSocket, 0);
    zmq_msg_recv(&piece, self.recvSocket, 0);
    
    NSString *identity = [self messageToNSString:ident];
    DEBUG_SAY(2, "Network.m :: pickUp\n");
    int pieceNum = atoi(zmq_msg_data(&piece));
    //UIButton *button = [self.buttons objectAtIndex:pieceNum];
    if ([identity hasPrefix:self.name]){
        self.heldPiece = pieceNum;
        //[button setTitle:@"I have this" forState:normal];
        NSLog(@"I have %i", self.heldPiece);
        [self.graphics pickupPiece:self.heldPiece];
        self.wantedPiece = -1;
    } else {
        [self.graphics addToHeld:pieceNum];
        if (pieceNum == self.wantedPiece){
            NSLog(@"%@ stole my piece!", identity);
            self.wantedPiece = -1;
        }
    }
}

/* Receives a message from the server to say that a piece has been dropped */
-(void)drop{
    zmq_msg_t piece;
    zmq_msg_t x;
    zmq_msg_t y;
    zmq_msg_t rotation;
    
    zmq_msg_init(&piece);
    zmq_msg_init(&x);
    zmq_msg_init(&y);
    zmq_msg_init(&rotation);
    
    zmq_msg_recv(&piece, self.recvSocket, 0);
    zmq_msg_recv(&x, self.recvSocket, 0);
    zmq_msg_recv(&y, self.recvSocket, 0);
    zmq_msg_recv(&rotation, self.recvSocket, 0);
    
    if (self.heldPiece == atoi(zmq_msg_data(&piece)))
        self.heldPiece = -1;
    
    /*NSString *title = [[NSString alloc]initWithFormat:@"%s: %s,%s r%s", zmq_msg_data(&piece),
                       zmq_msg_data(&x),
                       zmq_msg_data(&y),
                       zmq_msg_data(&rotation)]; */
    int pieceNum = atoi(zmq_msg_data(&piece));
    float locs[3] = {atof(zmq_msg_data(&x)), atof(zmq_msg_data(&y)), atof(zmq_msg_data(&rotation))};
   // [[self.buttons objectAtIndex:atoi(zmq_msg_data(&piece))]setTitle:title forState:normal];
    [self.graphics placePiece:pieceNum andCoords:locs];
    
    
    zmq_msg_close(&piece);
    zmq_msg_close(&x);
    zmq_msg_close(&y);
    zmq_msg_close(&rotation);
}

/* Informs the server that the client hasn't died. This is used while the client
 * is holding a piece.
 */
-(void)keepAlive{
    DEBUG_SAY(4, "Network.m :: keepAlive\n");
    const char *piece = [[[NSString alloc] initWithFormat:@"%d", self.heldPiece] UTF8String];
    zmq_send(self.socket, "KeepAlive", 9, ZMQ_SNDMORE);
    zmq_send(self.socket, piece, strlen(piece), 0);
}

/* Checks for messages from the server */
-(void)checkMessages{
    //If a piece is held and still wanted, tell the server we're still alive.
    if (self.heldPiece != -1 && self.wantedPiece == -1)
        [self keepAlive];
  
    //Initialise and receive the type of message
    zmq_msg_t type;
    zmq_msg_init(&type);
    int i = zmq_msg_recv(&type, self.recvSocket, ZMQ_DONTWAIT);
    //If no message type was received, return
    if (i <= 0){
        //Lost server connection
        if ([self.lastHeard timeIntervalSinceNow]*-1 > TIMEOUT){
            zmq_setsockopt(self.recvSocket, ZMQ_SUBSCRIBE, "SetupMode", 9);
            self.timedOut = YES;
            self.heldPiece = -1;
            self.wantedPiece = -1;
        }
        return;
    }
    self.recvMessagesCount++;
    self.lastHeard = [NSDate date];
    //Turn the type into a NSString.
    NSString *stringType = [[NSString alloc] initWithFormat:@"%s", zmq_msg_data(&type)];
    //If a piece has been picked up.
    if ([stringType hasPrefix:@"PickUp"]){
        [self pickUp];
    //If a piece has been dropped
    } else if ([stringType hasPrefix:@"Drop"]){
        [self drop];
    } else if ([stringType hasPrefix:@"Error"]){
        zmq_msg_recv(&type, self.recvSocket, 0); //This message contains the count of messages since last heard.
        if ((atoi(zmq_msg_data(&type))) != self.recvMessagesCount){
            DEBUG_SAY(2, "Error message received\n");
            [self setUpMode:NO];
        }
        self.recvMessagesCount = 0;
    } else {
        //NSLog(@"%@", stringType);
    }
    zmq_msg_close(&type);
    
    /*If a piece has been requested but we haven't had a response within TIMEOUT
    int time = [self.lastRequest timeIntervalSinceNow] *-1;
    if (self.wantedPiece != -1 && self.heldPiece == -1 && time > TIMEOUT){
        [self requestPiece:self.wantedPiece];
    }
     */
    
}


@end
