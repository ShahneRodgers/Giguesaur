/*
    File: Puzzle.h
    Author: Ashley Manson
 
    Defines what a puzzle is, and declares some methods to operate on the puzzle.
 */

#include "Piece.h"

#ifndef Giguesaur_Puzzle_h
#define Giguesaur_Puzzle_h

#define BOARD_WIDTH 1024
#define BOARD_HEIGHT 768

#define NUM_OF_ROWS 2
#define NUM_OF_COLS 2
#define NUM_OF_PIECES (NUM_OF_ROWS*NUM_OF_COLS)

#define DISTANCE_BEFORE_SNAP 500
#define NO_NEIGHBOUR -1

// Generate each piece of the puzzle
void generatePieces(Piece *pieces);

// Return 1 if the puzzle has been solved, 0 if not
int checkIfSolved(Piece *pieces);

// Resets the edges of pieces and their neighbours
void resetEdgesOfPiece(int pieceID, Piece *pieces);

// Moves any piece that is outside of the board
void moveIfOutOfBounds(Piece *pieces);

#endif
