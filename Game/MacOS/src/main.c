/*
 File: main.m
 Author: Ashley Manson
 Description: Main file for the Giguesaur puzzle game.
 */

// Standard Includes
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>
// OpenGL stuff
#include <OpenGL/gl.h>
#include <OpenGL/glu.h>
#include <GLUT/glut.h>
#include <unistd.h>
#include "soil/SOIL.h"
// My Stuff
#include "headers/std_stuff.h"
#include "headers/Piece.h"

#define NUM_OF_ROWS 5
#define NUM_OF_COLS 4
#define NUM_OF_PIECES NUM_OF_ROWS*NUM_OF_COLS
#define PLUS_ROTATION 15
#define DISTANCE_BEFORE_SNAP 250
#define SCREEN_WIDTH 1920
#define SCREEN_HEIGHT 1080

typedef struct {
    // top left
    double x0;
    double y0;
    // top right
    double x1;
    double y1;
    // bot right
    double x2;
    double y2;
    // bot left
    double x3;
    double y3;
} Points_Rotated;

// Global Varibles
int holdingPiece = -1;
bool is_connections = false;
bool do_bounding_box = false;
bool do_draw_ids = false;
Piece pieces[NUM_OF_PIECES];
double texture_height = 1.0 / NUM_OF_ROWS;
double texture_length = 1.0 / NUM_OF_COLS;

GLuint textures[1];

void load_textures(char* name) {
    glGenTextures(1, textures);
    int width, height;
    unsigned char* texture_image;
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, textures[0]);
    texture_image = SOIL_load_image(name, &width, &height, 0, SOIL_LOAD_RGBA);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, texture_image);
    SOIL_free_image_data(texture_image);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glEnable(GL_TEXTURE_2D);
    glEnable(GL_DEPTH_TEST);
}

void Draw_Piece(Piece piece, bool draw_bounding_box, bool draw_id) {
    
    // WTF was I doing here >:(
    int row = 0;
    int col = 0;
    int index = 0;
    while (index != piece.piece_id) {
        col++;
        index++;
        if (col >= NUM_OF_COLS) {
            col = 0;
            row++;
        }
    }
    
    GLint half_length = piece.side_length / 2;
    glPushMatrix();
    glTranslated(piece.x_centre, piece.y_centre, 0.0);
    glRotated(piece.rotation, 0.0, 0.0, 1.0);
    glTranslated(-piece.x_centre, -piece.y_centre, 0.0);
    
    double tex_x_half = texture_length / 2;
    double tex_y_half = texture_height / 2;
    double tex_x_pt = texture_length / 5;
    double tex_y_pt = texture_height / 5;
    //glBegin(GL_POLYGON);
    glBegin(GL_TRIANGLE_FAN);
    glTexCoord2d((texture_length * col) + (texture_length/2), (texture_height * row) + (texture_height/2));
    glVertex2d(piece.x_centre, piece.y_centre);
    glTexCoord2d(texture_length * col, texture_height * (row + 1));
    glVertex2d(piece.x_centre - half_length, piece.y_centre - half_length);
    /* if (piece.edges.down_piece >=0) {
     glTexCoord2d((tex_x_half * (col + 1)) - tex_x_pt, texture_height * (row + 1));
     glVertex2d(piece.x_centre - 10, piece.y_centre - half_length);
     glTexCoord2d((tex_x_half * (col + 1)), (texture_height * (row + 1)) + tex_y_pt);
     glVertex2d(piece.x_centre, piece.y_centre - half_length - 10);
     glTexCoord2d((tex_x_half * (col + 1)) + tex_x_pt, texture_height * (row + 1));
     glVertex2d(piece.x_centre + 10, piece.y_centre - half_length);
     }*/
    glTexCoord2d(texture_length * (col + 1), texture_height * (row + 1));
    glVertex2d(piece.x_centre + half_length, piece.y_centre - half_length);
    /*if (piece.edges.right_piece >= 0) {
     glVertex2d(piece.x_centre + half_length, piece.y_centre - 10);
     glVertex2d(piece.x_centre + half_length + 10, piece.y_centre);
     glVertex2d(piece.x_centre + half_length, piece.y_centre + 10);
     }*/
    glTexCoord2d(texture_length * (col + 1), texture_height * row);
    glVertex2d(piece.x_centre + half_length, piece.y_centre + half_length);
    /*  if (piece.edges.up_piece >= 0) {
     glVertex2d(piece.x_centre + 10, piece.y_centre + half_length);
     glVertex2d(piece.x_centre, piece.y_centre + half_length - 10);
     glVertex2d(piece.x_centre - 10, piece.y_centre + half_length);
     }*/
    glTexCoord2d(texture_length * col, texture_height * row);
    glVertex2d(piece.x_centre - half_length, piece.y_centre + half_length);
    /* if (piece.edges.left_piece >= 0) {
     glVertex2d(piece.x_centre - half_length, piece.y_centre + 10);
     glVertex2d(piece.x_centre - half_length + 10, piece.y_centre);
     glVertex2d(piece.x_centre - half_length, piece.y_centre - 10);
     }*/
    glTexCoord2d(texture_length * col, texture_height * (row + 1));
    glVertex2d(piece.x_centre - half_length, piece.y_centre - half_length);
    glEnd();
    
    glPopMatrix();
    
    if (draw_bounding_box) {
        glColor4f(1.0f, 0.8f, 0.0f, 0.5f);
        glBegin(GL_LINE_LOOP);
        glVertex2d(piece.x_centre - half_length, piece.y_centre - half_length);
        glVertex2d(piece.x_centre + half_length, piece.y_centre - half_length);
        glVertex2d(piece.x_centre + half_length, piece.y_centre + half_length);
        glVertex2d(piece.x_centre - half_length, piece.y_centre + half_length);
        glVertex2d(piece.x_centre - half_length, piece.y_centre - half_length);
        glEnd();
        
    }
    if (draw_id) {
        int x = piece.x_centre - 5;
        int y = piece.y_centre - 5;
        int letter = piece.piece_id;
        
        glColor4f(1.0f, 0.5f, 0.0f, 0.5f);
        glRasterPos2d(x, y);
        
        int div;
        for (div = 1; div <= letter; div *= 10);
        
        for(;;) {
            div /= 10;
            glutBitmapCharacter(GLUT_BITMAP_HELVETICA_12, (letter == 0 ? 0 : (letter / div)) + '0');
            if (letter != 0) letter %= div;
            if (piece.piece_id % 10 == 0 && piece.piece_id != 0) {
                glutBitmapCharacter(GLUT_BITMAP_HELVETICA_12, '0');
            }
            if (letter == 0) {
                break;
            }
        }
    }
}

