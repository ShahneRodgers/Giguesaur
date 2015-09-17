//
//  Vision.m
//  Giguesaur
//
//  Created by Local Joshua La Pine on 7/23/15.
//  Copyright (c) 2015 Giguesaur Team. All rights reserved.
//

#import "Vision.h"

cv::Size boardSize(9,6);
std::vector<cv::Point3f> corners;
cv::Mat cameraMatrix, distCoeffs;
cv::Mat input; // the puzzle image, who named it input?
BOOL puzzleImageCopied = NO;
std::vector<cv::Point2f> imagePlane;
std::vector<cv::Point3f> polypoints;
GLKMatrix4 modelView;
float current_rotation = 0;

@implementation Vision

@synthesize videoCaptureDevice;
@synthesize videoDataOutput;
@synthesize session;

- (void) visionInit:(Graphics *) graphics{

    // This needs to be replaced with the UIImage held in Graphics
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *filePath = [mainBundle pathForResource: @"puppy" ofType: @"png"];
    UIImage* resImage = [UIImage imageWithContentsOfFile:filePath];

    //UIImage* resImage = self.graphics.puzzleImage;
    input = [self cvMatFromUIImage:resImage];


    self.graphics = graphics;

    for( int i = 0; i < boardSize.height; ++i ){
        for( int j = 0; j < boardSize.width; ++j ){
            corners.push_back(cv::Point3f(float(j*28), float(i*28), 0));
        }
    }

    NSString *myFile = [mainBundle pathForResource: @"0.7params" ofType: @"xml"];
    //std::string *path = new std::string([myFile UTF8String]);
    const char *path = [myFile UTF8String];

    cv::FileStorage fs(path, cv::FileStorage::READ);
    if(!fs.isOpened())
        std::cout << "File io is not working" << std::endl;

    fs["Camera_Matrix"] >> cameraMatrix;
    fs["Distortion_Coefficients"] >> distCoeffs;
    fs.release();

    session = [[AVCaptureSession alloc]init];
    session.sessionPreset = AVCaptureSessionPresetHigh;
    videoCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

    [videoCaptureDevice lockForConfiguration:nil];
    [videoCaptureDevice setVideoZoomFactor:1];
    [videoCaptureDevice setFocusMode:AVCaptureFocusModeLocked];
    [videoCaptureDevice unlockForConfiguration];

    NSError *error = nil;
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoCaptureDevice error: &error];
    if(videoInput){
        [session addInput:videoInput];
    } else {
        NSLog(@"For some reason the device has no camera?");
    }

    videoDataOutput = [AVCaptureVideoDataOutput new];
    NSDictionary *newSettings =
    @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) };
    videoDataOutput.videoSettings = newSettings;
    [videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];

    dispatch_queue_t queue = dispatch_queue_create("MyQueue", NULL);
    [videoDataOutput setSampleBufferDelegate:self queue:queue];

    [session addOutput:videoDataOutput];

    AVCaptureVideoPreviewLayer *preview = [AVCaptureVideoPreviewLayer layerWithSession:session];
    preview.frame = self.graphics.bounds;
    preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    preview.hidden = YES;
}

// Convert from screen coordinates to world coordinates
- (CGPoint) projectedPoints: (CGPoint) screenCoords {

    double s_x = screenCoords.x*1.875; // 1920 / 1024
    double s_y = screenCoords.y*1.40625; // 1080 / 768

    cv::Mat rvec, tvec, rotationMatrix;
    cv::solvePnP(corners, imagePlane, cameraMatrix, distCoeffs, rvec, tvec, false);
    cv::Rodrigues(rvec,rotationMatrix);
    cv::Mat uvPoint = cv::Mat::ones(3,1,cv::DataType<double>::type); // u,v,1
    // image point
    uvPoint.at<double>(0,0) = s_x;
    uvPoint.at<double>(1,0) = s_y;

    cv::Mat tempMat, tempMat2;
    double s;
    tempMat = rotationMatrix.inv() * cameraMatrix.inv() * uvPoint;
    tempMat2 = rotationMatrix.inv() * tvec;
    s = PIECE_Z + tempMat2.at<double>(2,0);
    s /= tempMat.at<double>(2,0);
    cv::Mat wcPoint = rotationMatrix.inv() * (s * cameraMatrix.inv() * uvPoint - tvec);

    cv::Point3f realPoint(wcPoint.at<double>(0, 0), wcPoint.at<double>(1, 0), wcPoint.at<double>(2, 0)); // point in world coordinates

    return CGPointMake(wcPoint.at<double>(0,0), wcPoint.at<double>(1, 0));
}

