//
//  main.c
//  Jigsaw
//

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>
#include <OpenGL/gl.h>
#include <OpenGL/glu.h>
#include <GLUT/glut.h>

#define PIECES_SIZE 9
#define PIECE_LENGTH 50
#define SCREEN_WIDTH 1280
#define SCREEN_HEIGHT 720

typedef enum {false, true, null} bool;

typedef struct {
    int up_Piece;
    int down_Piece;
    int left_Piece;
    int right_Piece;
} Edge;

typedef struct {
    bool up_open;
    bool down_open;
    bool left_open;
    bool right_open;
} OpenEdges;

typedef struct {
    int pieceID;
    GLint x_Location;
    GLint y_Location;
    int size;
    Edge edges;
    OpenEdges open_edges;
} Piece;

// Global Varibles
int holdingPiece = -1;
bool is_connections = false;
Piece pieces[PIECES_SIZE];

void DrawPiece(Piece piece) {
    glBegin(GL_POLYGON);
    glVertex2i(piece.x_Location, piece.y_Location);
    glVertex2i(piece.x_Location + piece.size, piece.y_Location);
    glVertex2i(piece.x_Location + piece.size, piece.y_Location + piece.size);
    glVertex2i(piece.x_Location, piece.y_Location + piece.size);
    glEnd();
}

void DrawLetter(Piece piece) {
    int x = piece.x_Location + (piece.size/2)-5;
    int y = piece.y_Location + (piece.size/2)-5;
    int letter = piece.pieceID;
    glColor4f(1.0f, 0.5f, 0.0f, 0.5f);
    glRasterPos2d(x, y);
    
    int div;
    for (div = 1; div <= letter; div *= 10);
    do {
        div /= 10;
        glutBitmapCharacter(GLUT_BITMAP_HELVETICA_12, (letter == 0 ? 0 : (letter / div)) + '0');
        if (letter != 0) letter %= div;
    } while (letter);
    
}

void DrawPuzzlePieces() {
    glClear(GL_COLOR_BUFFER_BIT);
    
    for (int i = 0; i < PIECES_SIZE; i++) {
        if (i != holdingPiece) {
            glColor4f(0.0f, 0.0f, 0.0f, 1.0f);
            // Fix out of bounds
            if (pieces[i].x_Location + pieces[i].size > glutGet(GLUT_WINDOW_WIDTH)) {
                pieces[i].x_Location = glutGet(GLUT_WINDOW_WIDTH) - pieces[i].size;
            }
            else if (pieces[i].x_Location < 0) {
                pieces[i].x_Location = 0;
            }
            if (pieces[i].y_Location + pieces[i].size > glutGet(GLUT_WINDOW_HEIGHT)) {
                pieces[i].y_Location = glutGet(GLUT_WINDOW_HEIGHT) - pieces[i].size;
            }
            else if (pieces[i].y_Location < 0) {
                pieces[i].y_Location = 0;
            }
            DrawPiece(pieces[i]);
            DrawLetter(pieces[i]);
        }
    }
    if (holdingPiece >= 0) {
        glColor4f(0.5f, 0.5f, 0.5f, 0.5f);
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        DrawPiece(pieces[holdingPiece]);
        DrawLetter(pieces[holdingPiece]);
        glDisable(GL_BLEND);
    }
    
    glFlush();
}

