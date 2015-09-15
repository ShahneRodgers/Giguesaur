//
//  BrowsingDelegate.m
//  Giguesaur
//
//  Created by Local Joshua La Pine on 7/21/15.
//  Copyright (c) 2015 Giguesaur Team. All rights reserved.
//


#import "BrowsingDelegate.h"

@implementation BrowsingDelegate

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
    else if (result->sin_family != AF_INET)
        NSLog(@"Error: only IPv6 found");
    else {
        //[viewClass addButton:[[NSString alloc]initWithFormat:@"%s", string]];
        [viewClass switchViews:[[NSString alloc]initWithFormat:@"%s", string]];
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
-(void) searchForService:(ViewController*)view{
    viewClass = view;
    if (!MyStartBrowsingForServices(CFSTR("_zeromq._tcp"), CFSTR("")))
        NSLog(@"Error");
}


@end