void Draw_Puzzle_Pieces() {
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    /*
    glColor4f(1.0f, 1.0f, 1.0f, 0.0f);
    glBegin(GL_LINE_LOOP);
    glVertex2d(0, 0);
    glVertex2d(SCREEN_WIDTH, 0);
    glVertex2d(SCREEN_WIDTH, SCREEN_HEIGHT);
    glVertex2d(0, SCREEN_HEIGHT);
    glVertex2d(0, 0);
    glEnd();
    */
    //Board, colour seems fucked up xD
    glColor4f(0.0f, 1.0f, 1.0f, 0.5f);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glBegin(GL_POLYGON);
    glVertex2d(0, 0);
    glVertex2d(SCREEN_WIDTH, 0);
    glVertex2d(SCREEN_WIDTH, SCREEN_HEIGHT);
    glVertex2d(0, SCREEN_HEIGHT);
    glVertex2d(0, 0);
    glEnd();
    glDisable(GL_BLEND);
    for (int i = 0; i < NUM_OF_PIECES; i++) {
        // Fix out of bounds
        if (pieces[i].x_centre + (pieces[i].side_length / 2) > glutGet(GLUT_WINDOW_WIDTH)) {
            pieces[i].x_centre = glutGet(GLUT_WINDOW_WIDTH) - (pieces[i].side_length / 2);
        }
        else if (pieces[i].x_centre - (pieces[i].side_length / 2) < 0) {
            pieces[i].x_centre = pieces[i].side_length / 2;
        }
        if (pieces[i].y_centre + (pieces[i].side_length / 2) > glutGet(GLUT_WINDOW_HEIGHT)) {
            pieces[i].y_centre = glutGet(GLUT_WINDOW_HEIGHT) - (pieces[i].side_length / 2);
        }
        else if (pieces[i].y_centre - (pieces[i].side_length / 2) < 0) {
            pieces[i].y_centre = pieces[i].side_length / 2;
        }
        // Fix rotations getting too small or too big
        while (pieces[i].rotation >= 360) {
            pieces[i].rotation -= 360;
        }
        while (pieces[i].rotation < 0) {
            pieces[i].rotation += 360;
        }
        
        if (i != holdingPiece) {
            glColor4f(1.0f, 1.0f, 1.0f, 0.5f);
            Draw_Piece(pieces[i], do_bounding_box, do_draw_ids);
        }
    }
    if (holdingPiece >= 0) {
        glColor4f(0.5f, 0.5f, 0.5f, 0.5f);
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        Draw_Piece(pieces[holdingPiece], do_bounding_box, do_draw_ids);
        glDisable(GL_BLEND);
    }
    
    glFlush();
    glutSwapBuffers();
}

