//
//  PublishingDelegate.m
//  TestServer
//
//  Created by Local Shahne on 3/26/15.
//  Copyright (c) 2015 Shahne Rodgers. All rights reserved.
//

#import "PublishingDelegate.h"

@implementation PublishingDelegate 

//Sent when publishing begins
-(void)netServiceWillPublish:(NSNetService *)sender{
    NSLog(@"Publishing has started");
}

-(void)netServiceDidPublish:(NSNetService *)sender{
    NSLog(@"Publishing is finished");
}


-(void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict{
    NSLog(@"The server did not publish. Error code = %@", errorDict);
}

-(void)netServiceDidStop:(NSNetService *)sender{
    NSLog(@"The server stopped publishing");
}

-(void)netServiceDidResolveAddress:(NSNetService *)sender{
    NSLog(@"The server resolved address");
}

@end
