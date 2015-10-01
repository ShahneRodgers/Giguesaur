//
//  ViewController.m is the first ViewController in Giguesaur.
//  It uses BrowsingDelegate to search for a Giguesaur server.
//  When the server is found, it switches to the main GameController view.
//
//  Created by Shahne in 2015.


#import "ViewController.h"


@implementation ViewController


/* Called when the view is loaded. Sets up a BrowsingDelegate and starts searching
 * for a Giguesaur server
 */
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.xLocation = 100;
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


/* @deprecated
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
    self.delegate = NULL;
    GameController *controller = [[GameController alloc] init];
    //controller.delegate = self.delegate;
    Network *network = [[Network alloc]init];
    [network prepare:address];
   /* while(!network.hasImage){
        [network checkMessages];
    }*/
    //Should give the network the chosen client name and check this is okay.
    [controller prepare:network];
    [controller setModalPresentationStyle:UIModalPresentationFullScreen];
    [self presentViewController:controller animated:YES completion:nil];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