void MakeConnections() {
    if (NUM_OF_PIECES > 0) {
        int index = 0;
        for (int row = 0; row < NUM_OF_ROWS; row++) {
            for (int col = 0; col < NUM_OF_COLS; col++) {
                if (row == 0) {
                    pieces[index].edges.up_piece = -1;
                }
                else {
                    pieces[index].edges.up_piece = index - NUM_OF_COLS;
                }
                if (row + 1 == NUM_OF_ROWS) {
                    pieces[index].edges.down_piece = -1;
                }
                else {
                    pieces[index].edges.down_piece = index + NUM_OF_COLS;
                }
                if (col == 0) {
                    pieces[index].edges.left_piece = -1;
                }
                else {
                    pieces[index].edges.left_piece = index - 1;
                }
                if (col + 1 == NUM_OF_COLS) {
                    pieces[index].edges.right_piece = -1;
                }
                else {
                    pieces[index].edges.right_piece = index + 1;
                }
                index++;
            }
        }
        is_connections = true;
    }
    else {
        is_connections = false;
        fprintf(stderr, "Cannnot make connections!\n");
    }
    if (is_connections) {
        for (int i = 0; i < NUM_OF_PIECES; i++) {
            Accessible up = closed;
            Accessible down = closed;
            Accessible left = closed;
            Accessible right = closed;
            
            if (pieces[i].edges.up_piece >= 0) up = opened;
            else up = invalid;
            if (pieces[i].edges.down_piece >= 0) down = opened;
            else down = invalid;
            if (pieces[i].edges.left_piece >= 0) left = opened;
            else left = invalid;
            if (pieces[i].edges.right_piece >= 0) right = opened;
            else right = invalid;
            
            pieces[i].open_edges.up_open = up;
            pieces[i].open_edges.down_open = down;
            pieces[i].open_edges.left_open = left;
            pieces[i].open_edges.right_open = right;
        }
    }
}

Points_Rotated Get_Rotated_Points(Piece piece) {
    int x = piece.x_centre;
    int y = piece.y_centre;
    int side = piece.side_length;
    
    double theta = (double) piece.rotation * PI / 180.0;
    double xa = x-side/2;
    double ya = y+side/2;
    double xb = x+side/2;
    double yb = y+side/2;
    double xc = x+side/2;
    double yc = y-side/2;
    double xd = x-side/2;
    double yd = y-side/2;
    double xa_new = cos(theta) * (xa - x) - sin(theta) * (ya - y) + x;
    double ya_new = sin(theta) * (xa - x) + cos(theta) * (ya - y) + y;
    double xb_new = cos(theta) * (xb - x) - sin(theta) * (yb - y) + x;
    double yb_new = sin(theta) * (xb - x) + cos(theta) * (yb - y) + y;
    double xc_new = cos(theta) * (xc - x) - sin(theta) * (yc - y) + x;
    double yc_new = sin(theta) * (xc - x) + cos(theta) * (yc - y) + y;
    double xd_new = cos(theta) * (xd - x) - sin(theta) * (yd - y) + x;
    double yd_new = sin(theta) * (xd - x) + cos(theta) * (yd - y) + y;
    Points_Rotated new_piece_location = {.x0 = xa_new,
        .y0 = ya_new,
        .x1 = xb_new,
        .y1 = yb_new,
        .x2 = xc_new,
        .y2 = yc_new,
        .x3 = xd_new,
        .y3 = yd_new};
    return new_piece_location;
}

