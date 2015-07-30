/*
    File: Graphics.h
    Author: Ashley Manson
 
    OpenGL stuff and interface control.
 */

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <GLKit/GLKit.h>
#import "SimpleMath.h"
#import "Network.h"
#include "Debug.h"

#define C_BLACK {0, 0, 0, 1}
#define C_GRAY {0.5, 0.5, 0.5, 1}
#define C_WHITE {1, 1, 1, 1}
#define C_GOLD {255.0/255.0, 223.0/255.0, 0.0/255.0, 1}
#define C_TRANS {0, 0, 0, 0}

#define BOARD_WIDTH 1024
#define BOARD_HEIGHT 768

@class Network;

@interface Graphics: UIView {
    
    Piece *pieces;
    int puzzle_rows;
    int puzzle_cols;
    int num_of_pieces;
    int texture_height;
    int texture_width;
    
    CAEAGLLayer* _eaglLayer;
    EAGLContext* _context;
    SimpleMath* simpleMath;
    
    GLuint _colorRenderBuffer;
    GLuint _positionSlot;
    GLuint _colorSlot;
    GLuint _projectionUniform;
    GLuint _modelViewUniform;
    GLuint _depthRenderBuffer;

    GLKMatrix4 _projectionMatrix;
    GLKMatrix4 _modelViewMatrix;

    GLuint _puzzleTexture;
    GLuint _backgroundTexture;
    GLuint _texCoordSlot;
    GLuint _textureUniform;

    GLuint _vertexBuffer;
    GLuint _indexBuffer;
    GLuint _vertexBuffer2;
    GLuint _indexBuffer2;
    
}

- (id)initWithFrame:(CGRect)frame andNetwork:(Network*) theNetwork;
- (void) placePiece: (int) pieceID andCoord: (int[3]) coord;
- (void) pickupPiece: (int) pieceID;
//- (void) bringSublayerToFront;
//- (void) checkThenSnapPiece: (int) pieceID;
//- (void) checkThenCloseEdge: (int) pieceID;
//- (void) openClosedEdges: (int) pieceID;
- (void) initPuzzle: (UIImage *)data withPieces:(Piece*)in_pieces
         andNumRows: (int) rows
         andNumCols: (int) cols;

@property Network* network;
@property void* pieces;

@end
