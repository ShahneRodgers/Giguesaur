/*
 File: Graphics.m
 Author: Ashley Manson
 
 Does all the OpenGL magic and rendering, and handles the interface.
 Note: iPad aspect ratio is 4:3
 */

#import "Graphics.h"

#define PIECE_Z 0
#define HOLDING_Z 0.01

/***** Global Varibles for the Puzzle *****/
Piece pieces[NUM_OF_PIECES];
int holdingPiece = -1;
int reset = 0;

typedef struct {
    float Position[3];
    float Colour[4];
    float TexCoord[2];
} Vertex;

const Vertex DefaultPiece[] = {
    {{SIDE_HALF, -SIDE_HALF, PIECE_Z}, C_BLACK, {1, 0}},
    {{SIDE_HALF, SIDE_HALF, PIECE_Z}, C_BLACK, {1, 1}},
    {{-SIDE_HALF, SIDE_HALF, PIECE_Z}, C_BLACK, {0, 1}},
    {{-SIDE_HALF, -SIDE_HALF, PIECE_Z}, C_BLACK, {0, 0}}
};

const Vertex BackgroundVertices[] = {
    {{BOARD_WIDTH, 0, 0}, C_WHITE, {1, 1}},
    {{BOARD_WIDTH, BOARD_HIEGHT, 0}, C_WHITE, {1, 0}},
    {{0, BOARD_HIEGHT, 0}, C_WHITE, {0, 0}},
    {{0, 0, 0}, C_WHITE, {0, 1}}
};

const GLubyte Indices[] = {
    0, 1, 2,
    2, 3, 0
};

const GLubyte Indices2[] = {
    1, 0, 2, 3
};

@implementation Graphics

/***** OpenGL Setup Code *****/
+ (Class) layerClass {
    return [CAEAGLLayer class];
}

- (void) setupLayer {
    _eaglLayer = (CAEAGLLayer*) self.layer;
    _eaglLayer.opaque = YES;
}

- (void) setupContext {
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    _context = [[EAGLContext alloc] initWithAPI:api];
    if (!_context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    
    if (![EAGLContext setCurrentContext:_context]) {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
}

- (void) setupRenderBuffer {
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
}

- (void) setupDepthBuffer {
    glGenRenderbuffers(1, &_depthRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, self.frame.size.width, self.frame.size.height);
}

- (void) setupFrameBuffer {
    GLuint framebuffer;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, _colorRenderBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderBuffer);
}

- (GLuint) compileShader: (NSString*) shaderName withType: (GLenum) shaderType {
    
    NSString* shaderPath = [[NSBundle mainBundle] pathForResource:shaderName
                                                           ofType:@"glsl"];
    NSError* error;
    NSString* shaderString = [NSString stringWithContentsOfFile:shaderPath
                                                       encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSLog(@"Error loading shader: %@", error.localizedDescription);
        exit(1);
    }
    
    GLuint shaderHandle = glCreateShader(shaderType);
    
    const char * shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = (int)[shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    glCompileShader(shaderHandle);
    
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    return shaderHandle;
}

- (void) compileShaders {
    
    GLuint vertexShader = [self compileShader:@"SimpleVertex" withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:@"SimpleFragment" withType:GL_FRAGMENT_SHADER];
    
    GLuint programHandle = glCreateProgram();
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    glLinkProgram(programHandle);
    
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    glUseProgram(programHandle);
    
    _positionSlot = glGetAttribLocation(programHandle, "Position");
    _colorSlot = glGetAttribLocation(programHandle, "SourceColor");
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_colorSlot);
    _projectionUniform = glGetUniformLocation(programHandle, "Projection");
    _modelViewUniform = glGetUniformLocation(programHandle, "Modelview");
    _texCoordSlot = glGetAttribLocation(programHandle, "TexCoordIn");
    glEnableVertexAttribArray(_texCoordSlot);
    _textureUniform = glGetUniformLocation(programHandle, "Texture");
}

- (void) setupVBOs {

    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(DefaultPiece), DefaultPiece, GL_STATIC_DRAW);

    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);

    glGenBuffers(1, &_vertexBuffer2);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer2);
    glBufferData(GL_ARRAY_BUFFER, sizeof(BackgroundVertices), BackgroundVertices, GL_STATIC_DRAW);

    glGenBuffers(1, &_indexBuffer2);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer2);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices2), Indices2, GL_STATIC_DRAW);

}

