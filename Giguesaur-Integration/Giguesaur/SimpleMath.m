/*
    File: SimpleMath.h
    Author: Ashley Manson
 
    Implementation of SimpleMath.h
 */

#import "SimpleMath.h"

@implementation SimpleMath

- (NSArray*) pointsRotated: (Piece) piece {
    
    float x = piece.x_location;
    float y = piece.y_location;
    
    float theta = degToRad(piece.rotation);
    
    // Top Left, index 0
    float xa = x - SIDE_HALF;
    float ya = y + SIDE_HALF;
    float xa_new = cosf(theta) * (xa - x) - sinf(theta) * (ya - y) + x;
    float ya_new = sinf(theta) * (xa - x) + cosf(theta) * (ya - y) + y;
    
    // Top Right, index 1
    float xb = x + SIDE_HALF;
    float yb = y + SIDE_HALF;
    float xb_new = cosf(theta) * (xb - x) - sinf(theta) * (yb - y) + x;
    float yb_new = sinf(theta) * (xb - x) + cosf(theta) * (yb - y) + y;
    
    // Bot Right, index 2
    float xc = x + SIDE_HALF;
    float yc = y - SIDE_HALF;
    float xc_new = cosf(theta) * (xc - x) - sinf(theta) * (yc - y) + x;
    float yc_new = sinf(theta) * (xc - x) + cosf(theta) * (yc - y) + y;
    
    // Bot Left, index 3
    float xd = x - SIDE_HALF;
    float yd = y - SIDE_HALF;
    float xd_new = cosf(theta) * (xd - x) - sinf(theta) * (yd - y) + x;
    float yd_new = sinf(theta) * (xd - x) + cosf(theta) * (yd - y) + y;
    
    return [NSArray arrayWithObjects:
            [NSValue valueWithCGPoint:CGPointMake(xa_new, ya_new)],
            [NSValue valueWithCGPoint:CGPointMake(xb_new, yb_new)],
            [NSValue valueWithCGPoint:CGPointMake(xc_new, yc_new)],
            [NSValue valueWithCGPoint:CGPointMake(xd_new, yd_new)],
            nil];
}

@end
