//
//  ChatController.h
//  Giguesaur
//
//  Created by Local Shahne on 4/9/15.
//  Copyright (c) 2015 Local Shahne. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "zmq.h"

@interface ChatController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *messages;
@property (strong, nonatomic) IBOutlet UIView *messageLog;
@property (weak, nonatomic) IBOutlet UITextView *chatLog;

@property (nonatomic) void* socket;
@property (nonatomic) void* recvSocket;
@property (nonatomic) NSString *address;
@property (nonatomic) int heldPiece;
@property (nonatomic) NSString *name;
@property (nonatomic) int wantedPiece;
@property (nonatomic) NSDate *date;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic) NSMutableArray *buttons;

-(void)setAddress:(NSString *) address;
@end