- (GLuint) setupTexture: (NSString *) fileName {
    
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }
    
    int width = (int)CGImageGetWidth(spriteImage);
    int height = (int)CGImageGetHeight(spriteImage);
    
    GLubyte *spriteData = (GLubyte *)calloc(width*height*4, sizeof(GLubyte));
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4, CGImageGetColorSpace(spriteImage), (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    
    GLuint texName;
    glGenTextures(1, &texName);
    glBindTexture(GL_TEXTURE_2D, texName);

    // use linear filetring
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    // clamp to edge
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    free(spriteData);
    return texName;
}

// Move a piece if it is in range to snap to another piece
- (void) checkThenSnapPiece: (int) pieceID {
    
    CGPoint newPoints;
    int upID = pieces[pieceID].neighbourPiece.up_piece;
    int downID = pieces[pieceID].neighbourPiece.down_piece;
    int leftID = pieces[pieceID].neighbourPiece.left_piece;
    int rightID = pieces[pieceID].neighbourPiece.right_piece;
    
    if (upID >= 0 &&
        [simpleMath shouldPieceSnap:pieces[pieceID]
                     withOtherPiece:pieces[upID]
                          whichSide:P_UP
                 distanceBeforeSnap:DISTANCE_BEFORE_SNAP]) {
            
            newPoints = [simpleMath newCoordinates:pieces[upID] whichSide:P_UP];
            pieces[pieceID].x_location = newPoints.x;
            pieces[pieceID].y_location = newPoints.y;
            pieces[pieceID].rotation = pieces[upID].rotation;
            
            DEBUG_PRINT_2("checkThenSnapPiece :: Moved piece %i to (%.2f, %.2f)\n",
                        pieceID, newPoints.x, newPoints.y);
        }
    
    if (downID >= 0 &&
        [simpleMath shouldPieceSnap:pieces[pieceID]
                     withOtherPiece:pieces[downID]
                          whichSide:P_DOWN
                 distanceBeforeSnap:DISTANCE_BEFORE_SNAP]) {
            
            newPoints = [simpleMath newCoordinates:pieces[downID] whichSide:P_DOWN];
            pieces[pieceID].x_location = newPoints.x;
            pieces[pieceID].y_location = newPoints.y;
            pieces[pieceID].rotation = pieces[downID].rotation;
            
            DEBUG_PRINT_2("checkThenSnapPiece :: Moved piece %i to (%.2f, %.2f)\n",
                        pieceID, newPoints.x, newPoints.y);
        }
    
    if (leftID >= 0 &&
        [simpleMath shouldPieceSnap:pieces[pieceID]
                     withOtherPiece:pieces[leftID]
                          whichSide:P_LEFT
                 distanceBeforeSnap:DISTANCE_BEFORE_SNAP]) {
            
            newPoints = [simpleMath newCoordinates:pieces[leftID] whichSide:P_LEFT];
            pieces[pieceID].x_location = newPoints.x;
            pieces[pieceID].y_location = newPoints.y;
            pieces[pieceID].rotation = pieces[leftID].rotation;
            
            DEBUG_PRINT_2("checkThenSnapPiece :: Moved piece %i to (%.2f, %.2f)\n",
                        pieceID, newPoints.x, newPoints.y);
            
        }
    
    if (rightID >= 0 &&
        [simpleMath shouldPieceSnap:pieces[pieceID]
                     withOtherPiece:pieces[rightID]
                          whichSide:P_RIGHT
                 distanceBeforeSnap:DISTANCE_BEFORE_SNAP]) {
            
            newPoints = [simpleMath newCoordinates:pieces[rightID] whichSide: P_RIGHT];
            pieces[pieceID].x_location = newPoints.x;
            pieces[pieceID].y_location = newPoints.y;
            pieces[pieceID].rotation = pieces[rightID].rotation;
            
            DEBUG_PRINT_2("checkThenSnapPiece :: Moved piece %i to (%.2f, %.2f)\n",
                        pieceID, newPoints.x, newPoints.y);
        }
}

