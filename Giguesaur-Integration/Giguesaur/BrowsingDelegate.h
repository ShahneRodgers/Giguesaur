//
//  BrowsingDelegate.h
//  Giguesaur
//
//  Created by Shahne Rodgers in 2015.
//

#import <arpa/inet.h>
#import <sys/socket.h>
#import <Foundation/Foundation.h>
#import "ViewController.h"

static id viewClass; //holds a reference to the view controller so that it can switch views when the server is found.

@interface BrowsingDelegate : NSObject

-(void) searchForService:(UIViewController *)view;

@end


