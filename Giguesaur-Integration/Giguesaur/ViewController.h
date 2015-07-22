//
//  ViewController.h
//  Giguesaur
//
//  Created by Local Shahne on 4/9/15.
//  Copyright (c) 2015 Local Shahne. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GameController.h"
#import "BrowsingDelegate.h"
#import "Network.h"


@class BrowsingDelegate; //Weird trick to fix circular dependency issue.

@interface ViewController : UIViewController

@property int xLocation;
@property BrowsingDelegate *delegate;

-(void)addButton:(NSString*)title;

@end

