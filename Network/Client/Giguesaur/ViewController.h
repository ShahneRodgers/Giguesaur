//
//  ViewController.h
//  Giguesaur
//
//  Created by Local Shahne on 4/9/15.
//  Copyright (c) 2015 Local Shahne. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChatController.h"
#import "BrowsingDelegate.h"
#import "zmq.h"
#import "PublishingDelegate.h"
#import <arpa/inet.h>
#import <sys/socket.h>

static id thisClass;

@interface ViewController : UIViewController
@property (strong, nonatomic) IBOutlet UIView *view;
@property int xLocation;

@end