void CheckForConnections(int piece_num) {
    if (piece_num >= 0 && is_connections) {
        
        int up_id = pieces[piece_num].edges.up_piece;
        int right_id = pieces[piece_num].edges.right_piece;
        int down_id = pieces[piece_num].edges.down_piece;
        int left_id = pieces[piece_num].edges.left_piece;
        
        Points_Rotated new_points = Get_Rotated_Points(pieces[piece_num]);
        
        if (up_id >= 0) {
            Points_Rotated up_points = Get_Rotated_Points(pieces[up_id]);
            double distance_1 = pow((new_points.x0 - up_points.x3), 2)
            + pow((new_points.y0 - up_points.y3), 2);
            double distance_2 = pow((new_points.x1 - up_points.x2), 2)
            + pow((new_points.y1 - up_points.y2), 2);
            
            if (distance_1 < DISTANCE_BEFORE_SNAP && distance_2 < DISTANCE_BEFORE_SNAP) {
                double rads = pieces[up_id].rotation * PI / 180.0;
                double adj = pieces[up_id].side_length * cos(rads);
                double opp = pieces[up_id].side_length * sin(rads);
                double x_new = pieces[up_id].x_centre + opp;
                double y_new = pieces[up_id].y_centre - adj;
                pieces[piece_num].x_centre = x_new;
                pieces[piece_num].y_centre = y_new;
                pieces[piece_num].rotation = pieces[up_id].rotation;
            }
        }
        if (right_id >= 0) {
            Points_Rotated right_points = Get_Rotated_Points(pieces[right_id]);
            double distance_1 = pow((new_points.x1 - right_points.x0), 2)
            + pow((new_points.y1 - right_points.y0), 2);
            double distance_2 = pow((new_points.x2 - right_points.x3), 2)
            + pow((new_points.y2 - right_points.y3), 2);
            
            if (distance_1 < DISTANCE_BEFORE_SNAP && distance_2 < DISTANCE_BEFORE_SNAP) {
                double rads = pieces[right_id].rotation * PI / 180.0;
                double adj = pieces[right_id].side_length * sin(rads);
                double opp = pieces[right_id].side_length * cos(rads);
                double x_new = pieces[right_id].x_centre - opp;
                double y_new = pieces[right_id].y_centre - adj;
                pieces[piece_num].x_centre = x_new;
                pieces[piece_num].y_centre = y_new;
                pieces[piece_num].rotation = pieces[right_id].rotation;
            }
        }
        if (down_id >= 0) {
            Points_Rotated down_points = Get_Rotated_Points(pieces[down_id]);
            double distance_1 = pow((new_points.x3 - down_points.x0), 2)
            + pow((new_points.y3 - down_points.y0), 2);
            double distance_2 = pow((new_points.x2 - down_points.x1), 2)
            + pow((new_points.y2 - down_points.y1), 2);
            
            if (distance_1 < DISTANCE_BEFORE_SNAP && distance_2 < DISTANCE_BEFORE_SNAP) {
                double rads = pieces[down_id].rotation * PI / 180.0;
                double adj = pieces[down_id].side_length * cos(rads);
                double opp = pieces[down_id].side_length * sin(rads);
                double x_new = pieces[down_id].x_centre - opp;
                double y_new = pieces[down_id].y_centre + adj;
                pieces[piece_num].x_centre = x_new;
                pieces[piece_num].y_centre = y_new;
                pieces[piece_num].rotation = pieces[down_id].rotation;
            }
        }
        if (left_id >= 0) {
            Points_Rotated left_points = Get_Rotated_Points(pieces[left_id]);
            double distance_1 = pow((new_points.x0 - left_points.x1), 2)
            + pow((new_points.y0 - left_points.y1), 2);
            double distance_2 = pow((new_points.x3 - left_points.x2), 2)
            + pow((new_points.y3 - left_points.y2), 2);
            
            if (distance_1 < DISTANCE_BEFORE_SNAP && distance_2 < DISTANCE_BEFORE_SNAP) {
                double rads = pieces[left_id].rotation * PI / 180.0;
                double adj = pieces[left_id].side_length * sin(rads);
                double opp = pieces[left_id].side_length * cos(rads);
                double x_new = pieces[left_id].x_centre + opp;
                double y_new = pieces[left_id].y_centre + adj;
                pieces[piece_num].x_centre = x_new;
                pieces[piece_num].y_centre = y_new;
                pieces[piece_num].rotation = pieces[left_id].rotation;
            }
        }
        
        if (up_id >= 0) {
            double rads = pieces[up_id].rotation * PI / 180.0;
            double adj = pieces[up_id].side_length * cos(rads);
            double opp = pieces[up_id].side_length * sin(rads);
            double x_new = pieces[up_id].x_centre + opp;
            double y_new = pieces[up_id].y_centre - adj;
            
            bool x_true = pieces[piece_num].x_centre - x_new < 1 && pieces[piece_num].x_centre - x_new > -1;
            bool y_true = pieces[piece_num].y_centre - y_new < 1 && pieces[piece_num].y_centre - y_new > -1;
            if (x_true && y_true) {
                pieces[piece_num].open_edges.up_open = closed;
                pieces[up_id].open_edges.down_open = closed;
                printf("Piece %d joined piece %d\n", piece_num, up_id);
            }
            
        }
        if (right_id >= 0) {
            double rads = pieces[right_id].rotation * PI / 180.0;
            double adj = pieces[right_id].side_length * sin(rads);
            double opp = pieces[right_id].side_length * cos(rads);
            double x_new = pieces[right_id].x_centre - opp;
            double y_new = pieces[right_id].y_centre - adj;
            
            bool x_true = pieces[piece_num].x_centre - x_new < 1 && pieces[piece_num].x_centre - x_new > -1;
            bool y_true = pieces[piece_num].y_centre - y_new < 1 && pieces[piece_num].y_centre - y_new > -1;
            if (x_true && y_true) {
                pieces[piece_num].open_edges.right_open = closed;
                pieces[right_id].open_edges.left_open = closed;
                printf("Piece %d joined piece %d\n", piece_num, right_id);
            }
            
        }
        if (down_id >= 0) {
            double rads = pieces[down_id].rotation * PI / 180.0;
            double adj = pieces[down_id].side_length * cos(rads);
            double opp = pieces[down_id].side_length * sin(rads);
            double x_new = pieces[down_id].x_centre - opp;
            double y_new = pieces[down_id].y_centre + adj;
            
            bool x_true = pieces[piece_num].x_centre - x_new < 1 && pieces[piece_num].x_centre - x_new > -1;
            bool y_true = pieces[piece_num].y_centre - y_new < 1 && pieces[piece_num].y_centre - y_new > -1;
            if (x_true && y_true) {
                pieces[piece_num].open_edges.down_open = closed;
                pieces[down_id].open_edges.up_open = closed;
                printf("Piece %d joined piece %d\n", piece_num, down_id);
            }
            
        }
        if (left_id >= 0) {
            double rads = pieces[left_id].rotation * PI / 180.0;
            double adj = pieces[left_id].side_length * sin(rads);
            double opp = pieces[left_id].side_length * cos(rads);
            double x_new = pieces[left_id].x_centre + opp;
            double y_new = pieces[left_id].y_centre + adj;
            
            bool x_true = pieces[piece_num].x_centre - x_new < 1 && pieces[piece_num].x_centre - x_new > -1;
            bool y_true = pieces[piece_num].y_centre - y_new < 1 && pieces[piece_num].y_centre - y_new > -1;
            if (x_true && y_true) {
                pieces[piece_num].open_edges.left_open = closed;
                pieces[left_id].open_edges.right_open = closed;
                printf("Piece %d joined piece %d\n", piece_num, left_id);
            }
            
        }
    }
}

