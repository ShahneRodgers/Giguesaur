//
//  ChatController.m
//  Giguesaur
//
//  Created by Local Shahne on 4/9/15.
//  Copyright (c) 2015 Local Shahne. All rights reserved.
//

#import "ChatController.h"

@implementation ChatController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.heldPiece = -1;
    self.wantedPiece = -1;
    void *context = zmq_ctx_new();
    [self startSendSocket:context];
    [self startRecvSocket:context];
    [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)1
                                     target:self
                                   selector:@selector(checkMessages)
                                   userInfo:nil
                                    repeats:YES];
}

void free_data(void* data, void* hint){
    free(data);
}

- (IBAction)sendMessage:(UIButton *)sender {
    for (int i = 0; i < self.buttons.count; i++){
        NSLog(@"%i", i);
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
}


/*Creates a socket and returns it in a pollitem */
-(void)startSendSocket:(void *)context{
    
    void *socket = zmq_socket(context, ZMQ_DEALER);
    self.name = [UIDevice currentDevice].name;
    const char* ip = [[[NSString alloc] initWithFormat:@"tcp://%@:5555", self.address] UTF8String];
    const char* id = [self.name UTF8String];
    zmq_setsockopt (socket, ZMQ_IDENTITY, id, strlen (id));
    zmq_connect(socket, ip);
    
    self.socket = socket;
    
}

-(void)startRecvSocket:(void *)context{
    void *socket = zmq_socket(context, ZMQ_SUB);
    const char* address = [[[NSString alloc] initWithFormat:@"tcp://%@:5556", self.address] UTF8String];
    int rc = zmq_connect(socket, address);
    if (rc == -1)
        NSLog(@"Problem connecting");
    zmq_setsockopt(socket, ZMQ_SUBSCRIBE, "SetupMode", 9);
    zmq_setsockopt(socket, ZMQ_SUBSCRIBE, "ChatMode", 8);
    zmq_setsockopt(socket, ZMQ_SUBSCRIBE, "PickUp", 6);
    zmq_setsockopt(socket, ZMQ_SUBSCRIBE, "Drop", 4);
    
    self.recvSocket = socket;
}

-(void)addButton:(int)x withTitle:(NSString*)title{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button addTarget:self action:@selector(sendMessage:) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:title forState:UIControlStateNormal];
    button.frame = CGRectMake(220, x, 160, 40);
    [self.view addSubview:button];
    [self.buttons addObject:button];
}

-(void)displayPieces:(int[100][3])arr withSize:(int)size{
    self.buttons = [NSMutableArray array];
    for (int i = 0; i < size; i++){
        NSString *title = [[NSString alloc]initWithFormat:@"%i: %i,%i r%i",i, arr[i][0], arr[i][1], arr[i][2]];
        [self addButton:30*i+160 withTitle:title];
    }
}

-(void)setUpMode{
    zmq_msg_t picture;
    zmq_msg_init(&picture);
    zmq_msg_t numPieces;
    zmq_msg_init(&numPieces);
    zmq_msg_t pieceLocations;
    zmq_msg_init(&pieceLocations);

    //Receive the image data.
    int len = zmq_msg_recv(&picture, self.recvSocket, 0);
    NSData *data = [NSData dataWithBytes:zmq_msg_data(&picture) length:len];
    
    zmq_msg_recv(&numPieces, self.recvSocket, 0);
    //Display the image so that we can see it's working.
    self.imageView.image = [UIImage imageWithData:data];
    
    zmq_msg_recv(&pieceLocations, self.recvSocket, 0);
    int pieces[atoi(zmq_msg_data(&numPieces))][3];
    memcpy(&pieces, zmq_msg_data(&pieceLocations), zmq_msg_size(&pieceLocations));
    
    [self displayPieces:pieces withSize:atoi(zmq_msg_data(&numPieces))];
    
    //Unsubscribe from board initialisation messages.
    zmq_setsockopt(self.recvSocket, ZMQ_UNSUBSCRIBE, "SetupMode", 9);
}

-(const char*)intToString:(int)num{
    return [[[NSString alloc] initWithFormat:@"%d", num] UTF8String];
}

-(void)requestPiece:(int)pieceNum{
    const char *piece = [[[NSString alloc] initWithFormat:@"%d", pieceNum] UTF8String];
    zmq_send(self.socket, "PickUp", 6, ZMQ_SNDMORE);
    zmq_send(self.socket, piece, pieceNum%10+1, 0);
    self.wantedPiece = pieceNum;
}



