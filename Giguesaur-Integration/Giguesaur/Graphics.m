/*
 File: Graphics.m
 Author: Ashley Manson
 
 Does all the OpenGL magic and rendering, and handles the interface.
 Note: iPad aspect ratio is 4:3
 */

#import "Graphics.h"

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
    {{BOARD_WIDTH, BOARD_HEIGHT, 0}, C_WHITE, {1, 0}},
    {{0, BOARD_HEIGHT, 0}, C_WHITE, {0, 0}},
    {{0, 0, 0}, C_WHITE, {0, 1}}
};

const GLubyte PieceIndices[] = {
    0, 1, 2,
    2, 3, 0
};

const GLubyte BackgroundIndices[] = {
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
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16,
                          self.frame.size.width, self.frame.size.height);
}

- (void) setupFrameBuffer {
    GLuint framebuffer;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, _colorRenderBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
                              GL_RENDERBUFFER, _depthRenderBuffer);
}

- (GLuint) compileShader: (NSString*) shaderName withType: (GLenum) shaderType {
    
    NSString* shaderPath = [[NSBundle mainBundle] pathForResource:shaderName
                                                           ofType:@"glsl"];
    NSError* error;
    NSString* shaderString = [NSString stringWithContentsOfFile:shaderPath
                                                       encoding:NSUTF8StringEncoding
                                                          error:&error];
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
    
    GLuint vertexShader = [self compileShader:@"SimpleVertex"
                                     withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:@"SimpleFragment"
                                       withType:GL_FRAGMENT_SHADER];
    
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
    glBufferData(GL_ARRAY_BUFFER, sizeof(DefaultPiece),
                 DefaultPiece, GL_STATIC_DRAW);

    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(PieceIndices),
                 PieceIndices, GL_STATIC_DRAW);

    glGenBuffers(1, &_vertexBuffer2);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer2);
    glBufferData(GL_ARRAY_BUFFER, sizeof(BackgroundVertices),
                 BackgroundVertices, GL_STATIC_DRAW);

    glGenBuffers(1, &_indexBuffer2);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer2);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(BackgroundIndices),
                 BackgroundIndices, GL_STATIC_DRAW);
}