void CheckIfSolved() {
    bool solved = true;
    for (int i = 0; i < NUM_OF_PIECES; i++) {
        if (pieces[i].open_edges.up_open == opened) {
            solved = false;
            i = NUM_OF_PIECES;
        }
        if (pieces[i].open_edges.down_open == opened) {
            solved = false;
            i = NUM_OF_PIECES;
        }
        if (pieces[i].open_edges.left_open == opened) {
            solved = false;
            i = NUM_OF_PIECES;
        }
        if (pieces[i].open_edges.right_open == opened) {
            solved = false;
            i = NUM_OF_PIECES;
        }
    }
    if (solved) printf("Solved!\n");
    else printf("Not Solved\n");
}

void Render() {
    Draw_Puzzle_Pieces();
}

bool gluInvertMatrix(const double m[16], double invOut[16]) {
    double inv[16], det;
    int i;
    
    inv[0] = m[5]  * m[10] * m[15] -
    m[5]  * m[11] * m[14] -
    m[9]  * m[6]  * m[15] +
    m[9]  * m[7]  * m[14] +
    m[13] * m[6]  * m[11] -
    m[13] * m[7]  * m[10];
    
    inv[4] = -m[4]  * m[10] * m[15] +
    m[4]  * m[11] * m[14] +
    m[8]  * m[6]  * m[15] -
    m[8]  * m[7]  * m[14] -
    m[12] * m[6]  * m[11] +
    m[12] * m[7]  * m[10];
    
    inv[8] = m[4]  * m[9] * m[15] -
    m[4]  * m[11] * m[13] -
    m[8]  * m[5] * m[15] +
    m[8]  * m[7] * m[13] +
    m[12] * m[5] * m[11] -
    m[12] * m[7] * m[9];
    
    inv[12] = -m[4]  * m[9] * m[14] +
    m[4]  * m[10] * m[13] +
    m[8]  * m[5] * m[14] -
    m[8]  * m[6] * m[13] -
    m[12] * m[5] * m[10] +
    m[12] * m[6] * m[9];
    
    inv[1] = -m[1]  * m[10] * m[15] +
    m[1]  * m[11] * m[14] +
    m[9]  * m[2] * m[15] -
    m[9]  * m[3] * m[14] -
    m[13] * m[2] * m[11] +
    m[13] * m[3] * m[10];
    
    inv[5] = m[0]  * m[10] * m[15] -
    m[0]  * m[11] * m[14] -
    m[8]  * m[2] * m[15] +
    m[8]  * m[3] * m[14] +
    m[12] * m[2] * m[11] -
    m[12] * m[3] * m[10];
    
    inv[9] = -m[0]  * m[9] * m[15] +
    m[0]  * m[11] * m[13] +
    m[8]  * m[1] * m[15] -
    m[8]  * m[3] * m[13] -
    m[12] * m[1] * m[11] +
    m[12] * m[3] * m[9];
    
    inv[13] = m[0]  * m[9] * m[14] -
    m[0]  * m[10] * m[13] -
    m[8]  * m[1] * m[14] +
    m[8]  * m[2] * m[13] +
    m[12] * m[1] * m[10] -
    m[12] * m[2] * m[9];
    
    inv[2] = m[1]  * m[6] * m[15] -
    m[1]  * m[7] * m[14] -
    m[5]  * m[2] * m[15] +
    m[5]  * m[3] * m[14] +
    m[13] * m[2] * m[7] -
    m[13] * m[3] * m[6];
    
    inv[6] = -m[0]  * m[6] * m[15] +
    m[0]  * m[7] * m[14] +
    m[4]  * m[2] * m[15] -
    m[4]  * m[3] * m[14] -
    m[12] * m[2] * m[7] +
    m[12] * m[3] * m[6];
    
    inv[10] = m[0]  * m[5] * m[15] -
    m[0]  * m[7] * m[13] -
    m[4]  * m[1] * m[15] +
    m[4]  * m[3] * m[13] +
    m[12] * m[1] * m[7] -
    m[12] * m[3] * m[5];
    
    inv[14] = -m[0]  * m[5] * m[14] +
    m[0]  * m[6] * m[13] +
    m[4]  * m[1] * m[14] -
    m[4]  * m[2] * m[13] -
    m[12] * m[1] * m[6] +
    m[12] * m[2] * m[5];
    
    inv[3] = -m[1] * m[6] * m[11] +
    m[1] * m[7] * m[10] +
    m[5] * m[2] * m[11] -
    m[5] * m[3] * m[10] -
    m[9] * m[2] * m[7] +
    m[9] * m[3] * m[6];
    
    inv[7] = m[0] * m[6] * m[11] -
    m[0] * m[7] * m[10] -
    m[4] * m[2] * m[11] +
    m[4] * m[3] * m[10] +
    m[8] * m[2] * m[7] -
    m[8] * m[3] * m[6];
    
    inv[11] = -m[0] * m[5] * m[11] +
    m[0] * m[7] * m[9] +
    m[4] * m[1] * m[11] -
    m[4] * m[3] * m[9] -
    m[8] * m[1] * m[7] +
    m[8] * m[3] * m[5];
    
    inv[15] = m[0] * m[5] * m[10] -
    m[0] * m[6] * m[9] -
    m[4] * m[1] * m[10] +
    m[4] * m[2] * m[9] +
    m[8] * m[1] * m[6] -
    m[8] * m[2] * m[5];
    
    det = m[0] * inv[0] + m[1] * inv[4] + m[2] * inv[8] + m[3] * inv[12];

    if (det == 0)
        return false;
    
    det = 1.0 / det;
    
    for (i = 0; i < 16; i++)
        invOut[i] = inv[i] * det;
    
    return true;
}

