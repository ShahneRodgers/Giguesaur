/*
 File: Graphics.m
 Author: Ashley Manson
 
 Displayes an image to the screen using OpenGL, and handles the interface.
 Note: iPad aspect ratio is 4:3 (1024:768)
 */

#import "Graphics.h"

// Puzzle State
CGPoint screenCentre;

typedef struct {
    float Position[3];
    float Colour[4];
    float TexCoord[2];
} Vertex;

Vertex ImageVertices[4];
const GLubyte ImageIndices[] = {
    1, 0, 2, 3
};

@implementation Graphics

/***** OpenGL Set Up Code *****/
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

    float screen_width = self.frame.size.width;
    float screen_height = self.frame.size.height;

    ImageVertices[0] = (Vertex){{screen_width, 0, 0}, {C_WHITE}, {1, 1}};
    ImageVertices[1] = (Vertex){{screen_width, screen_height, 0}, {C_WHITE}, {1, 0}};
    ImageVertices[2] = (Vertex){{0, screen_height, 0}, {C_WHITE}, {0, 0}};
    ImageVertices[3] = (Vertex){{0, 0, 0}, {C_WHITE}, {0, 1}};

    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(ImageVertices),
                 ImageVertices, GL_STATIC_DRAW);

    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(ImageIndices),
                 ImageIndices, GL_STATIC_DRAW);
}

/* Called by vision to set up the image to display to the screen */
- (void) setupTextureImage: (UIImage *) imageFile {

    DEBUG_SAY(4, "Graphics.m :: set up image texture\n");

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

    _imageTexture = texName;

    [self render];

    glDeleteTextures(1, &texName);
}

/* Methods called by server to manipulate the pieces on the client */
- (void) placePiece: (int) pieceID andCoords: (float[3]) coords {
    DEBUG_PRINT(3, "Graphics.m :: Place piece %d at [%.2f,%.2f]\n", pieceID, coords[0], coords[1]);
    _pieces[pieceID].x_location = coords[0];
    _pieces[pieceID].y_location = coords[1];
    _pieces[pieceID].rotation = coords[2];
    _pieces[pieceID].held = P_FALSE;
    if (_holdingPiece == pieceID) _holdingPiece = -1;
}

- (void) pickupPiece: (int) pieceID {
    DEBUG_PRINT(3, "Graphics.m :: Pick up piece %d\n", pieceID);
    _pieces[pieceID].held = P_TRUE;
    _holdingPiece = pieceID;
}

- (void) addToHeld: (int) pieceID {
    DEBUG_PRINT(3, "Graphics.m :: Add piece %d to held\n", pieceID);
    _pieces[pieceID].held = P_TRUE;
}

- (void) updateAllPieces: (Piece*) piecesS {
    DEBUG_SAY(3, "Graphics.m :: Update all pieces\n");
    _pieces = piecesS;
}

/***** SCREEN TOUCH *****/
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {

    UITouch *touch = [[event allTouches] anyObject];
    
    // Get the specific point that was touched
    CGPoint point = [touch locationInView:touch.view];

    DEBUG_PRINT(2,"Graphics.m :: Original [x,y] = [%.2f,%.2f]\n", point.x, point.y);

    point = [self.vision projectedPoints:point];

    DEBUG_PRINT(2, "Graphics.m :: Converted [x,y] = [%.2f,%.2f]\n", point.x, point.y);

    if (!_puzzleStateRecieved) {
        NSLog(@"Have not recieved the puzzle state yet!");
    }
    else if (_holdingPiece >= 0) {
        DEBUG_PRINT(3, "Graphics.m :: Ask server to place piece %d\n", _holdingPiece);
        [self.network droppedPiece:point.x WithY:point.y WithRotation:_pieces[_holdingPiece].rotation];
    }
    else {
        for (int i = 0; i < _num_of_pieces; i++) {
            if(point.x >= _pieces[i].x_location - SIDE_HALF && point.x < _pieces[i].x_location + SIDE_HALF) {
                if (point.y >= _pieces[i].y_location - SIDE_HALF && point.y < _pieces[i].y_location + SIDE_HALF) {
                    DEBUG_PRINT(3, "Graphics.m :: Ask server to pick up piece %d\n", i);
                    DEBUG_PRINT(3, "Graphics.m :: Piece %d at [%.2f,%.2f]:\nLeft: %.2f, Right: %.2f\nDown: %.2f, Up: %.2f\n", i,
                                _pieces[i].x_location,
                                _pieces[i].y_location,
                                _pieces[i].x_location - SIDE_HALF,
                                _pieces[i].x_location + SIDE_HALF,
                                _pieces[i].y_location - SIDE_HALF,
                                _pieces[i].y_location + SIDE_HALF);

                    [self.network requestPiece:i];
                    i = _num_of_pieces;
                }
            }
        }
        for (int i = 0; i < _num_of_pieces; i++) {
            DEBUG_PRINT(3, "%d: [%.2f,%.2f]\n", i, _pieces[i].x_location, _pieces[i].y_location);
        }
    }
}

