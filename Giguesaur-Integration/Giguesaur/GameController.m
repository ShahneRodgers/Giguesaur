//
//  GameController.m
//  Giguesaur
//
//  Created by Local Joshua La Pine on 7/21/15.
//  Copyright (c) 2015 Giguesaur Team. All rights reserved.
//

#import "GameController.h"

@implementation GameController

/*
 * Stores the set-up Network
 */
-(void)prepare:(Network *)network and:(Vision *) vision{
    self.network = network;
    self.vision = vision;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self.vision.session startRunning];
    // Do any additional setup after loading the view, typically from a nib.
   
}


@end