void MouseListener(int button, int state, int x, int y) {
    
    GLdouble model[16];
    GLdouble project[16];
    GLdouble model_mat[4][4];
    GLdouble project_mat[4][4];
    GLdouble model_project[16];
    GLdouble model_project_mat[4][4];
    GLdouble inverse_mat[16];
    GLint viewport[4];
    glGetDoublev(GL_MODELVIEW_MATRIX, model);
    glGetDoublev(GL_PROJECTION_MATRIX, project);
    glGetIntegerv(GL_VIEWPORT, viewport);
    GLdouble new_projection[4];
    int sum = 0;
  
    new_projection[0] = 2.0 * x / viewport[2] - 1;
    new_projection[1] = -(2.0 * y / viewport[3] + 1);
    new_projection[2] = 0;
    new_projection[3] = 1.0;
    
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            for (int k = 0; k < 4; k++) {
                sum = sum + project_mat[i][k]*model_mat[k][j];
            }
            model_project_mat[i][j] = sum;
            sum = 0;
        }
    }
    
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            model_project[i*4+j] = model_project_mat[i][j];
        }
    }
    
    bool success = gluInvertMatrix(model_project, inverse_mat);
    if (success) puts("Yep");
    
    y = glutGet(GLUT_WINDOW_HEIGHT)-y; // Fix Mouse Y
    //x = -(SCREEN_WIDTH - x * 2 - 1);
    //y = SCREEN_HEIGHT - y * 2 - 1;
    if (button == GLUT_LEFT_BUTTON && state == GLUT_DOWN) {
        // Place piece back on board if holding a piece
        if (holdingPiece >= 0) {
            bool can_place = true;
            for (int i = 0; i < NUM_OF_PIECES; i++) {
                if(pieces[holdingPiece].x_centre >= pieces[i].x_centre - (pieces[i].side_length/2) && pieces[holdingPiece].x_centre < pieces[i].x_centre + (pieces[i].side_length/2)) {
                    if (pieces[holdingPiece].y_centre >= pieces[i].y_centre - (pieces[i].side_length/2) && pieces[holdingPiece].y_centre < pieces[i].y_centre + (pieces[i].side_length/2)) {
                        if (i != holdingPiece) {
                            printf("Cannot place piece %d on piece %d\n", holdingPiece, i);
                            can_place = false;
                            i = NUM_OF_PIECES;
                        }
                    }
                }
            }
            if (can_place) {
                pieces[holdingPiece].x_centre = x;
                pieces[holdingPiece].y_centre = y;
                CheckForConnections(holdingPiece);
                holdingPiece = -1;
            }
        }
        else {
            for (int i = 0; i < NUM_OF_PIECES; i++) {
                if(x >= pieces[i].x_centre - (pieces[i].side_length/2) && x < pieces[i].x_centre + (pieces[i].side_length/2)) {
                    if (y >= pieces[i].y_centre - (pieces[i].side_length/2) && y < pieces[i].y_centre + (pieces[i].side_length/2)) {
                        pieces[i].x_centre = x;
                        pieces[i].y_centre = y;
                        holdingPiece = i;
                        if (pieces[i].open_edges.up_open == closed) pieces[i].open_edges.up_open = opened;
                        if (pieces[i].open_edges.down_open == closed) pieces[i].open_edges.down_open = opened;
                        if (pieces[i].open_edges.left_open == closed) pieces[i].open_edges.left_open = opened;
                        if (pieces[i].open_edges.right_open == closed) pieces[i].open_edges.right_open = opened;
                        printf("Picked up piece: %d\n", holdingPiece);
                        i = NUM_OF_PIECES;
                    }
                }
            }
        }
    }
    
    if (button == GLUT_RIGHT_BUTTON && state == GLUT_DOWN) {
        if (holdingPiece >= 0) {
            pieces[holdingPiece].rotation += PLUS_ROTATION;
            printf("Rotated piece %d has rotation %.2f\n", holdingPiece, pieces[holdingPiece].rotation);
        }
        else {
            for (int i = 0; i < NUM_OF_PIECES; i++) {
                if(x >= pieces[i].x_centre - (pieces[i].side_length/2) && x < pieces[i].x_centre + (pieces[i].side_length/2)) {
                    if (y >= pieces[i].y_centre - (pieces[i].side_length/2) && y < pieces[i].y_centre + (pieces[i].side_length/2)) {
                        pieces[i].rotation += PLUS_ROTATION;
                        if (pieces[i].open_edges.up_open == closed) pieces[i].open_edges.up_open = opened;
                        if (pieces[i].open_edges.down_open == closed) pieces[i].open_edges.down_open = opened;
                        if (pieces[i].open_edges.left_open == closed) pieces[i].open_edges.left_open = opened;
                        if (pieces[i].open_edges.right_open == closed) pieces[i].open_edges.right_open = opened;
                        printf("Rotated piece %d has rotation %.2f\n", i, pieces[i].rotation);
                        i = NUM_OF_PIECES;
                    }
                }
            }
        }
    }
    Draw_Puzzle_Pieces();
}

