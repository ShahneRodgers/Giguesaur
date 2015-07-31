/*
 File: PieceNeighbours.m
 Author: Ashley Manson

 Implementation of PieceNeighbours.h
 */

#import "PieceNeighbours.h"

@implementation PieceNeighbours

// Move a piece if it is in range to snap to another piece
- (void) checkThenSnapPiece: (int) pieceID
                  andPieces: (Piece *) pieces {

    SimpleMath *simpleMath = [[SimpleMath alloc] init];

    CGPoint newPoints;
    int upID = pieces[pieceID].neighbourPiece.up_piece;
    int downID = pieces[pieceID].neighbourPiece.down_piece;
    int leftID = pieces[pieceID].neighbourPiece.left_piece;
    int rightID = pieces[pieceID].neighbourPiece.right_piece;

    if (upID >= 0 &&
        [simpleMath shouldPieceSnap:pieces[pieceID]
                     withOtherPiece:pieces[upID]
                          whichSide:P_UP
                 distanceBeforeSnap:DISTANCE_BEFORE_SNAP]) {

            newPoints = [simpleMath newCoordinates:pieces[upID] whichSide:P_UP];
            pieces[pieceID].x_location = newPoints.x;
            pieces[pieceID].y_location = newPoints.y;
            pieces[pieceID].rotation = pieces[upID].rotation;
        }

    if (downID >= 0 &&
        [simpleMath shouldPieceSnap:pieces[pieceID]
                     withOtherPiece:pieces[downID]
                          whichSide:P_DOWN
                 distanceBeforeSnap:DISTANCE_BEFORE_SNAP]) {

            newPoints = [simpleMath newCoordinates:pieces[downID] whichSide:P_DOWN];
            pieces[pieceID].x_location = newPoints.x;
            pieces[pieceID].y_location = newPoints.y;
            pieces[pieceID].rotation = pieces[downID].rotation;
        }

    if (leftID >= 0 &&
        [simpleMath shouldPieceSnap:pieces[pieceID]
                     withOtherPiece:pieces[leftID]
                          whichSide:P_LEFT
                 distanceBeforeSnap:DISTANCE_BEFORE_SNAP]) {

            newPoints = [simpleMath newCoordinates:pieces[leftID] whichSide:P_LEFT];
            pieces[pieceID].x_location = newPoints.x;
            pieces[pieceID].y_location = newPoints.y;
            pieces[pieceID].rotation = pieces[leftID].rotation;
        }

    if (rightID >= 0 &&
        [simpleMath shouldPieceSnap:pieces[pieceID]
                     withOtherPiece:pieces[rightID]
                          whichSide:P_RIGHT
                 distanceBeforeSnap:DISTANCE_BEFORE_SNAP]) {

            newPoints = [simpleMath newCoordinates:pieces[rightID] whichSide: P_RIGHT];
            pieces[pieceID].x_location = newPoints.x;
            pieces[pieceID].y_location = newPoints.y;
            pieces[pieceID].rotation = pieces[rightID].rotation;
        }
}

// Check if a piece joined its neighbours then closes their edges
- (void) checkThenCloseEdge: (int) pieceID
                  andPieces: (Piece *) pieces {

    SimpleMath *simpleMath = [[SimpleMath alloc] init];

    int upID = pieces[pieceID].neighbourPiece.up_piece;
    int downID = pieces[pieceID].neighbourPiece.down_piece;
    int leftID = pieces[pieceID].neighbourPiece.left_piece;
    int rightID = pieces[pieceID].neighbourPiece.right_piece;

    if (upID >= 0 &&
        [simpleMath didPieceConnect:pieces[pieceID]
                     withOtherPiece:pieces[upID]
                          whichSide:P_UP]) {

            pieces[pieceID].openEdge.up_open = isClosed;
            pieces[upID].openEdge.down_open = isClosed;
        }

    if (downID >= 0 &&
        [simpleMath didPieceConnect:pieces[pieceID]
                     withOtherPiece:pieces[downID]
                          whichSide:P_DOWN]) {

            pieces[pieceID].openEdge.down_open = isClosed;
            pieces[downID].openEdge.up_open = isClosed;
        }

    if (leftID >= 0 &&
        [simpleMath didPieceConnect:pieces[pieceID]
                     withOtherPiece:pieces[leftID]
                          whichSide:P_LEFT]) {

            pieces[pieceID].openEdge.left_open = isClosed;
            pieces[leftID].openEdge.right_open = isClosed;
        }

    if (rightID >= 0 &&
        [simpleMath didPieceConnect:pieces[pieceID]
                     withOtherPiece:pieces[rightID]
                          whichSide:P_RIGHT]) {

            pieces[pieceID].openEdge.right_open = isClosed;
            pieces[rightID].openEdge.left_open = isClosed;
        }
}

@end