// Check if a piece joined its neighbours then closes their edges
- (void) checkThenCloseEdge: (int) pieceID {
    
    int upID = pieces[pieceID].neighbourPiece.up_piece;
    int downID = pieces[pieceID].neighbourPiece.down_piece;
    int leftID = pieces[pieceID].neighbourPiece.left_piece;
    int rightID = pieces[pieceID].neighbourPiece.right_piece;
    
    if (upID >= 0 &&
        [simpleMath didPieceConnect:pieces[pieceID]
                     withOtherPiece:pieces[upID]
                          whichSide:P_UP]) {
        
            pieces[pieceID].openEdge.up_open = isClosed;
            pieces[upID].openEdge.down_open = isClosed;
            
            DEBUG_PRINT_2("checkThenCloseEdge :: Piece %i joined piece %i\n",
                        pieceID, upID);
    }
    
    if (downID >= 0 &&
        [simpleMath didPieceConnect:pieces[pieceID]
                     withOtherPiece:pieces[downID]
                          whichSide:P_DOWN]) {
        
            pieces[pieceID].openEdge.down_open = isClosed;
            pieces[downID].openEdge.up_open = isClosed;
            
            DEBUG_PRINT_2("checkThenCloseEdge :: Piece %i joined piece %i\n",
                        pieceID, downID);
    }
    
    if (leftID >= 0 &&
        [simpleMath didPieceConnect:pieces[pieceID]
                     withOtherPiece:pieces[leftID]
                          whichSide:P_LEFT]) {
        
            pieces[pieceID].openEdge.left_open = isClosed;
            pieces[leftID].openEdge.right_open = isClosed;
            
            DEBUG_PRINT_2("checkThenCloseEdge :: Piece %i joined piece %i\n",
                        pieceID, leftID);
    }
    
    if (rightID >= 0 &&
        [simpleMath didPieceConnect:pieces[pieceID]
                     withOtherPiece:pieces[rightID]
                          whichSide:P_RIGHT]) {
        
            pieces[pieceID].openEdge.right_open = isClosed;
            pieces[rightID].openEdge.left_open = isClosed;
            
            DEBUG_PRINT_2("checkThenCloseEdge :: Piece %i joined piece %i\n",
                        pieceID, rightID);
    }
}

// Open closed edges of pickedup piece and neighbouring edges
- (void) openClosedEdges: (int) pieceID {
    
    int upID = pieces[pieceID].neighbourPiece.up_piece;
    int downID = pieces[pieceID].neighbourPiece.down_piece;
    int leftID = pieces[pieceID].neighbourPiece.left_piece;
    int rightID = pieces[pieceID].neighbourPiece.right_piece;
    
    if (upID >= 0) {
        pieces[pieceID].openEdge.up_open = isOpen;
        pieces[upID].openEdge.down_open = isOpen;
        
        DEBUG_PRINT_2("openClosedEdges :: Piece %i up_open = isOpen\n"
                    "                   Piece %i down_open = isOpen\n",
                    pieceID, upID);
    }
    if (downID >= 0) {
        pieces[pieceID].openEdge.down_open = isOpen;
        pieces[downID].openEdge.up_open = isOpen;
        
        DEBUG_PRINT_2("openClosedEdges :: Piece %i down_open = isOpen\n"
                    "                   Piece %i up_open = isOpen\n",
                    pieceID, downID);
    }
    if (leftID >= 0) {
        pieces[pieceID].openEdge.left_open = isOpen;
        pieces[leftID].openEdge.right_open = isOpen;
        
        DEBUG_PRINT_2("openClosedEdges :: Piece %i left_open = isOpen\n"
                    "                   Piece %i right_open = isOpen\n",
                    pieceID, leftID);
    }
    if (rightID >= 0) {
        pieces[pieceID].openEdge.right_open = isOpen;
        pieces[rightID].openEdge.left_open = isOpen;
        
        DEBUG_PRINT_2("openClosedEdges :: Piece %i right_open = isOpen\n"
                    "                   Piece %i left_open = isOpen\n",
                    pieceID, rightID);
    }
}

