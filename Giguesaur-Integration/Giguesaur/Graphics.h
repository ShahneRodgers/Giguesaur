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
#import "Vision.h"
#import "Debug.h"

#define PIECE_Z 0

#define C_WHITE 1, 1, 1, 1
#define C_CALM 230.0/255.0, 1.0, 1.0, 0.0

@class Network;
@class Vision;

@interface Graphics: UIView {

    CAEAGLLayer* _eaglLayer;
    EAGLContext* _context;
    
    GLuint _colorRenderBuffer;
    GLuint _positionSlot;
    GLuint _colorSlot;
    GLuint _projectionUniform;
    GLuint _modelViewUniform;
    GLuint _depthRenderBuffer;

    GLuint _imageTexture;
    GLuint _texCoordSlot;
    GLuint _textureUniform;

    GLuint _vertexBuffer;
    GLuint _indexBuffer;
}

// Puzzle Variables
@property Piece* pieces;
@property UIImage *puzzleImage;
@property int puzzle_rows;
@property int puzzle_cols;
@property int num_of_pieces;
@property float texture_height;
@property float texture_width;
@property BOOL puzzleStateRecieved;

// Called by Vision
- (void) setupTextureImage: (UIImage *) imageFile;

// Called by Network
- (void) placePiece: (int) pieceID andCoords: (float[3]) coords;
- (void) pickupPiece: (int) pieceID;
- (void) addToHeld: (int) pieceID;
- (void) updateAllPieces: (Piece*) piecesS;

// Setup the Rendering
- (id)initWithFrame: (CGRect) frame
         andNetwork: (Network*) theNetwork;

// Setup the Game
- (void) initWithPuzzle: (UIImage *) puzzleImageS
             withPieces: (Piece *) piecesS
             andNumRows: (int) numRows
             andNumCols: (int) numCols;

@property Network* network;
@property Vision* vision;

@end
