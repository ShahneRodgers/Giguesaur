/*
    File: Puzzle.c
    Author: Ashley Manson
 
    Mainly generates the puzzle.
 */

#include <stdlib.h>
#include "Puzzle.h"

// Generate all the pieces of the puzzle
void generatePieces(Piece *pieces) {
    
    for (int i = 0; i < NUM_OF_PIECES; i++) {
        Piece piece = {
            .piece_id = i,
            .x_location = rand()%BOARD_WIDTH,
            .y_location = rand()%BOARD_HEIGHT,
            .rotation = rand()%360,
            .held = P_FALSE
        };
        pieces[i] = piece;
    }
    
    // Make connections, a neighbour is defined by the index of the array
    int index = 0;
    for (int row = 0; row < NUM_OF_ROWS; row++) {
        for (int col = 0; col < NUM_OF_COLS; col++) {
            
            // Up Neighbour Piece
            if (row == 0) pieces[index].neighbourPiece.up_piece = NO_NEIGHBOUR;
            else pieces[index].neighbourPiece.up_piece = index - NUM_OF_COLS;
            
            // Down Neighbour Piece
            if (row + 1 == NUM_OF_ROWS) pieces[index].neighbourPiece.down_piece = NO_NEIGHBOUR;
            else pieces[index].neighbourPiece.down_piece = index + NUM_OF_COLS;
            
            // Left Neighbour Piece
            if (col == 0) pieces[index].neighbourPiece.left_piece = NO_NEIGHBOUR;
            else pieces[index].neighbourPiece.left_piece = index - 1;
            
            // Right Neighbour Piece
            if (col + 1 == NUM_OF_COLS) pieces[index].neighbourPiece.right_piece = NO_NEIGHBOUR;
            else pieces[index].neighbourPiece.right_piece = index + 1;
            
            index++;
        }
    }
    
    for (int i = 0; i < NUM_OF_PIECES; i++) {
        ACCESSIBLE_EDGE up = isClosed;
        ACCESSIBLE_EDGE down = isClosed;
        ACCESSIBLE_EDGE left = isClosed;
        ACCESSIBLE_EDGE right = isClosed;
        
        if (pieces[i].neighbourPiece.up_piece >= 0) up = isOpen;
        else up = invalid;
        
        if (pieces[i].neighbourPiece.down_piece >= 0) down = isOpen;
        else down = invalid;
        
        if (pieces[i].neighbourPiece.left_piece >= 0) left = isOpen;
        else left = invalid;
        
        if (pieces[i].neighbourPiece.right_piece >= 0) right = isOpen;
        else right = invalid;
        
        pieces[i].openEdge.up_open = up;
        pieces[i].openEdge.down_open = down;
        pieces[i].openEdge.left_open = left;
        pieces[i].openEdge.right_open = right;
    }

    moveIfOutOfBounds(pieces);
}

// Check if the puzzle has been solved
int checkIfSolved(Piece *pieces) {
    
    for (int i = 0; i < NUM_OF_PIECES; i++) {
        if (pieces[i].openEdge.up_open == isOpen ||
            pieces[i].openEdge.down_open == isOpen ||
            pieces[i].openEdge.left_open == isOpen ||
            pieces[i].openEdge.right_open == isOpen) {
            
            return 0;
        }
    }
    return 1;
}

// Resets the edges of pieces and their neighbours
void resetEdgesOfPiece(int pieceID, Piece *pieces) {
    
    int upID = pieces[pieceID].neighbourPiece.up_piece;
    int downID = pieces[pieceID].neighbourPiece.down_piece;
    int leftID = pieces[pieceID].neighbourPiece.left_piece;
    int rightID = pieces[pieceID].neighbourPiece.right_piece;

    if (upID >= 0) {
        pieces[pieceID].openEdge.up_open = isOpen;
        pieces[upID].openEdge.down_open = isOpen;
    }
    if (downID >= 0) {
        pieces[pieceID].openEdge.down_open = isOpen;
        pieces[downID].openEdge.up_open = isOpen;
    }
    if (leftID >= 0) {
        pieces[pieceID].openEdge.left_open = isOpen;
        pieces[leftID].openEdge.right_open = isOpen;
    }
    if (rightID >= 0) {
        pieces[pieceID].openEdge.right_open = isOpen;
        pieces[rightID].openEdge.left_open = isOpen;
    }
}

// Moves pieces back onto the board if they are out of bounds
void moveIfOutOfBounds(Piece *pieces) {

    for (int i = 0; i < NUM_OF_PIECES; i++) {
        if (pieces[i].x_location + SIDE_HALF > BOARD_WIDTH) {
            pieces[i].x_location = BOARD_WIDTH - SIDE_HALF;
            resetEdgesOfPiece(i, pieces);
        }
        else if (pieces[i].x_location - SIDE_HALF < 0) {
            pieces[i].x_location = SIDE_HALF;
            resetEdgesOfPiece(i, pieces);
        }
        if (pieces[i].y_location + SIDE_HALF > BOARD_HEIGHT) {
            pieces[i].y_location = BOARD_HEIGHT - SIDE_HALF;
            resetEdgesOfPiece(i, pieces);
        }
        else if (pieces[i].y_location - SIDE_HALF < 0) {
            pieces[i].y_location = SIDE_HALF;
            resetEdgesOfPiece(i, pieces);
        }
    }
}
