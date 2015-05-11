//
//  ViewController.m
//  Giguesaur
//
//  Created by Local Shahne on 4/9/15.
//  Copyright (c) 2015 Local Shahne. All rights reserved.
//

#import "ViewController.h"


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    thisClass = self;
    self.xLocation = 70;
    [self searchForService];
}

/* 
 Start a client and connect to the server given by the sender.
 */
- (IBAction)joinGame:(UIButton *)sender {
    NSString *address = sender.titleLabel.text;
    if ([address isEqualToString:@"Localhost"])
        address = @"10.249.157.221";
    NSLog(@"Joining: %@", address);
    [self switchViews:address];
}


void MyBrowseCallBack (CFNetServiceBrowserRef browser,
                       CFOptionFlags flags,
                       CFTypeRef domainOrService,
                       CFStreamError* error,
                       void* info){
    if (error->error != 0){
        NSLog(@"Error browsing: %s", strerror(error->error));
        return;
    } else {
        CFNetServiceRef result = (CFNetServiceRef)domainOrService;
        if (!CFNetServiceResolveWithTimeout(result, 0, error))
            NSLog(@"Error resolving: %s", strerror(error->error));
        else
            MyResolveCallback(result, error, NULL);
    }
    
}

-(void)addButton:(NSString*)title{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button addTarget:self action:@selector(joinGame:) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:title forState:UIControlStateNormal];
    button.frame = CGRectMake(220, self.xLocation, 160, 40);
    self.xLocation += 40;
    [self.view addSubview:button];
}

void MyResolveCallback (
                        CFNetServiceRef theService,
                        CFStreamError* error,
                        void* info)
{
    CFArrayRef ip = CFNetServiceGetAddressing(theService);
    if (CFArrayGetCount(ip) == 0){
        NSLog(@"Error: no addresses found");
        return;
    }
    int index = 0;
    char string[256];
    struct sockaddr_in *result;
    do {
        const void *data = CFArrayGetValueAtIndex(ip, index);
        result = (struct sockaddr_in *)CFDataGetBytePtr(data);
        index += 1;
    } while (index < CFArrayGetCount(ip) && result->sin_family != AF_INET);
    if (!inet_ntop(result->sin_family, &result->sin_addr, string, sizeof(string)))
        NSLog(@"Error: %s", strerror(errno));
    else {
        [thisClass addButton:[[NSString alloc]initWithFormat:@"%s", string]];
    }
}


static Boolean MyStartBrowsingForServices(CFStringRef type, CFStringRef domain) {
    CFNetServiceClientContext clientContext = { 0, NULL, NULL, NULL, NULL };
    CFStreamError error;
    Boolean result;
    
    assert(type != NULL);
    
    CFNetServiceBrowserRef gServiceBrowserRef = CFNetServiceBrowserCreate(kCFAllocatorDefault, MyBrowseCallBack, &clientContext);
    assert(gServiceBrowserRef != NULL);
    
    CFNetServiceBrowserScheduleWithRunLoop(gServiceBrowserRef, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    
    result = CFNetServiceBrowserSearchForServices(gServiceBrowserRef, domain, type, &error);
    if (result == false) {
        
        // Something went wrong, so let's clean up.
        CFNetServiceBrowserUnscheduleFromRunLoop(gServiceBrowserRef, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);         CFRelease(gServiceBrowserRef);
        gServiceBrowserRef = NULL;
        
        fprintf(stderr, "CFNetServiceBrowserSearchForServices returned (domain = %d, error = %d)\n", (int)error.domain, (int)error.error);
    }
    
    return result;
}

/*
 * Looks for a giguesaur game which is already running.
 */
-(void) searchForService{
    if (!MyStartBrowsingForServices(CFSTR("_zeromq._tcp"), CFSTR("")))
        NSLog(@"Error");
}



/*Switches to the chat interface */
-(void)switchViews:(NSString *)address{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ChatController *controller = [storyboard instantiateViewControllerWithIdentifier:@"ChatController"];
    controller.address = address;
    [controller setModalPresentationStyle:UIModalPresentationFullScreen];
    [self presentViewController:controller animated:YES completion:nil];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