void MakeConnections() {
    if (PIECES_SIZE == 4) {
        
        // Hard coded values
        pieces[0].edges.up_Piece = -1;
        pieces[0].edges.right_Piece = 1;
        pieces[0].edges.down_Piece = 2;
        pieces[0].edges.left_Piece = -1;
        
        pieces[1].edges.up_Piece = -1;
        pieces[1].edges.right_Piece = -1;
        pieces[1].edges.down_Piece = 3;
        pieces[1].edges.left_Piece = 0;
        
        pieces[2].edges.up_Piece = 0;
        pieces[2].edges.right_Piece = 3;
        pieces[2].edges.down_Piece = -1;
        pieces[2].edges.left_Piece = -1;
        
        pieces[3].edges.up_Piece = 1;
        pieces[3].edges.right_Piece = -1;
        pieces[3].edges.down_Piece = -1;
        pieces[3].edges.left_Piece = 2;
        
        is_connections = true;
    }
    else if (PIECES_SIZE == 9) {
        
        // Hard coded values
        pieces[0].edges.up_Piece = -1;
        pieces[0].edges.right_Piece = 1;
        pieces[0].edges.down_Piece = 3;
        pieces[0].edges.left_Piece = -1;
        
        pieces[1].edges.up_Piece = -1;
        pieces[1].edges.right_Piece = 2;
        pieces[1].edges.down_Piece = 4;
        pieces[1].edges.left_Piece = 0;
        
        pieces[2].edges.up_Piece = -1;
        pieces[2].edges.right_Piece = -1;
        pieces[2].edges.down_Piece = 5;
        pieces[2].edges.left_Piece = 1;
        
        pieces[3].edges.up_Piece = 0;
        pieces[3].edges.right_Piece = 4;
        pieces[3].edges.down_Piece = 6;
        pieces[3].edges.left_Piece = -1;
        
        pieces[4].edges.up_Piece = 1;
        pieces[4].edges.right_Piece = 5;
        pieces[4].edges.down_Piece = 7;
        pieces[4].edges.left_Piece = 3;
        
        pieces[5].edges.up_Piece = 2;
        pieces[5].edges.right_Piece = -1;
        pieces[5].edges.down_Piece = 8;
        pieces[5].edges.left_Piece = 4;
        
        pieces[6].edges.up_Piece = 3;
        pieces[6].edges.right_Piece = 7;
        pieces[6].edges.down_Piece = -1;
        pieces[6].edges.left_Piece = -1;
        
        pieces[7].edges.up_Piece = 4;
        pieces[7].edges.right_Piece = 8;
        pieces[7].edges.down_Piece = -1;
        pieces[7].edges.left_Piece = 6;
        
        pieces[8].edges.up_Piece = 5;
        pieces[8].edges.right_Piece = -1;
        pieces[8].edges.down_Piece = -1;
        pieces[8].edges.left_Piece = 7;
 
        is_connections = true;
    }
    else {
        is_connections = false;
        fprintf(stderr, "Cannnot make connections!\n");
    }
    if (is_connections) {
        for (int i = 0; i < PIECES_SIZE; i++) {
            bool up = false;
            bool down = false;
            bool left = false;
            bool right = false;
            
            if (pieces[i].edges.up_Piece > 0) up = true;
            else up = null;
            if (pieces[i].edges.down_Piece > 0) down = true;
            else down = null;
            if (pieces[i].edges.left_Piece > 0) left = true;
            else left = null;
            if (pieces[i].edges.right_Piece > 0) right = true;
            else right = null;
            
            pieces[i].open_edges.up_open = up;
            pieces[i].open_edges.down_open = down;
            pieces[i].open_edges.left_open = left;
            pieces[i].open_edges.right_open = right;
        }
    }
}

void CheckForConnections(int piece_num) {
    if (piece_num >= 0 && is_connections) {
        
        int up_p = pieces[piece_num].edges.up_Piece;
        int right_p = pieces[piece_num].edges.right_Piece;
        int down_p = pieces[piece_num].edges.down_Piece;
        int left_p = pieces[piece_num].edges.left_Piece;
        
        int x1, x2, y1, y2;
        int distance = pieces[piece_num].size/2;
        
        if (up_p >= 0) {
            x1 = pieces[piece_num].x_Location;
            x2 = pieces[up_p].x_Location;
            y1 = pieces[piece_num].y_Location + pieces[piece_num].size;
            y2 = pieces[up_p].y_Location;
            
            if (x1 - x2 < distance && x1 - x2 > -distance) {
                if (y1 - y2 < distance && y1 - y2 > -distance) {
                    printf("Piece %d joined piece %d\n", piece_num, up_p);
                    pieces[piece_num].x_Location = pieces[up_p].x_Location;
                    pieces[piece_num].y_Location = pieces[up_p].y_Location - pieces[piece_num].size;
                }
            }
        }
        if (right_p >= 0) {
            x1 = pieces[piece_num].x_Location + pieces[piece_num].size;
            x2 = pieces[right_p].x_Location;
            y1 = pieces[piece_num].y_Location;
            y2 = pieces[right_p].y_Location;
            
            if (x1 - x2 < distance && x1 - x2 > -distance) {
                if (y1 - y2 < distance && y1 - y2 > -distance) {
                    printf("Piece %d joined piece %d\n", piece_num, right_p);
                    pieces[piece_num].x_Location = pieces[right_p].x_Location - pieces[piece_num].size;
                    pieces[piece_num].y_Location = pieces[right_p].y_Location;
                }
            }

        }
        if (down_p >= 0) {
            x1 = pieces[piece_num].x_Location;
            x2 = pieces[down_p].x_Location;
            y1 = pieces[piece_num].y_Location;
            y2 = pieces[down_p].y_Location + pieces[down_p].size;
            
            if (x1 - x2 < distance && x1 - x2 > -distance) {
                if (y1 - y2 < distance && y1 - y2 > -distance) {
                    printf("Piece %d joined piece %d\n", piece_num, down_p);
                    pieces[piece_num].x_Location = pieces[down_p].x_Location;
                    pieces[piece_num].y_Location = pieces[down_p].y_Location + pieces[piece_num].size;
                }
            }
        }
        if (left_p >= 0) {
            x1 = pieces[piece_num].x_Location;
            x2 = pieces[left_p].x_Location + pieces[left_p].size;
            y1 = pieces[piece_num].y_Location;
            y2 = pieces[left_p].y_Location;
            
            if (x1 - x2 < distance && x1 - x2 > -distance) {
                if (y1 - y2 < distance && y1 - y2 > -distance) {
                    printf("Piece %d joined piece %d\n", piece_num, left_p);
                    pieces[piece_num].x_Location = pieces[left_p].x_Location + pieces[piece_num].size;
                    pieces[piece_num].y_Location = pieces[left_p].y_Location;
                }
            }
        }
    }
}

