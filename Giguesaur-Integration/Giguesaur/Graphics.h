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

#define C_BLACK {0, 0, 0, 1}
#define C_GRAY {0.5, 0.5, 0.5, 1}
#define C_WHITE {1, 1, 1, 1}
#define C_GOLD {255.0/255.0, 223.0/255.0, 0.0/255.0, 1}
#define C_TRANS {0, 0, 0, 0}

#define BOARD_WIDTH 1024
#define BOARD_HEIGHT 768

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

    // Puzzle State
    int holdingPiece;
    NSMutableArray* heldPieces;

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

- (void) placePiece: (int) pieceID
           andCoord: (int[3]) coord;

- (void) pickupPiece: (int) pieceID;

- (void) visionBackgroundRender:(UIImage *)imageFile;

- (id)initWithFrame:(CGRect)frame
         andNetwork:(Network*) theNetwork;

- (void) initPuzzle: (UIImage *) puzzleImage
         withPieces: (Piece *) pieces
         andNumRows: (int) numRows
         andNumCols: (int) numCols;

@property Network* network;
@property void* pieces;

@end