-(void)droppedPiece:(int)xNum WithY:(int)yNum WithRotation:(int)rotationNum{
    const char *piece = [self intToString:self.heldPiece];
    const char *x = [self intToString:xNum];
    const char *y = [self intToString:yNum];
    const char *rotation = [self intToString:rotationNum];

    zmq_send(self.socket, "Drop", 4, ZMQ_SNDMORE);
    zmq_send(self.socket, piece, sizeof(piece), ZMQ_SNDMORE);
    zmq_send(self.socket, x, sizeof(x), ZMQ_SNDMORE);
    zmq_send(self.socket, y, sizeof(y), ZMQ_SNDMORE);
    zmq_send(self.socket, rotation, sizeof(rotation), 0);
    self.heldPiece = -1;
}

-(void)pickUp{
    zmq_msg_t piece;
    zmq_msg_init(&piece);
    zmq_msg_t ident;
    zmq_msg_init(&ident);
    
    zmq_msg_recv(&ident, self.recvSocket, 0);
    zmq_msg_recv(&piece, self.recvSocket, 0);
    
    NSString *identity = [[NSString alloc] initWithFormat:@"%s", zmq_msg_data(&ident)];
    int pieceNum = atoi(zmq_msg_data(&piece));
    UIButton *button = [self.buttons objectAtIndex:pieceNum];
    if ([identity hasPrefix:self.name]){
        self.heldPiece = pieceNum;
        [button setTitle:@"I have this" forState:normal];
        NSLog(@"I have %i", self.heldPiece);
        self.wantedPiece = -1;
    } else {
        if (pieceNum == self.wantedPiece){
            NSString *title = [[NSString alloc]initWithFormat:@"%@ has stolen this piece!",identity];
            [button setTitle:title forState:normal];
            self.wantedPiece = -1;
        } else {
            NSString *title = [[NSString alloc]initWithFormat:@"%@ has this", identity];
            [button setTitle:title forState:normal];
        }
    }
}

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
    
    NSString *title = [[NSString alloc]initWithFormat:@"%s: %s,%s r%s", zmq_msg_data(&piece),
          zmq_msg_data(&x),
          zmq_msg_data(&y),
          zmq_msg_data(&rotation)];
    [[self.buttons objectAtIndex:atoi(zmq_msg_data(&piece))]setTitle:title forState:normal];
          
          
    zmq_msg_close(&piece);
    zmq_msg_close(&x);
    zmq_msg_close(&y);
    zmq_msg_close(&rotation);
}

-(void)keepAlive{
    const char *piece = [[[NSString alloc] initWithFormat:@"%d", self.heldPiece] UTF8String];
    zmq_send(self.socket, "KeepAlive", 9, ZMQ_SNDMORE);
    zmq_send(self.socket, piece, sizeof(piece), 0);
}

-(void)checkMessages{
    //If a piece is held, tell the server we're still alive.
    if (self.heldPiece != -1)
        [self keepAlive];
    
    //Initialise and receive the type of message
    zmq_msg_t type;
    zmq_msg_init(&type);
    int i = zmq_msg_recv(&type, self.recvSocket, ZMQ_DONTWAIT);
    //If no message type was received, return
    if (i <= 0){
        return;
    }
    
    //Turn the type into a NSString.
    NSString *stringType = [[NSString alloc] initWithFormat:@"%s", zmq_msg_data(&type)];
    //The board's game state has been received
    if ([stringType hasPrefix:@"SetupMode"]){
        [self setUpMode];
        return;
    //If a piece has been picked up.
    } else if ([stringType hasPrefix:@"PickUp"]){
        [self pickUp];
    //If a piece has been dropped
    } else if ([stringType hasPrefix:@"Drop"]){
        [self drop];
    //Otherwise chat mode!
    } else if ([stringType hasPrefix:@"ChatMode"]){
        NSLog(@"Chat: %@", stringType);
        zmq_msg_t identity;
        zmq_msg_init(&identity);
        zmq_msg_t msg;
        zmq_msg_init(&msg);
        int len = zmq_msg_recv(&identity, self.recvSocket, ZMQ_DONTWAIT);
        zmq_msg_recv(&msg, self.recvSocket, ZMQ_DONTWAIT);
        if (len > 0){
            NSString *newLog = [[NSString alloc] initWithFormat:@"%s said: %s\n%@", zmq_msg_data(&identity), zmq_msg_data(&msg), self.chatLog.text];
            self.chatLog.text = newLog;
        }
        zmq_msg_close(&msg);
        zmq_msg_close(&identity);
    } else {
        //NSLog(@"%@", stringType);
    }
    zmq_msg_close(&type);
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