void CheckIfSolved() {
    for (int i = 0; i < PIECES_SIZE; i++) {
    }
}

void Render() {
    DrawPuzzlePieces();
}

void MouseListener(int button, int state, int x, int y) {
    y = glutGet(GLUT_WINDOW_HEIGHT)-y; // Fix Mouse Y
    
    if (button == GLUT_LEFT_BUTTON && state == GLUT_DOWN) {
        // Place piece back on board if holding a piece
        if (holdingPiece >= 0) {
            pieces[holdingPiece].x_Location = x - (pieces[holdingPiece].size/2);
            pieces[holdingPiece].y_Location = y - (pieces[holdingPiece].size/2);
            CheckForConnections(holdingPiece);
            holdingPiece = -1;
        }
        else {
            for (int i = 0; i < PIECES_SIZE; i++) {
                if(x >= pieces[i].x_Location && x < pieces[i].x_Location + pieces[i].size) {
                    if (y >= pieces[i].y_Location && y < pieces[i].y_Location + pieces[i].size) {
                        pieces[i].x_Location = x - (pieces[i].size/2);
                        pieces[i].y_Location = y - (pieces[i].size/2);
                        holdingPiece = i;
                        printf("Picked up piece: %d\n", holdingPiece);
                        i = PIECES_SIZE;
                    }
                }
            }
        }
        DrawPuzzlePieces();
    }
}

void MousePosition(int x, int y) {
    y = glutGet(GLUT_WINDOW_HEIGHT)-y; // Fix Mouse Y
     
    if (holdingPiece >= 0) {
        pieces[holdingPiece].x_Location = x - (pieces[holdingPiece].size/2);
        pieces[holdingPiece].y_Location = y - (pieces[holdingPiece].size/2);
        DrawPuzzlePieces();
    }
}

void KeyboardListener(unsigned char theKey, int mouseX, int mouseY) {
    
    switch (theKey) {
        case 32: // space
            DrawPuzzlePieces();
            break;
        case 27: // escape
        case 'q':
        case 'Q':
            exit(0);
            break;
        default:
            break;
    }
}

void WindowResize(int w, int h) {
    DrawPuzzlePieces();
}

int main(int argc, char * argv[]) {
    
    srand((unsigned)time(NULL));
    
    for (int i = 0; i < PIECES_SIZE; i++) {
        Piece piece = { .pieceID = i,
                        .x_Location = rand()%SCREEN_WIDTH,
                        .y_Location = rand()%SCREEN_HEIGHT,
                        .size = PIECE_LENGTH};
        pieces[i] = piece;
    }
    MakeConnections();
    
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_SINGLE | GLUT_RGB);
    
    glutInitWindowSize(SCREEN_WIDTH, SCREEN_HEIGHT);
    glutInitWindowPosition((1920-SCREEN_WIDTH)/2, 0);
    glutCreateWindow("Jigsaw");
    
    glutDisplayFunc(Render);
    glutMouseFunc(MouseListener);
    glutPassiveMotionFunc(MousePosition);
    glutKeyboardFunc(KeyboardListener);
    glutReshapeFunc(WindowResize);
    
    glClearColor(1.0, 1.0, 1.0, 0.0);
    glColor3f(0.0f, 0.0f, 0.0f);
    glPointSize(1.0);
    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glViewport(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    gluOrtho2D(0, SCREEN_WIDTH, 0, SCREEN_HEIGHT);
    
    glutMainLoop();
    
    return 0;
}