/***** Screen Touch *****/
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    
    // Get the specific point that was touched
    CGPoint point = [touch locationInView:touch.view];

    // Convert Screen to World Coordinates (Orthagraphic Projection)
    float new_x = 2.0 * point.x / BOARD_WIDTH - 1;
    float new_y = -2.0 * point.y / BOARD_HIEGHT + 1;
    bool success;

    GLKMatrix4 viewProjectionInverse = GLKMatrix4Invert(GLKMatrix4Multiply(_projectionMatrix, _modelViewMatrix), &success);
    GLKVector3 newPoints = GLKVector3Make(new_x, new_y, 0);
    GLKVector3 result = GLKMatrix4MultiplyVector3(viewProjectionInverse, newPoints);

    point.x = result.v[0] + (BOARD_WIDTH / 2);
    point.y = result.v[1] + (BOARD_HIEGHT / 2);

    DEBUG_PRINT_2("touchesBegan :: Converted [x,y] = [%.2f,%.2f]\n", point.x, point.y);
    
    if (holdingPiece >= 0) {
        DEBUG_PRINT_1("touchesBegan :: Placed piece %i\n", holdingPiece);
        pieces[holdingPiece].x_location = point.x;
        pieces[holdingPiece].y_location = point.y;
        [self checkThenSnapPiece:holdingPiece];
        [self checkThenCloseEdge:holdingPiece];
        holdingPiece = -1;
        reset = 0;
    }
    else {
        for (int i = 0; i < NUM_OF_PIECES; i++) {
            if(point.x >= pieces[i].x_location - SIDE_HALF && point.x < pieces[i].x_location + SIDE_HALF) {
                if (point.y >= pieces[i].y_location - SIDE_HALF && point.y < pieces[i].y_location + SIDE_HALF) {
                    DEBUG_PRINT_1("touchesBegan :: Picked up piece %i\n", i);
                    [self openClosedEdges:i];
                    holdingPiece = i;
                    i = NUM_OF_PIECES;
                    reset = 0;
                }
            }
        }
    }
    DEBUG_PRINT_1("checkIfSolved :: %s\n",
                (checkIfSolved(pieces) ? "Solved" : "Not Solved"));
    
    if (holdingPiece < 0 && point.x < 20 && point.y < 20) {
        if (reset >= 10) {
            generatePieces(pieces);
            reset = 0;
            DEBUG_SAY("Puzzle Reset!\n");
        }
        else {
            reset++;
            DEBUG_PRINT_1("touchesBegan :: Reset Counter = %i\n", reset);
        }
    }
    
    [self render];
}