- (void) calculatePose:(cv::Mat &)frame{

    if (self.graphics.puzzleStateRecieved && !puzzleImageCopied) {
        input = [self cvMatFromUIImage:self.graphics.puzzleImage];
        puzzleImageCopied = YES;
    }

    std::vector<cv::Point2f> imagepoints;
    std::vector<cv::Point2f> pixelcorners;
    std::vector<cv::Point3f> worldpieces;
    cv::Mat rvec;
    cv::Mat tvec;
    cv::Mat rotation;
    cv::Mat output = cv::Mat::zeros(frame.size(), frame.type());
    int width = input.rows;
    int height = input.cols;
    bool vectors = false;
    bool patternfound = findChessboardCorners(frame, boardSize, pixelcorners,
                                              cv::CALIB_CB_ADAPTIVE_THRESH + cv::CALIB_CB_NORMALIZE_IMAGE
                                              + cv::CALIB_CB_FAST_CHECK);

    SimpleMath *simpleMath = [[SimpleMath alloc] init];
    PieceCoords pieceCoords[self.graphics.num_of_pieces][4]; // 4 = number of corners
    int num_pieces_draw = 0;

    current_rotation += 5;
    if (current_rotation >= 360) {
        current_rotation = 0;
    }
    printf("rotation: %.2f\n", current_rotation);

    for (int i = 0; i < self.graphics.num_of_pieces; i++) {
        // set row and col to get the sub-section of the texture
        int row = 0;
        int col = 0;
        int index = 0;
        while (index != i) {
            col++;
            index++;
            if (col >= self.graphics.puzzle_cols) {
                col = 0;
                row++;
            }
        }
        Piece tempPiece = self.graphics.pieces[i];
        if (i == 1) {
            tempPiece.rotation += current_rotation;


        tempPiece.x_location += SIDE_LENGTH*col;
        tempPiece.y_location += SIDE_LENGTH*row;
        }
        /*
        if (tempPiece.rotation == 0) {
            tempPiece.x_location += SIDE_LENGTH*col;
            tempPiece.y_location += SIDE_LENGTH*row;
        }
        else if (tempPiece.rotation == 90) {
            tempPiece.x_location -= SIDE_LENGTH*row;
            tempPiece.y_location += SIDE_LENGTH*col;
        }
        else if (tempPiece.rotation == 180) {
            tempPiece.x_location -= SIDE_LENGTH*col;
            tempPiece.y_location -= SIDE_LENGTH*row;
        }
        else if (tempPiece.rotation == 270) {
            tempPiece.x_location += SIDE_LENGTH*row;
            tempPiece.y_location -= SIDE_LENGTH*col;
        }
        */

        NSArray *rotatedPiece = [simpleMath pointsRotated:tempPiece];
        CGPoint topLeft = [[rotatedPiece objectAtIndex:0] CGPointValue];
        CGPoint topRight = [[rotatedPiece objectAtIndex:1] CGPointValue];
        CGPoint botRight = [[rotatedPiece objectAtIndex:2] CGPointValue];
        CGPoint botLeft = [[rotatedPiece objectAtIndex:3] CGPointValue];

        pieceCoords[i][0] = (PieceCoords) {
            {static_cast<float>(botLeft.x), static_cast<float>(botLeft.y), PIECE_Z},
            {self.graphics.texture_width * col, self.graphics.texture_height * row}
        };
        pieceCoords[i][1] = (PieceCoords) {
            {static_cast<float>(botRight.x), static_cast<float>(botRight.y), PIECE_Z},
            {self.graphics.texture_width * (col + 1), self.graphics.texture_height * row}
        };
        pieceCoords[i][2] = (PieceCoords) {
            {static_cast<float>(topRight.x), static_cast<float>(topRight.y), PIECE_Z},
            {self.graphics.texture_width * (col + 1), self.graphics.texture_height * (row + 1)}
        };
        pieceCoords[i][3] = (PieceCoords) {
            {static_cast<float>(topLeft.x), static_cast<float>(topLeft.y), PIECE_Z},
            {self.graphics.texture_width * col, self.graphics.texture_height * (row + 1)}
        };

        if (!self.graphics.pieces[i].held || self.graphics.holdingPiece == i) {
            num_pieces_draw++;
            for(int j = 0; j < 4; j++){
                float x, y;
                if (i == 1) {
                     x = pieceCoords[i][j].Position[0] -= SIDE_LENGTH*col;
                     y = pieceCoords[i][j].Position[1] -= SIDE_LENGTH*row;
                }
                else {
                     x = pieceCoords[i][j].Position[0];// -= SIDE_LENGTH*col;
                     y = pieceCoords[i][j].Position[1];// -= SIDE_LENGTH*row;
                }
                float z = pieceCoords[i][j].Position[2];
                worldpieces.push_back(cv::Point3f(x,y,z));
            }
        }
    }

    if (patternfound) {
        imagePlane = pixelcorners;
        vectors = solvePnP(corners, pixelcorners, cameraMatrix, distCoeffs, rvec, tvec, false);
        //cv::drawChessboardCorners(frame, boardSize, pixelcorners, patternfound);
    }

    if (vectors) {

        for (int piece = 0; piece < num_pieces_draw; piece++) {
            std::vector<cv::Point2f> imagePiece;
            std::vector<cv::Point3f> worldPiece;
            int corner = piece * 4;

            worldPiece.push_back(worldpieces.at(corner));
            worldPiece.push_back(worldpieces.at(corner+1));
            worldPiece.push_back(worldpieces.at(corner+2));
            worldPiece.push_back(worldpieces.at(corner+3));

            cv::projectPoints(worldPiece, rvec, tvec, cameraMatrix, distCoeffs, imagePiece);

            imagepoints.push_back(imagePiece.at(0));
            imagepoints.push_back(imagePiece.at(1));
            imagepoints.push_back(imagePiece.at(2));
            imagepoints.push_back(imagePiece.at(3));

            cv::Mat lambda(2,4, CV_32FC1);
            //lambda = cv::Mat::zeros(input.rows*self.graphics.texture_height, input.cols*self.graphics.texture_width, input.type());

            cv::Point2f inputQuad[4];
            cv::Point2f outputQuad[4];

            inputQuad[0] = cv::Point2f(pieceCoords[piece][0].TexCoord[0]*width, pieceCoords[piece][0].TexCoord[1]*height);
            inputQuad[1] = cv::Point2f(pieceCoords[piece][1].TexCoord[0]*width, pieceCoords[piece][1].TexCoord[1]*height);
            inputQuad[2] = cv::Point2f(pieceCoords[piece][2].TexCoord[0]*width, pieceCoords[piece][2].TexCoord[1]*height);
            inputQuad[3] = cv::Point2f(pieceCoords[piece][3].TexCoord[0]*width, pieceCoords[piece][3].TexCoord[1]*height);

            outputQuad[0] = imagepoints[corner];
            outputQuad[1] = imagepoints[corner+1];
            outputQuad[2] = imagepoints[corner+2];
            outputQuad[3] = imagepoints[corner+3];

            cv::Rect crop(inputQuad[0].x, inputQuad[0].y, width*self.graphics.texture_width, height*self.graphics.texture_height);
            cv::Mat subImage = input(crop);//cv::Rect(inputQuad[0].x, inputQuad[0].y, width*self.graphics.texture_width, height*self.graphics.texture_height));

            lambda = cv::getPerspectiveTransform(inputQuad, outputQuad);

            cv::warpPerspective(subImage, output, lambda, output.size());
            output.copyTo(frame, output);
        }

    }

    @autoreleasepool {

        cv::cvtColor(frame, frame, CV_BGRA2RGBA);

        /* cv::Rect crop(240,0,1440,1080);
         frame = frame(crop);
         std::cout << frame.cols << " " << frame.rows << std::endl;*/
        UIImage *image = [self UIImageFromCVMat:frame];
        /*[[self graphics] performSelectorOnMainThread:@selector(visionBackgroundRender:)
         withObject:image
         waitUntilDone:NO];*/

        dispatch_async(dispatch_get_main_queue(), ^{
            [[self graphics] setupTextureImage:image];
        });
    }
    rvec.release();
    tvec.release();
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {

    @autoreleasepool {

        //NSLog(@"delegate works!");
        cv::Mat frame;
        [self fromSampleBuffer:sampleBuffer toCVMat: frame];
        // std::cout << frame.size().height << frame.size().width << std::endl;
        //std::cout << frame.cols << " " << frame.rows << std::endl;
        [self calculatePose:frame];
        /* cv::cvtColor(frame, frame, CV_BGRA2RGBA);

         UIImage *image = [self UIImageFromCVMat:frame];
         [[self graphics] performSelectorOnMainThread:@selector(visionBackgroundRender:)
         withObject:image
         waitUntilDone:NO];*/

        /* [[[ALAssetsLibrary alloc] init] writeImageToSavedPhotosAlbum:[image CGImage] orientation:(ALAssetOrientation)[image imageOrientation] completionBlock:nil];*/
        frame.release();
    }
    //    imageView.image = image;
}

- (void)fromSampleBuffer:(CMSampleBufferRef)sampleBuffer
                 toCVMat:(cv::Mat &)mat{

    CVImageBufferRef imgBuf = CMSampleBufferGetImageBuffer(sampleBuffer);

    // lock the buffer
    CVPixelBufferLockBaseAddress(imgBuf, 0);

    // get the address to the image data
    void *imgBufAddr = CVPixelBufferGetBaseAddress(imgBuf);

    // get image properties
    int w = (int)CVPixelBufferGetWidth(imgBuf);
    int h = (int)CVPixelBufferGetHeight(imgBuf);
    int bytesPerRow = (int)CVPixelBufferGetBytesPerRow(imgBuf);
    int size = h * bytesPerRow;


    // create the cv mat
    mat.create(h, w, CV_8UC4);
    memcpy(mat.data, imgBufAddr, size);

    // unlock again
    CVPixelBufferUnlockBaseAddress(imgBuf, 0);

}

-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;

    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }

    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);

    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );


    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);

    return finalImage;
}

- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;

    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)

    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

@end

