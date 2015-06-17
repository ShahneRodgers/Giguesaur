//
//  ConnectionManager.m
//  Giguesaur
//
//  Created by Local Shahne on 3/29/15.
//  Copyright (c) 2015 Local Shahne. All rights reserved.
//

#import "ConnectionManager.h"

@implementation ConnectionManager

-(id)init{
    self = [super init];
    
    if (self) {
        _peerID = nil;
        _session = nil;
        _browser = nil;
        _advertiser = nil;
    }
    
    return self;
}

-(void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state{
    NSDictionary *dict = @{@"peerID": peerID,
                           @"state" : [NSNumber numberWithInt:state]
                           };
    
    NSLog(@"Hello");
}

-(void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID{
    NSDictionary *dict = @{@"data": data,
                           @"peerID": peerID
                           };
    
    NSLog(@"Received data");
}


-(void)setupPeerAndSessionWithDisplayName:(NSString *)displayName{
    self.peerID = [[MCPeerID alloc] initWithDisplayName:displayName];
    self.session = [[MCSession alloc] initWithPeer:self.peerID];
    self.session.delegate = self;
}



-(void)setupMCBrowser{
    self.browser = [[MCBrowserViewController alloc] initWithServiceType:@"Giguesaur" session:self.session];
}

-(void)advertiseSelf:(BOOL)shouldAdvertise{
    if (shouldAdvertise){
        self.advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.peerID discoveryInfo:nil serviceType:@"Giguesaur"];
        //initWithServiceType:@"Giguesaur" discoveryInfo:nil session:self.session];
    } else {
        //[self.advertiser stop];
        self.advertiser = nil;
    }
}


@end