/***** DRAW CODE *****/
- (void) render {//:(CADisplayLink*)displayLink {
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);

    // Clear the screen
    glClearColor(230.0/255.0, 1.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    
    // Sort out projection Matrix
    GLKMatrix4 projection = GLKMatrix4MakeOrtho(0, BOARD_WIDTH, 0, BOARD_HIEGHT, 0.1, 1000);
    //float h = 4.0 * BOARD_WIDTH / BOARD_HIEGHT;
    //GLKMatrix4 projection = GLKMatrix4MakeFrustum(-2, 2, -h/2, h/2, 0.1, 1000);

    _projectionMatrix = projection;
    glUniformMatrix4fv(_projectionUniform, 1, 0, projection.m);
    
    // Sort out Model-View Matrix
    GLKMatrix4 translation = GLKMatrix4MakeTranslation(0,0,-1);
    //GLKMatrix4 translation = GLKMatrix4MakeTranslation(-BOARD_WIDTH/2,-BOARD_HIEGHT/2,-25);
    GLKMatrix4 rotation = GLKMatrix4MakeRotation(degToRad(0), 0, 0, 1);
    GLKMatrix4 modelView = GLKMatrix4Multiply(translation, rotation);
    
    _modelViewMatrix = modelView;
    glUniformMatrix4fv(_modelViewUniform, 1, 0, modelView.m);
    
    glViewport(0, 0, BOARD_WIDTH, BOARD_HIEGHT);

    // Draw Default Piece
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(DefaultPiece), DefaultPiece, GL_STATIC_DRAW);

    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float)*3));
    glVertexAttribPointer(_texCoordSlot, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float) * 7));

    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);

    // Draw each Puzzle Piece
    for (int i = 0; i < NUM_OF_PIECES; i++) {
        // set row and col to get the sub-section of the texture
        int row = 0;
        int col = 0;
        int index = 0;
        while (index != pieces[i].piece_id) {
            col++;
            index++;
            if (col >= NUM_OF_COLS) {
                col = 0;
                row++;
            }
        }

        Vertex NewPiece[4];
        // Piece on the board
        if (i != holdingPiece) {
            NewPiece[0] = (Vertex) {
                {pieces[i].x_location + SIDE_HALF, pieces[i].y_location - SIDE_HALF, PIECE_Z},
                C_WHITE,
                {TEXTURE_WIDTH * (col+1), TEXTURE_HEIGHT * (row + 1)}
            };
            NewPiece[1] = (Vertex) {
                {pieces[i].x_location + SIDE_HALF, pieces[i].y_location + SIDE_HALF, PIECE_Z},
                C_WHITE,
                {TEXTURE_WIDTH * (col+1), TEXTURE_HEIGHT * row}
            };
            NewPiece[2] = (Vertex) {
                {pieces[i].x_location - SIDE_HALF, pieces[i].y_location + SIDE_HALF, PIECE_Z},
                C_WHITE,
                {TEXTURE_WIDTH * col, TEXTURE_HEIGHT * row}
            };
            NewPiece[3] = (Vertex) {
                {pieces[i].x_location - SIDE_HALF, pieces[i].y_location - SIDE_HALF, PIECE_Z},
                C_WHITE,
                {TEXTURE_WIDTH * col, TEXTURE_HEIGHT * (row+1)}
            };
        }
        // Piece being held
        else {
            NewPiece[0] = (Vertex) {
                {SIDE_LENGTH*2+10, 10, HOLDING_Z},
                C_GOLD,
                {TEXTURE_WIDTH * (col+1), TEXTURE_HEIGHT * (row + 1)}
            };
            NewPiece[1] = (Vertex) {
                {SIDE_LENGTH*2+10, SIDE_LENGTH*2+10, HOLDING_Z},
                C_GOLD,
                {TEXTURE_WIDTH * (col+1), TEXTURE_HEIGHT * row}
            };
            NewPiece[2] = (Vertex) {
                {10, SIDE_LENGTH*2+10, HOLDING_Z},
                C_GOLD,
                {TEXTURE_WIDTH * col, TEXTURE_HEIGHT * row}
            };
            NewPiece[3] = (Vertex) {
                {10, 10, HOLDING_Z},
                C_GOLD,
                {TEXTURE_WIDTH * col, TEXTURE_HEIGHT * (row+1)}
            };
        }

        glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
        glBufferData(GL_ARRAY_BUFFER, sizeof(NewPiece), NewPiece, GL_STATIC_DRAW);
        
        glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
        glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float)*3));
        glVertexAttribPointer(_texCoordSlot, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float) * 7));

        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, _puzzleTexture);
        glUniform1i(_textureUniform, 0);
        
        glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
    }

    // Set Orthographic Projection for Background Image
    projection = GLKMatrix4MakeOrtho(0, BOARD_WIDTH, 0, BOARD_HIEGHT, 0.1, 1000);
    glUniformMatrix4fv(_projectionUniform, 1, 0, projection.m);

    // Send Background Image to the back
    modelView = GLKMatrix4MakeTranslation(0, 0, -999);
    glUniformMatrix4fv(_modelViewUniform, 1, 0, modelView.m);

    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer2);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer2);
    glBindTexture(GL_TEXTURE_2D, _backgroundTexture);

    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float)*3));
    glVertexAttribPointer(_texCoordSlot, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float) * 7));

    glDrawElements(GL_TRIANGLE_STRIP, sizeof(Indices2)/sizeof(Indices2[0]), GL_UNSIGNED_BYTE, 0);

    // Flush everything to the screen
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

/*
// Renders the game to the screens refresh rate
- (void)setupDisplayLink {
    CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}
*/

/* "Main" for the frame */
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Call all the OpenGL setup code
        [self setupLayer];
        [self setupContext];
        [self setupDepthBuffer];
        [self setupRenderBuffer];
        [self setupFrameBuffer];
        [self compileShaders];
        [self setupVBOs];
        //[self setupDisplayLink];
        _puzzleTexture = [self setupTexture:@"puppy.png"];
        _backgroundTexture = [self setupTexture:@"background.jpg"];
        simpleMath = [[SimpleMath alloc] init];
        generatePieces(pieces);
        [self render];
    }
    return self;
}

@end
