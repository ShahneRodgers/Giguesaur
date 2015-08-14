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
//vector<Point3f> polypoints;
cv::Mat cameraMatrix, distCoeffs;
cv::Mat input;
BOOL puzzleImageCopied = NO;

std::vector<cv::Point3f> polypoints;

GLKMatrix4 modelView;// GLKMatrix4Identity;

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
    //NSLog(@"This works");
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
    // [self.graphics.layer addSublayer:preview];
    //[self.graphics bringSublayerToFront]; This doesn';t work
    //[self.graphics.layer insertSublayer:preview atIndex:1];

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
    cv::Mat viewMat = cv::Mat::zeros(4, 4, CV_64FC1);//might need to change format
    cv::Mat matToGL = cv::Mat::zeros(4, 4, CV_64FC1);
    cv::Mat output = cv::Mat::zeros(frame.size(), frame.type());

    matToGL.at<double>(0,0) = 1.0f;
    matToGL.at<double>(1,1) = -1.0f; //inverts y
    matToGL.at<double>(2,2) = -1.0f; //inverts z
    matToGL.at<double>(3,3) = 1.0f;

    // Get Piece Coordinates from Graphics
    PieceCoords pieceCoords[self.graphics.num_of_pieces][4];
    int num_of_pieces = self.graphics.num_of_pieces;
    int num_cols = self.graphics.puzzle_cols;
    float tex_width = self.graphics.texture_width;
    float tex_height = self.graphics.texture_height;
    Piece *pieces = self.graphics.pieces;

    for (int i = 0; i < num_of_pieces; i++) {
        // set row and col to get the sub-section of the texture
        int row = 0;
        int col = 0;
        int index = 0;
        while (index != i) {
            col++;
            index++;
            if (col >= num_cols) {
                col = 0;
                row++;
            }
        }
        // 0 and 2 swapped positions for openCV?
        pieceCoords[i][0] = (PieceCoords) {
            {pieces[i].x_location - SIDE_HALF, pieces[i].y_location + SIDE_HALF, PIECE_Z},
            {tex_width * (float)col, tex_height * (float)row}
        };
        pieceCoords[i][1] = (PieceCoords) {
            {pieces[i].x_location + SIDE_HALF, pieces[i].y_location + SIDE_HALF, PIECE_Z},
            {tex_width * (col+1), tex_height * row}
        };
        pieceCoords[i][2] = (PieceCoords) {
            {pieces[i].x_location + SIDE_HALF, pieces[i].y_location - SIDE_HALF, PIECE_Z},
            {tex_width * (col+1), tex_height * (row + 1)}
        };
        pieceCoords[i][3] = (PieceCoords) {
            {pieces[i].x_location - SIDE_HALF, pieces[i].y_location - SIDE_HALF, PIECE_Z},
            {tex_width * col, tex_height * (row+1)}
        };
    }

    for(int i = 0; i < 4; i++){
        for(int j = 0; j < 4; j++){
            float x = pieceCoords[i][j].Position[0];
            float y = pieceCoords[i][j].Position[1];
            float z = pieceCoords[i][j].Position[2];
            worldpieces.push_back(cv::Point3f(x,y,z));
        }
    }

    //vector<Point2f> imagepoints;
    bool vectors = false;

    // NSDate *start = [NSDate date];
    bool patternfound = findChessboardCorners(frame, boardSize, pixelcorners,
                                              cv::CALIB_CB_ADAPTIVE_THRESH + cv::CALIB_CB_NORMALIZE_IMAGE
                                              + cv::CALIB_CB_FAST_CHECK);

    /*bool patternfound = findChessboardCorners(frame, boardSize, pixelcorners, cv::CALIB_CB_ADAPTIVE_THRESH + cv::CALIB_CB_FAST_CHECK + cv::CALIB_CB_FILTER_QUADS);*/

    /* NSDate *finish = [NSDate date];
     NSTimeInterval runtime = [finish timeIntervalSinceDate:start];
     NSLog(@"Checkerboard found in %f \n", runtime);*/
    if(patternfound){
        vectors = solvePnP(corners, pixelcorners, cameraMatrix, distCoeffs, rvec, tvec, false);
        cv::drawChessboardCorners(frame, boardSize, pixelcorners, patternfound);
    }

    if(vectors){

        cv::projectPoints(worldpieces, rvec, tvec, cameraMatrix, distCoeffs, imagepoints);

        cv::Mat lambda(2,4, CV_32FC1);
        lambda = cv::Mat::zeros(input.rows/2, input.cols/2, input.type());

        int width = input.rows;
        int height = input.cols;


        for(int i = 0; i < 4; i++){
            cv::Point2f inputQuad[4];
            cv::Point2f outputQuad[4];
            // for(int j = i * 4; j < i * 4 + 4; j++){
            int j = i * 4;
            //float texX = pieceCoords[i][j].TexCoord[0];
            //float texY = pieceCoords[i][j].TexCoord[1];


            inputQuad[0] = cv::Point2f(pieceCoords[i][0].TexCoord[0]*width, pieceCoords[i][0].TexCoord[1]*height);
            inputQuad[1] = cv::Point2f(pieceCoords[i][1].TexCoord[0]*width, pieceCoords[i][1].TexCoord[1]*height);
            inputQuad[2] = cv::Point2f(pieceCoords[i][2].TexCoord[0]*width, pieceCoords[i][2].TexCoord[1]*height);
            inputQuad[3] = cv::Point2f(pieceCoords[i][3].TexCoord[0]*width, pieceCoords[i][3].TexCoord[1]*height);

            /*  std::cout << "corner 0" << inputQuad[0] << " " << pieceCoords[i][0].TexCoord[0] << " " << pieceCoords[i][j].TexCoord[1] << std::endl;
             std::cout << "corner 1" << inputQuad[1] << " " << pieceCoords[i][1].TexCoord[0] << " " << pieceCoords[i][1].TexCoord[1] << std::endl;

             std::cout << "corner 2" << inputQuad[2] << " " << pieceCoords[i][2].TexCoord[0] << " " << pieceCoords[i][2].TexCoord[1] << std::endl;

             std::cout << "corner 3" << inputQuad[3] << " " << pieceCoords[i][3].TexCoord[0] << " " << pieceCoords[i][3].TexCoord[1] << std::endl;*/
            

            outputQuad[0] = imagepoints[j];
            outputQuad[1] = imagepoints[j+1];
            outputQuad[2] = imagepoints[j+2];
            outputQuad[3] = imagepoints[j+3];



            cv::Mat subImage = input(cv::Rect(inputQuad[0].x, inputQuad[0].y, width/2, height/2)); //Hardcoded height and width.

            lambda = cv::getPerspectiveTransform(inputQuad, outputQuad);

            cv::warpPerspective(subImage, output, lambda, output.size());
            //std::cout << output.rows << " " << output.cols << " " << output.type() << std::endl;
            output.copyTo(frame,output);

            //}
        }

        //std::cout << "rvec: " << rvec << "tvec: " << tvec << std::endl;
        /* for(int i = 0; i < 3; i++){
         rotation[i] = rvec.at<double>(0,i);
         translation[i] = tvec.at<double>(0,i);
         }

         for(int i = 0; i < 3; i++){
         printf("rotation %d: %f\n", i+1, rotation[i]);
         printf("translation %d: %f\n", i+1, translation[i]);
         }*/

        /*GLKMatrix4 rotation = GLKMatrix4MakeRotation(degToRad(0), 0, 0, 1);
         GLKMatrix4 translation = GLKMatrix4MakeTranslation(0,0,-1);*/
        //modelView = GLKMatrix4Multiply(rotation, translation);

        /*projectPoints(polypoints, rvec, tvec, cameraMatrix, distCoeffs, imagepoints);
         line(frame, imagepoints[0], imagepoints[1], cv::Scalar(255,0,0), 5, 8);
         //line(frame, imagepoints[1], imagepoints[2], Scalar(255,0,0), 5, 8);
         //line(frame, imagepoints[2], imagepoints[3], Scalar(255,0,0), 5, 8);
         line(frame, imagepoints[3], imagepoints[0], cv::Scalar(0,255,0), 5, 8);

         line(frame, imagepoints[0], imagepoints[4], cv::Scalar(0,0,255), 5, 8);*/

        /*line(frame, imagepoints[1], imagepoints[5], Scalar(255,0,0), 5, 8);
         line(frame, imagepoints[2], imagepoints[6], Scalar(255,0,0), 5, 8);
         line(frame, imagepoints[3], imagepoints[7], Scalar(255,0,0), 5, 8);

         line(frame, imagepoints[4], imagepoints[5], Scalar(255,0,0), 5, 8);
         line(frame, imagepoints[5], imagepoints[6], Scalar(255,0,0), 5, 8);
         line(frame, imagepoints[6], imagepoints[7], Scalar(255,0,0), 5, 8);
         line(frame, imagepoints[7], imagepoints[4], Scalar(255,0,0), 5, 8);*/


        cv::Rodrigues(rvec, rotation);
        for(int row = 0; row < 3; row++){
            for(int col = 0; col < 3; col++){
                viewMat.at<double>(row,col) = rotation.at<double>(row,col);
            }
            viewMat.at<double>(row,3) = tvec.at<double>(row,0);// changed, might be wrong curerntly in line with example
            // std::cout << tvec.at<double>(row,0) << std::endl;
        }
        viewMat.at<double>(3,3) = 1.0f;
        viewMat = viewMat * matToGL;
        cv::transpose(viewMat, viewMat);

        modelView = GLKMatrix4Make(viewMat.at<double>(0,0), viewMat.at<double>(0,1), viewMat.at<double>(0,2), viewMat.at<double>(0,3), viewMat.at<double>(1,0), viewMat.at<double>(1,1), viewMat.at<double>(1,2), viewMat.at<double>(1,3), viewMat.at<double>(2,0), viewMat.at<double>(2,1), viewMat.at<double>(2,2), viewMat.at<double>(2,3), viewMat.at<double>(3,0), viewMat.at<double>(3,1), viewMat.at<double>(3,2), viewMat.at<double>(3,3));
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