void MousePosition(int x, int y) {
    y = glutGet(GLUT_WINDOW_HEIGHT)-y; // Fix Mouse Y
    //x = -(SCREEN_WIDTH - x * 2 - 1);
    //y = SCREEN_HEIGHT - y * 2 - 1;
    //printf("Mouse: %d %d\n", x, y);
    if (holdingPiece >= 0) {
        pieces[holdingPiece].x_centre = x;
        pieces[holdingPiece].y_centre = y;
        Draw_Puzzle_Pieces();
    }
}

void SpecialInput(int key, int x, int y) {
    switch (key) {
        case GLUT_KEY_UP:
            glMatrixMode(GL_MODELVIEW);
            glTranslated(SCREEN_WIDTH/2, SCREEN_HEIGHT/2, 0.0);
            glRotated(15, -1, 0, 0);
            glTranslated(-SCREEN_WIDTH/2, -SCREEN_HEIGHT/2, 0.0);
            glutPostRedisplay();
            break;
        case GLUT_KEY_DOWN:
            glMatrixMode(GL_MODELVIEW);
            glTranslated(SCREEN_WIDTH/2, SCREEN_HEIGHT/2, 0.0);
            glRotated(15, 1, 0, 0);
            glTranslated(-SCREEN_WIDTH/2, -SCREEN_HEIGHT/2, 0.0);
            glutPostRedisplay();
            break;
        case GLUT_KEY_LEFT:
            glMatrixMode(GL_MODELVIEW);
            glTranslated(SCREEN_WIDTH/2, SCREEN_HEIGHT/2, 0.0);
            glRotated(15, 0, -1, 0);
            glTranslated(-SCREEN_WIDTH/2, -SCREEN_HEIGHT/2, 0.0);
            glutPostRedisplay();
            break;
        case GLUT_KEY_RIGHT:
            glMatrixMode(GL_MODELVIEW);
            glTranslated(SCREEN_WIDTH/2, SCREEN_HEIGHT/2, 0.0);
            glRotated(15, 0, 1, 0);
            glTranslated(-SCREEN_WIDTH/2, -SCREEN_HEIGHT/2, 0.0);
            glutPostRedisplay();
            break;
    }
}

