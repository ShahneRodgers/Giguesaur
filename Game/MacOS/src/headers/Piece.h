/*
 File: Piece.h
 Author: Ashley Manson
 Description: Header File for the pieces that go into a Giguesaur puzzle.
 */

#ifndef GIGUESAUR_PIECE_H
#define GIGUESAUR_PIECE_H

#ifdef __APPLE__
#include <OpenGL/gl.h>
#include <OpenGL/glu.h>
#include <GLUT/glut.h>
#else
#ifdef _WIN32
#include <windows.h>
#endif
#include <GL/gl.h>
#include <GL/glu.h>
#include <GL/glut.h>
#endif

typedef enum {closed, opened, invalid} Accessible;

// Representation of a Giguesaur Puzzle Piece
typedef struct {
    
    int piece_id;
    GLdouble x_centre;
    GLdouble y_centre;
    GLint side_length;
    GLdouble rotation;
    
    // Whether an edge has an adjacent Piece
    struct Edges {
        int up_piece;
        int down_piece;
        int left_piece;
        int right_piece;
    } edges;
    
    // Whether an edge is open or not
    struct Open_Edges{
        Accessible up_open;
        Accessible down_open;
        Accessible left_open;
        Accessible right_open;
    }open_edges;
    
} Piece;

#endif
