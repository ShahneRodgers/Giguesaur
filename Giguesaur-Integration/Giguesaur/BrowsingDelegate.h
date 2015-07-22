//
//  BrowsingDelegate.h
//  Giguesaur
//
//  Created by Local Joshua La Pine on 7/21/15.
//  Copyright (c) 2015 Giguesaur Team. All rights reserved.
//

#import <arpa/inet.h>
#import <sys/socket.h>
#import <Foundation/Foundation.h>
#import "ViewController.h"

static id viewClass;

@interface BrowsingDelegate : NSObject

-(void) searchForService:(UIViewController *)view;

@end


