//
//  BrowsingDelegate.h
//  testclient
//
//  Created by Local Shahne on 3/26/15.
//  Copyright (c) 2015 Local Shahne. All rights reserved.
//

#ifndef testclient_BrowsingDelegate_h
#define testclient_BrowsingDelegate_h

#import <Foundation/Foundation.h>

@interface BrowsingDelegate : NSObject <NSNetServiceBrowserDelegate>
{
}

// Other methods
- (void)handleError:(NSNumber *)error;
- (void)updateUI;

@end

#endif
