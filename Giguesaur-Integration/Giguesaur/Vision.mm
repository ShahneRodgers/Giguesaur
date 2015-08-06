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
GLKMatrix4 modelView;// GLKMatrix4Identity;

@implementation Vision

@synthesize videoCaptureDevice;
@synthesize videoDataOutput;
@synthesize session;

- (void) visionInit:(Graphics *) graphics{
    
    self.graphics = graphics;
    
    for( int i = 0; i < boardSize.height; ++i ){
        for( int j = 0; j < boardSize.width; ++j ){
            corners.push_back(cv::Point3f(float(j*28), float(i*28), 0));
        }
    }
    
     NSBundle *mainBundle = [NSBundle mainBundle];
     NSString *myFile = [mainBundle pathForResource: @"camera_params" ofType: @"xml"];
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
    NSLog(@"This works");
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
    
    std::vector<cv::Point2f> pixelcorners;
    cv::Mat rvec;
    cv::Mat tvec;
    cv::Mat rotation;
    cv::Mat viewMat = cv::Mat::zeros(4, 4, CV_64FC1);//might need to change format
    cv::Mat matToGL = cv::Mat::zeros(4, 4, CV_64FC1);
    
    matToGL.at<double>(0,0) = 1.0f;
    matToGL.at<double>(1,1) = -1.0f; //inverts y
    matToGL.at<double>(2,2) = -1.0f; //inverts z
    matToGL.at<double>(3,3) = 1.0f;
    
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

        cv::Rodrigues(rvec, rotation);
        for(int row = 0; row < 3; row++){
            for(int col = 0; col < 3; col++){
                viewMat.at<double>(row,col) = rotation.at<double>(row,col);
            }
            viewMat.at<double>(row,3) = tvec.at<double>(0,row);
        }
        viewMat.at<double>(3,3) = 1.0f;
        viewMat = viewMat * matToGL;
        cv::transpose(viewMat, viewMat);
        
        modelView = GLKMatrix4Make(viewMat.at<double>(0,0), viewMat.at<double>(0,1), viewMat.at<double>(0,2), viewMat.at<double>(0,3), viewMat.at<double>(1,0), viewMat.at<double>(1,1), viewMat.at<double>(1,2), viewMat.at<double>(1,3), viewMat.at<double>(2,0), viewMat.at<double>(2,1), viewMat.at<double>(2,2), viewMat.at<double>(2,3), viewMat.at<double>(3,0), viewMat.at<double>(3,1), viewMat.at<double>(3,2), viewMat.at<double>(3,3));
    }
    
    @autoreleasepool {
        
        
        cv::cvtColor(frame, frame, CV_BGRA2RGBA);
        
        UIImage *image = [self UIImageFromCVMat:frame];
        /*[[self graphics] performSelectorOnMainThread:@selector(visionBackgroundRender:)
         withObject:image
         waitUntilDone:NO];*/
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self graphics] visionBackgroundRender:image with: &modelView];
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

@end

