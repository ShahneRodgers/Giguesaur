/*
    File: Piece.h
    Author: Ashley Manson
 
    Defines what a puzzle piece is.
 */

#ifndef Giguesaur_Piece_h
#define Giguesaur_Piece_h

// Should be an even number or there is a line visbible between pieces when they snap together
#define SIDE_LENGTH 50
#define SIDE_HALF (SIDE_LENGTH/2)
#define P_FALSE 0
#define P_TRUE 1

typedef enum {invalid, isClosed, isOpen} ACCESSIBLE_EDGE;

typedef struct {
    int piece_id;
    float x_location;
    float y_location;
    float rotation;
    int held;
    
    struct NEIGHBOUR_PIECE {
        int up_piece;
        int down_piece;
        int left_piece;
        int right_piece;
    } neighbourPiece;
    
    struct OPEN_EDGE {
        ACCESSIBLE_EDGE up_open;
        ACCESSIBLE_EDGE down_open;
        ACCESSIBLE_EDGE left_open;
        ACCESSIBLE_EDGE right_open;
    } openEdge;
    
} Piece;

#endif
