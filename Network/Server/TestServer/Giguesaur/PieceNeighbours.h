/*
 File: PieceNeighbours.h
 Author: Ashley Manson
 
 Methods to open/close pieces edges and snap them to their neightbours.
*/

#import <Foundation/Foundation.h>
#import "Puzzle.h"
#import "SimpleMath.h"

@interface PieceNeighbours : NSObject

// Checks to see if a piece should snap to another piece, if YES then the piece
// x,y coordinates are change to snap to its neighbour.
- (void) checkThenSnapPiece: (int) pieceID
                  andPieces: (Piece *) pieces;

// Checks to see if a piece has snapped to its neighbours, if YES then the piece
// edges are set to closed
- (void) checkThenCloseEdge: (int) pieceID
                  andPieces: (Piece *) pieces;

@end