//
//  ConnectionManager.h
//  Giguesaur
//
//  Created by Local Shahne on 3/29/15.
//  Copyright (c) 2015 Local Shahne. All rights reserved.
//

#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface ConnectionManager : NSObject <MCSessionDelegate>{}

@property (strong, nonatomic) MCNearbyServiceAdvertiser *advertiser;
@property (strong, nonatomic) MCPeerID *peerID;
@property (strong, nonatomic) MCSession *session;
@property (strong, nonatomic) MCBrowserViewController *browser;

-(void)setupPeerAndSessionWithDisplayName:(NSString *)displayName;
-(void)setupMCBrowser;
-(void)advertiseSelf:(BOOL)shouldAdvertise;

@end

