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
#import "Giguesaur/Piece.h"
#import "Network.h"
#import "Debug.h"

#define PIECE_Z -10

#define C_WHITE 1, 1, 1, 1
#define C_CALM 230.0/255.0, 1.0, 1.0, 0.0

@class Network;

@interface Graphics: UIView {

    // Puzzle Variables
    Piece* _pieces;
    UIImage *_puzzleImage;
    int puzzle_rows;
    int puzzle_cols;
    int num_of_pieces;
    float texture_height;
    float texture_width;

    CAEAGLLayer* _eaglLayer;
    EAGLContext* _context;
    
    GLuint _colorRenderBuffer;
    GLuint _positionSlot;
    GLuint _colorSlot;
    GLuint _projectionUniform;
    GLuint _modelViewUniform;
    GLuint _depthRenderBuffer;

    GLKMatrix4 _projectionMatrix;
    GLKMatrix4 _modelViewMatrix;

    GLuint _imageTexture;
    GLuint _texCoordSlot;
    GLuint _textureUniform;

    GLuint _vertexBuffer;
    GLuint _indexBuffer;
    
}

// Called by Vision
- (void) visionImageRender: (UIImage *) imageFile;

// Called by Network
- (void) placePiece: (int) pieceID andCoords: (float[3]) coords;
- (void) pickupPiece: (int) pieceID;
- (void) addToHeld: (int) pieceID;

// Setup the Rendering
- (id)initWithFrame: (CGRect) frame
         andNetwork: (Network*) theNetwork;

// Setup the Game
- (void) initWithPuzzle: (UIImage *) puzzleImage
             withPieces: (Piece *) pieces
             andNumRows: (int) numRows
             andNumCols: (int) numCols;

@property Network* network;
@property void* pieces;

@end

typedef struct {
    float Postion[3];
    float TexCoord[2];
 } PieceCoords;

extern PieceCoords pieceCoords[4][4];
