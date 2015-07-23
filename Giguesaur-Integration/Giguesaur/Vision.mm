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

@implementation Vision

@synthesize videoCaptureDevice;
@synthesize videoDataOutput;
@synthesize session;

- (void) visionInit{
    
    
    for( int i = 0; i < boardSize.height; ++i ){
        for( int j = 0; j < boardSize.width; ++j ){
            corners.push_back(cv::Point3f(float(j*28), float(i*28), 0));
        }
    }
    
    /* NSBundle *mainBundle = [NSBundle mainBundle];
     NSString *myFile = [mainBundle pathForResource: @"camera_params" ofType: @"xml"];
     //std::string *path = new std::string([myFile UTF8String]);
     const char *path = [myFile UTF8String];
     
     FileStorage fs(path, FileStorage::READ);
     if(!fs.isOpened())
     std::cout << "File io is not working" << std::endl;
     
     fs["Camera_Matrix"] >> cameraMatrix;
     fs["Distortion_Coefficients"] >> distCoeffs;
     fs.release();*/
    
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
    preview.frame = self.view.bounds;
    preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    preview.hidden = YES;
    [self.view.layer addSublayer:preview];
    
    
}

- (void) calculatePose:(cv::Mat &)frame{
    
    std::vector<cv::Point2f> pixelcorners;
    cv::Mat rvec;
    cv::Mat tvec;
    //vector<Point2f> imagepoints;
    bool vectors = false;
    
    bool patternfound = findChessboardCorners(frame, boardSize, pixelcorners,
                                              cv::CALIB_CB_ADAPTIVE_THRESH + cv::CALIB_CB_NORMALIZE_IMAGE
                                              + cv::CALIB_CB_FAST_CHECK);
    
    if(patternfound){
        vectors = solvePnP(corners, pixelcorners, cameraMatrix, distCoeffs, rvec, tvec, false);
    }
    
    if(vectors){
    //Do something here with rvec and tvec, likely call rendering while passing it mat
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
fromConnection:(AVCaptureConnection *)connection {
    
    NSLog(@"delegate works!");
    cv::Mat frame;
    [self fromSampleBuffer:sampleBuffer toCVMat: frame];
    
    [self calculatePose:frame];
    //cv::cvtColor(frame, frame, CV_BGRA2GRAY);
    
    UIImage *image = [self UIImageFromCVMat:frame];
    
    //    imageView.image = image;
   /* [[[ALAssetsLibrary alloc] init] writeImageToSavedPhotosAlbum:[image CGImage] orientation:(ALAssetOrientation)[image imageOrientation] completionBlock:nil];*/
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
    
    // create the cv mat
    mat.create(h, w, CV_8UC4);
    memcpy(mat.data, imgBufAddr, w * h);
    
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