void KeyboardListener(unsigned char theKey, int mouseX, int mouseY) {
    
    switch (theKey) {
            // ==========
        case '-':
            glMatrixMode(GL_MODELVIEW);
            glTranslated(SCREEN_WIDTH/2, SCREEN_HEIGHT/2, 0.0);
            glScaled(0.5, 0.5, 0.5);
            glTranslated(-SCREEN_WIDTH/2, -SCREEN_HEIGHT/2, 0.0);
            glutPostRedisplay();
            break;
        case '=':
            glMatrixMode(GL_MODELVIEW);
            glTranslated(SCREEN_WIDTH/2, SCREEN_HEIGHT/2, 0.0);
            glScaled(2, 2, 2);
            glTranslated(-SCREEN_WIDTH/2, -SCREEN_HEIGHT/2, 0.0);
            glutPostRedisplay();
            break;
        case '[':
            glMatrixMode(GL_MODELVIEW);
            glTranslated(SCREEN_WIDTH/2, SCREEN_HEIGHT/2, 0.0);
            glRotated(15, 0, 0, 1);
            glTranslated(-SCREEN_WIDTH/2, -SCREEN_HEIGHT/2, 0.0);
            glutPostRedisplay();
            break;
        case ']':
            glMatrixMode(GL_MODELVIEW);
            glTranslated(SCREEN_WIDTH/2, SCREEN_HEIGHT/2, 0.0);
            glRotated(15, 0, 0, -1);
            glTranslated(-SCREEN_WIDTH/2, -SCREEN_HEIGHT/2, 0.0);
            glutPostRedisplay();
            break;
        case 'w':
        case 'W':
            glMatrixMode(GL_MODELVIEW);
            glTranslated(0,15,0);
            glutPostRedisplay();
            break;
        case 's':
        case 'S':
            glMatrixMode(GL_MODELVIEW);
            glTranslated(0,-15,0);
            glutPostRedisplay();
            break;
        case 'a':
        case 'A':
            glMatrixMode(GL_MODELVIEW);
            glTranslated(-15,0,0);
            glutPostRedisplay();
            break;
        case 'd':
        case 'D':
            glMatrixMode(GL_MODELVIEW);
            glTranslated(15,0,0);
            glutPostRedisplay();
            break;
            //==========
            
        case 'p':
        case 'P':
            for (int i = 0; i < NUM_OF_PIECES; i++) {
                printf("%d: x = %.2f, y = %.2f\n", i, pieces[i].x_centre, pieces[i].y_centre);
            }
            break;
        case 'r':
        case 'R':
            for (int i = 0; i < NUM_OF_PIECES; i++) {
                pieces[i].rotation = 0;
                if (pieces[i].open_edges.up_open == closed) pieces[i].open_edges.up_open = opened;
                if (pieces[i].open_edges.down_open == closed) pieces[i].open_edges.down_open = opened;
                if (pieces[i].open_edges.left_open == closed) pieces[i].open_edges.left_open = opened;
                if (pieces[i].open_edges.right_open == closed) pieces[i].open_edges.right_open = opened;
            }
            printf("Puzzle reset\n");
            Draw_Puzzle_Pieces();
            break;
        case 't':
        case 'T':
            if (do_bounding_box) do_bounding_box = false;
            else do_bounding_box = true;
            Draw_Puzzle_Pieces();
            break;
        case BTN_SPACE:
            CheckIfSolved();
            break;
        case BTN_ESCAPE:
        case 'q':
        case 'Q':
            exit(0);
            break;
        default:
            break;
    }
}

void WindowResize(int width, int height) {
    
    Draw_Puzzle_Pieces();
}

int main(int argc, char * argv[]) {
    
    srand((unsigned)time(NULL));
    
    for (int i = 0; i < NUM_OF_PIECES; i++) {
        Piece piece = { .piece_id = i,
            .x_centre = rand()%SCREEN_WIDTH,
            .y_centre = rand()%SCREEN_HEIGHT,
            .side_length = 100,
            .rotation = 0};
        pieces[i] = piece;
    }
    MakeConnections();
    
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGB);
    
    glutInitWindowSize(SCREEN_WIDTH, SCREEN_HEIGHT);
    glutInitWindowPosition((1920-SCREEN_WIDTH)/2, 0);
    glutCreateWindow("Giguesaur Alpha - Perspective Demo");
    
    glutDisplayFunc(Render);
    glutMouseFunc(MouseListener);
    glutPassiveMotionFunc(MousePosition);
    glutKeyboardFunc(KeyboardListener);
    glutSpecialFunc(SpecialInput);
    //glutReshapeFunc(WindowResize);
    
    // Background Colour
    glClearColor(1.0, 1.0, 1.0, 0.0);
    glEnable(GL_DEPTH_TEST);
    
    glViewport(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    
    gluPerspective(90.0f, (float)SCREEN_WIDTH/(float)SCREEN_HEIGHT, 0.01f, 5000.0f);
    //glOrtho(-0, SCREEN_WIDTH, -0, SCREEN_HEIGHT, -1000, 1000);
    
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    gluLookAt(0, 0, -3, 1280/2, 720/2, 1, 0, 1, 0);
    glTranslated(SCREEN_WIDTH/2, SCREEN_HEIGHT/2, 0.0);
    glRotated(-90, 0, 1, 0);
    glTranslated(-SCREEN_WIDTH/2, -SCREEN_HEIGHT/2, 0.0);
    char filepath[] = "/Users/localash/Desktop/Giguesaur-Game/MacOS/resources/puppy.png";
    FILE *fp;
    if ((fp = fopen(filepath, "r")) == NULL)
        fprintf(stderr, "Failed to load image!\n");
    else {
        fclose(fp);
        load_textures(filepath);
    }
    glutMainLoop();
    
    return 0;
}