/* Display image to the screen */
- (void) render {

    GLKMatrix4 projection;
    GLKMatrix4 modelView;

    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);

    glClearColor(C_CALM);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);

    glViewport(0, 0, self.frame.size.width, self.frame.size.height);

    // Sort out projection Matrix
    projection = GLKMatrix4MakeOrtho(0, self.frame.size.width, 0, self.frame.size.height, 0.1, 100);
    glUniformMatrix4fv(_projectionUniform, 1, 0, projection.m);

    // Send Image to the back
    modelView = GLKMatrix4MakeTranslation(0, 0, -99);
    glUniformMatrix4fv(_modelViewUniform, 1, 0, modelView.m);

    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBindTexture(GL_TEXTURE_2D, _imageTexture);

    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float)*3));
    glVertexAttribPointer(_texCoordSlot, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float) * 7));

    glDrawElements(GL_TRIANGLE_STRIP, sizeof(ImageIndices)/sizeof(ImageIndices[0]), GL_UNSIGNED_BYTE, 0);

    // Flush everything to the screen
    [_context presentRenderbuffer:GL_RENDERBUFFER];

    if (_holdingPiece >= 0) {
        DEBUG_PRINT(4, "Graphics.m :: Screen Centre [x,y] = [%.2f,%2.f]\n", screenCentre.x, screenCentre.y);
        CGPoint pieceCentreScreen = [self.vision projectedPoints:screenCentre];
        _pieces[_holdingPiece].x_location = pieceCentreScreen.x;
        _pieces[_holdingPiece].y_location = pieceCentreScreen.x;
        _pieces[_holdingPiece].rotation = 0;
        DEBUG_PRINT(4, "Graphics.m :: Piece Centre [x,y] = [%.2f,%2.f]\n", pieceCentreScreen.x, pieceCentreScreen.y);
        if (_motionManager.deviceMotionAvailable) {
            _motionManager.deviceMotionUpdateInterval = 0.01f;
            [_motionManager startDeviceMotionUpdatesToQueue:[[NSOperationQueue alloc] init]
                                         withHandler:^(CMDeviceMotion *data, NSError *error) {
                                             double rotation = atan2(data.gravity.x, data.gravity.y) - M_PI;
                                             DEBUG_PRINT(5, "Graphics.m :: Device Rotation = %.2f\n", radToDeg(rotation)-90);
                                             if (_holdingPiece >= 0) {
                                                 _pieces[_holdingPiece].rotation = radToDeg(rotation)-90;
                                             }
                                         }];
        }
    }
}

- (id) initWithFrame: (CGRect) frame andNetwork: (Network*) theNetwork {

    DEBUG_SAY(2, "Graphics.m :: initWithFrame\n");
    self = [super initWithFrame:frame];
    if (self) {
        // Call all the OpenGL set up code
        [self setupLayer];
        [self setupContext];
        [self setupDepthBuffer];
        [self setupRenderBuffer];
        [self setupFrameBuffer];
        [self compileShaders];
        [self setupVBOs];
        _motionManager = [[CMMotionManager alloc] init];

        _puzzleStateRecieved = NO;
        screenCentre = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);

        self.vision = [[Vision alloc]init];
        self.network = theNetwork;
        self.network.graphics = self;
        [self.network setUpMode:YES];
    }

    return self;
}

- (void) initWithPuzzle: (UIImage *) puzzleImageS
             withPieces: (Piece *) piecesS
             andNumRows: (int) numRows
             andNumCols: (int) numCols {

    DEBUG_SAY(2, "Graphics.m :: initWithPuzzle\n");
    _pieces = piecesS;
    _puzzleImage = puzzleImageS;
    _puzzle_rows = numRows;
    _puzzle_cols = numCols;
    _num_of_pieces = numRows * numCols;
    _texture_height = 1.0/(float)numRows;
    _texture_width = 1.0/(float)numCols;
    _holdingPiece = -1;
    _puzzleStateRecieved = YES;
}

@end
