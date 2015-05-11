//
//  PublishingDelegate.h
//  TestServer
//
//  Created by Local Shahne on 3/26/15.
//  Copyright (c) 2015 Shahne Rodgers. All rights reserved.
//

#ifndef TestServer_PublishingDelegate_h
#define TestServer_PublishingDelegate_h

#import <Foundation/Foundation.h>

@interface PublishingDelegate : NSObject <NSNetServiceDelegate>{
}


-(void)netServiceWillPublish:(NSNetService *)sender;
-(void)netServiceDidPublish:(NSNetService *)sender;
-(void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict;
-(void)netServiceDidStop:(NSNetService *)sender;
-(void)netServiceDidResolveAddress:(NSNetService *)sender;
@end

#endif
