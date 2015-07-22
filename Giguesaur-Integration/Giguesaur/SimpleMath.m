/*
    File: SimpleMath.h
    Author: Ashley Manson
 
    Implementation of SimpleMath.h
 */

#import "SimpleMath.h"

@implementation SimpleMath

- (NSArray*) pointsRotated: (Piece) piece {
    
    int x = piece.x_location;
    int y = piece.y_location;
    
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

- (NSArray*) distanceBetweenPiece: (Piece) originalPiece
                    andOtherPiece: (Piece) otherPiece
                        whichSide: (pieceSide) sideToCheck {
    
    NSArray *originalPieceRotated = [self pointsRotated:originalPiece];
    NSArray *otherPieceRotated = [self pointsRotated:otherPiece];
    
    CGPoint pieceTopLeft = [[originalPieceRotated objectAtIndex:0] CGPointValue];
    CGPoint pieceTopRight = [[originalPieceRotated objectAtIndex:1] CGPointValue];
    CGPoint pieceBotRight = [[originalPieceRotated objectAtIndex:2] CGPointValue];
    CGPoint pieceBotLeft = [[originalPieceRotated objectAtIndex:3] CGPointValue];
    
    float distance_1, distance_2;
    
    if (sideToCheck == P_UP) {
        CGPoint upBotLeft = [[otherPieceRotated objectAtIndex:3] CGPointValue];
        CGPoint upBotRight = [[otherPieceRotated objectAtIndex:2] CGPointValue];
        
        distance_1 =
            powf((pieceTopLeft.x - upBotLeft.x), 2) +
            powf((pieceTopLeft.y - upBotLeft.y), 2);
        
        distance_2 =
            powf((pieceTopRight.x - upBotRight.x), 2) +
            powf((pieceTopRight.y - upBotRight.y), 2);
    }
    
    else if (sideToCheck == P_DOWN) {
        CGPoint downTopLeft = [[otherPieceRotated objectAtIndex:0] CGPointValue];
        CGPoint downTopRight = [[otherPieceRotated objectAtIndex:1] CGPointValue];
        
        distance_1 =
            powf((pieceBotLeft.x - downTopLeft.x), 2) +
            powf((pieceBotLeft.y - downTopLeft.y), 2);
        
        distance_2 =
            powf((pieceBotRight.x - downTopRight.x), 2) +
            powf((pieceBotRight.y - downTopRight.y), 2);
    }
    
    else if (sideToCheck == P_LEFT) {
        CGPoint leftTopRight = [[otherPieceRotated objectAtIndex:1] CGPointValue];
        CGPoint leftBotRight = [[otherPieceRotated objectAtIndex:2] CGPointValue];
        
        distance_1 =
            powf((pieceTopLeft.x - leftTopRight.x), 2) +
            powf((pieceTopLeft.y - leftTopRight.y), 2);
        
        distance_2 =
            powf((pieceBotLeft.x - leftBotRight.x), 2) +
            powf((pieceBotLeft.y - leftBotRight.y), 2);
    }
    
    else if (sideToCheck == P_RIGHT) {
        CGPoint rightTopLeft = [[otherPieceRotated objectAtIndex:0] CGPointValue];
        CGPoint rightBotLeft = [[otherPieceRotated objectAtIndex:3] CGPointValue];
        
        distance_1 =
            powf((pieceTopRight.x - rightTopLeft.x), 2) +
            powf((pieceTopRight.y - rightTopLeft.y), 2);
        
        distance_2 =
            powf((pieceBotRight.x - rightBotLeft.x), 2) +
            powf((pieceBotRight.y - rightBotLeft.y), 2);
    }
    
    return [NSArray arrayWithObjects:
            [NSNumber numberWithFloat:distance_1],
            [NSNumber numberWithFloat:distance_2],
            nil];
}

- (BOOL) shouldPieceSnap: (Piece) originalPiece
          withOtherPiece: (Piece) otherPiece
               whichSide: (pieceSide) sideToCheck
      distanceBeforeSnap: (int) distanceToSnap {
    
    NSArray *distances = [self distanceBetweenPiece:originalPiece
                                      andOtherPiece:otherPiece
                                          whichSide:sideToCheck];
    
    return ([[distances objectAtIndex:0] floatValue] < distanceToSnap &&
            [[distances objectAtIndex:1] floatValue] < distanceToSnap);
}

- (CGPoint) newCoordinates: (Piece) neighbourPiece
                 whichSide: (pieceSide) sideOfNeighbour {
    
    float rads = degToRad(neighbourPiece.rotation);
    float adj, opp, x_new, y_new;
    
    if (sideOfNeighbour == P_UP) {
        opp = SIDE_LENGTH * sinf(rads);
        adj = SIDE_LENGTH * cosf(rads);
        x_new = neighbourPiece.x_location + opp;
        y_new = neighbourPiece.y_location - adj;
    }
    
    else if (sideOfNeighbour == P_DOWN) {
        opp = SIDE_LENGTH * sinf(rads);
        adj = SIDE_LENGTH * cosf(rads);
        x_new = neighbourPiece.x_location - opp;
        y_new = neighbourPiece.y_location + adj;
    }
    
    else if (sideOfNeighbour == P_LEFT) {
        opp = SIDE_LENGTH * cosf(rads);
        adj = SIDE_LENGTH * sinf(rads);
        x_new = neighbourPiece.x_location + opp;
        y_new = neighbourPiece.y_location + adj;
    }
    
    else if (sideOfNeighbour == P_RIGHT) {
        opp = SIDE_LENGTH * cosf(rads);
        adj = SIDE_LENGTH * sinf(rads);
        x_new = neighbourPiece.x_location - opp;
        y_new = neighbourPiece.y_location - adj;
    }
    
    return CGPointMake(x_new, y_new);
}

- (BOOL) didPieceConnect: (Piece) originalPiece
          withOtherPiece: (Piece) otherPiece
               whichSide: (pieceSide) sideToCheck {
    
    CGPoint newPoints = [self newCoordinates:otherPiece whichSide:sideToCheck];
    
    BOOL xCase = originalPiece.x_location - newPoints.x < 1 &&
    originalPiece.x_location - newPoints.x > -1;
    
    BOOL yCase = originalPiece.y_location - newPoints.y < 1 &&
    originalPiece.y_location - newPoints.y > -1;
    
    return (xCase && yCase);
}

@end
