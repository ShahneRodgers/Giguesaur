//
//  ViewController.m
//  Giguesaur
//
//  Created by Local Shahne on 4/9/15.
//  Copyright (c) 2015 Local Shahne. All rights reserved.
//

#import "ViewController.h"


@implementation ViewController


/* Called when the view is loaded. Sets up a BrowsingDelegate and starts searching
 * for a Giguesaur server
 */
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.xLocation = 100;
    self.anon = 0;
    self.delegate = [[BrowsingDelegate alloc]init];
    [self.delegate searchForService:self];
   // self.vision = [[Vision alloc]init];
    //[self.vision visionInit];
    //self.graphics = [[Graphics alloc] init];
}


/* 
 Start a client and connect to the server given by the sender.
 */
- (IBAction)joinGame:(UIButton *)sender {
    NSString *address = sender.titleLabel.text;
    if ([address isEqualToString:@"Localhost"])
        address = @"169.254.41.16";
    NSLog(@"Joining: %@", address);
    [self switchViews:address];
}


/* 
 * Adds a button to the screen with the given title.
 */
-(void)addButton:(NSString*)title{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button addTarget:self action:@selector(joinGame:) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:title forState:UIControlStateNormal];
    button.frame = CGRectMake(220, self.xLocation, 160, 40);
    self.xLocation += 40;
    [self.view addSubview:button];
}

/*
 * Sets up an instance of the network and passes this to the main game loop.
 */
-(void)switchViews:(NSString *)address{
    /*
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    GameController *controller = [storyboard instantiateViewControllerWithIdentifier:@"GameController"];
     */
    GameController *controller = [[GameController alloc] init];
    //controller.delegate = self.delegate;
    Network *network = [[Network alloc]init];
    NSString *name = self.name.text;
    if (name.length < 3){
        NSLog(@"Please enter a proper name");
        name = [[NSString alloc]initWithFormat:@"Anonymous%i", self.anon];
        self.anon += 1;
    }
    [network prepare:address called:name];
    //Should give the network the chosen client name and check this is okay.
    //[controller prepare:network and:self.vision];
    [controller prepare:network];
    [controller setModalPresentationStyle:UIModalPresentationFullScreen];
    [self presentViewController:controller animated:YES completion:nil];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
