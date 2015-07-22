/*
    File: OpenGLView.h
    Author: Ashley Manson
 
    OpenGL stuff and interface control.
 */

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <GLKit/GLKit.h>
#import "SimpleMath.h"
#import "Giguesaur/Puzzle.h"
#include "Debug.h"

#define C_BLACK {0, 0, 0, 1}
#define C_GRAY {0.5, 0.5, 0.5, 1}
#define C_WHITE {1, 1, 1, 1}
#define C_GOLD {255.0/255.0, 223.0/255.0, 0.0/255.0, 1}

@interface OpenGLView : UIView {
    
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

@end