- (GLuint) setupTexturePuzzle: (UIImage *) imageFile {

    DEBUG_SAY(1, "setup texture puzzle\n");
    
    CGImageRef spriteImage = imageFile.CGImage;

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

- (void) setupTexture: (UIImage *) imageFile {

    CGImageRef spriteImage = imageFile.CGImage;

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

    _backgroundTexture = texName;

    [self render];

    glDeleteTextures(1, &texName);
}

/* Method called by vision to manipulate background */
- (void) visionBackgroundRender: (UIImage *) imageFile {
    [self setupTexture:imageFile];
}

/* Methods called by server to manipulate the pieces on the client */
- (void) placePiece: (int) pieceID andCoords: (int[3]) coords {

    _pieces[pieceID].x_location = coords[0];
    _pieces[pieceID].y_location = coords[1];
    _pieces[pieceID].rotation = coords[2];
    _pieces[pieceID].held = P_FALSE;

    if (holdingPiece == pieceID) holdingPiece = -1;

    [self render];
}

- (void) pickupPiece: (int) pieceID {

    _pieces[pieceID].held = P_TRUE;

    holdingPiece = pieceID;

    [self render];
}

- (void) addToHeld: (int) pieceID {

    _pieces[pieceID].held = P_TRUE;

    [self render];
}

/***** SCREEN TOUCH *****/
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {

    UITouch *touch = [[event allTouches] anyObject];
    
    // Get the specific point that was touched
    CGPoint point = [touch locationInView:touch.view];

    // Convert Screen to World Coordinates (Orthagraphic Projection)
    float new_x = 2.0 * point.x / self.frame.size.width - 1;
    float new_y = -2.0 * point.y / self.frame.size.height + 1;
    bool success;

    GLKMatrix4 viewProjectionInverse = GLKMatrix4Invert(GLKMatrix4Multiply(_projectionMatrix, _modelViewMatrix), &success);
    GLKVector3 newPoints = GLKVector3Make(new_x, new_y, 0);
    GLKVector3 result = GLKMatrix4MultiplyVector3(viewProjectionInverse, newPoints);

    point.x = result.v[0] + (self.frame.size.width / 2);
    point.y = result.v[1] + (self.frame.size.height / 2);

    DEBUG_PRINT(2,"touchesBegan :: Converted [x,y] = [%.2f,%.2f]\n", point.x, point.y);
    
    // Ask server to place piece
    if (holdingPiece >= 0) {
        [self.network droppedPiece:point.x WithY:point.y WithRotation:0]; //BUG
    }
    else {
        for (int i = 0; i < num_of_pieces; i++) {
            if(point.x >= _pieces[i].x_location - SIDE_HALF && point.x < _pieces[i].x_location + SIDE_HALF) {
                // Ask server to pickup a piece
                if (point.y >= _pieces[i].y_location - SIDE_HALF && point.y < _pieces[i].y_location + SIDE_HALF) {
                    [self.network requestPiece:i];
                    i = num_of_pieces;
                }
            }
        }
    }
    
}

/***** DRAW CODE *****/
- (void) render {

    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);

    glClearColor(230.0/255.0, 1.0, 1.0, 0.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    
    // Sort out projection Matrix
    GLKMatrix4 projection = GLKMatrix4MakeOrtho(0, self.frame.size.width, 0, self.frame.size.height, 0.1, 1000);
    //float h = 4.0 * BOARD_WIDTH / BOARD_HEIGHT;
    //GLKMatrix4 projection = GLKMatrix4MakeFrustum(-2, 2, -h/2, h/2, 0.1, 1000);

    _projectionMatrix = projection;
    glUniformMatrix4fv(_projectionUniform, 1, 0, projection.m);
    
    // Sort out Model-View Matrix
    GLKMatrix4 translation = GLKMatrix4MakeTranslation(0,0,-1);
    //GLKMatrix4 translation = GLKMatrix4MakeTranslation(-BOARD_WIDTH/2,-BOARD_HEIGHT/2,-25);
    GLKMatrix4 rotation = GLKMatrix4MakeRotation(degToRad(0), 0, 0, 1);
    GLKMatrix4 modelView = GLKMatrix4Multiply(translation, rotation);
    
    _modelViewMatrix = modelView;
    glUniformMatrix4fv(_modelViewUniform, 1, 0, modelView.m);

    glViewport(0, 0, self.frame.size.width, self.frame.size.height);

    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(DefaultPiece), DefaultPiece, GL_STATIC_DRAW);

    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float)*3));
    glVertexAttribPointer(_texCoordSlot, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float) * 7));

    glDrawElements(GL_TRIANGLES, sizeof(PieceIndices)/sizeof(PieceIndices[0]), GL_UNSIGNED_BYTE, 0);

    // Draw each Puzzle Piece
    for (int i = 0; i < num_of_pieces; i++) {
        // set row and col to get the sub-section of the texture
        int row = 0;
        int col = 0;
        int index = 0;
        while (index != i) {
            col++;
            index++;
            if (col >= puzzle_cols) {
                col = 0;
                row++;
            }
        }

        Vertex NewPiece[4];
        // Piece on the board
        if (_pieces[i].held == P_FALSE) {
            NewPiece[0] = (Vertex) {
                {_pieces[i].x_location + SIDE_HALF, _pieces[i].y_location - SIDE_HALF, PIECE_Z},
                C_WHITE,
                {texture_width * (col+1), texture_height * (row + 1)}
            };
            NewPiece[1] = (Vertex) {
                {_pieces[i].x_location + SIDE_HALF, _pieces[i].y_location + SIDE_HALF, PIECE_Z},
                C_WHITE,
                {texture_width * (col+1), texture_height * row}
            };
            NewPiece[2] = (Vertex) {
                {_pieces[i].x_location - SIDE_HALF, _pieces[i].y_location + SIDE_HALF, PIECE_Z},
                C_WHITE,
                {texture_width * col, texture_height * row}
            };
            NewPiece[3] = (Vertex) {
                {_pieces[i].x_location - SIDE_HALF, _pieces[i].y_location - SIDE_HALF, PIECE_Z},
                C_WHITE,
                {texture_width * col, texture_height * (row+1)}
            };
        }
        // Piece being held
        else if (i == holdingPiece) {
            NewPiece[0] = (Vertex) {
                {SIDE_LENGTH*2+10, 10, HOLDING_Z},
                C_GOLD,
                {texture_width * (col+1), texture_height * (row + 1)}
            };
            NewPiece[1] = (Vertex) {
                {SIDE_LENGTH*2+10, SIDE_LENGTH*2+10, HOLDING_Z},
                C_GOLD,
                {texture_width * (col+1), texture_height * row}
            };
            NewPiece[2] = (Vertex) {
                {10, SIDE_LENGTH*2+10, HOLDING_Z},
                C_GOLD,
                {texture_width * col, texture_height * row}
            };
            NewPiece[3] = (Vertex) {
                {10, 10, HOLDING_Z},
                C_GOLD,
                {texture_width * col, texture_height * (row+1)}
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
        
        glDrawElements(GL_TRIANGLES, sizeof(PieceIndices)/sizeof(PieceIndices[0]), GL_UNSIGNED_BYTE, 0);
    }

    // Set Orthographic Projection for Background Image
    projection = GLKMatrix4MakeOrtho(0, self.frame.size.width, 0, self.frame.size.height, 0.1, 1000);
    glUniformMatrix4fv(_projectionUniform, 1, 0, projection.m);

    // Send Background Image to the back
    modelView = GLKMatrix4MakeTranslation(0, 0, -999);
    glUniformMatrix4fv(_modelViewUniform, 1, 0, modelView.m);

    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer2);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer2);

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _backgroundTexture);
    glUniform1i(_textureUniform, 0);

    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float)*3));
    glVertexAttribPointer(_texCoordSlot, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float) * 7));

    glDrawElements(GL_TRIANGLE_STRIP, sizeof(BackgroundIndices)/sizeof(BackgroundIndices[0]), GL_UNSIGNED_BYTE, 0);

    // Flush everything to the screen
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

- (id) initWithFrame: (CGRect) frame andNetwork: (Network*) theNetwork {
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

        self.network = theNetwork;
        self.network.graphics = self;

        [self render];
    }
    return self;
}

- (void) initWithPuzzle: (UIImage *) puzzleImage
             withPieces: (Piece *) pieces
             andNumRows: (int) numRows
             andNumCols: (int) numCols {

    _pieces = pieces;
    //_puzzleImage = [UIImage imageNamed:@"puppy.png"];//puzzleImage;
    puzzle_rows = numRows;
    puzzle_cols = numCols;
    num_of_pieces = numRows * numCols;
    texture_height = 1.0/num_of_pieces;
    texture_width = 1.0/num_of_pieces;
    holdingPiece = -1;
    _puzzleTexture = [self setupTexturePuzzle:puzzleImage];

    [self render];
}

@end
