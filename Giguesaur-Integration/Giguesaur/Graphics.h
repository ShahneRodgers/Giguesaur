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

#define PI 3.141592653
#define degToRad(DEG) (float)(DEG * PI / 180.0)

#define PIECE_Z 0
#define HOLDING_Z 0.01

#define C_BLACK {0, 0, 0, 1}
#define C_GRAY {0.5, 0.5, 0.5, 1}
#define C_WHITE {1, 1, 1, 1}
#define C_GOLD {255.0/255.0, 223.0/255.0, 0.0/255.0, 1}
#define C_TRANS {0, 0, 0, 0}

#define BOARD_WIDTH 1024
#define BOARD_HEIGHT 768

typedef enum {USE_BACKGROUND, USE_PUZZLE} use_image;

@class Network;

@interface Graphics: UIView {

    // Puzzle Variables
    Piece* _pieces;
    UIImage *_puzzleImage;
    int puzzle_rows;
    int puzzle_cols;
    int num_of_pieces;
    int texture_height;
    int texture_width;

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

    GLuint _puzzleTexture;
    GLuint _backgroundTexture;
    GLuint _texCoordSlot;
    GLuint _textureUniform;

    GLuint _vertexBuffer;
    GLuint _indexBuffer;
    GLuint _vertexBuffer2;
    GLuint _indexBuffer2;
    
}

// Called by Vision
- (void) visionBackgroundRender: (UIImage *) imageFile;

// Called by Network
- (void) placePiece: (int) pieceID andCoords: (int[3]) coords;
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
