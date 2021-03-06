//
//  GameController.h
//  Giguesaur
//
//  Created by Local Joshua La Pine on 7/21/15.
//  Copyright (c) 2015 Giguesaur Team. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Network.h"
#import "Vision.h"
#import "Graphics.h"

@interface GameController : UIViewController

@property Network* network;
@property Vision* vision;
@property Graphics* graphics;

//-(void)prepare:(Network *)network and:(Vision *) vision;
-(void)prepare:(Network *)network;

@end
