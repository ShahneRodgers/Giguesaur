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

@class BrowsingDelegate; //Weird trick to fix circular dependency issue.

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *name;
@property int xLocation;
@property BrowsingDelegate *delegate;
//@property Vision *vision;
@property Graphics *graphics;
@property int anon;

-(void)addButton:(NSString*)title;

@end

