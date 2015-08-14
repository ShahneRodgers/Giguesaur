//
//  Vision.h
//  Giguesaur
//
//  Created by Local Joshua La Pine on 7/23/15.
//  Copyright (c) 2015 Giguesaur Team. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "Graphics.h"
//#import <opencv2/opencv.hpp>
#import "opencv2/core/core_c.h"
#import "opencv2/core/core.hpp"
#import "opencv2/flann/miniflann.hpp"
#import "opencv2/imgproc/imgproc_c.h"
#import "opencv2/imgproc/imgproc.hpp"
#import "opencv2/photo/photo.hpp"
#import "opencv2/features2d/features2d.hpp"
#import "opencv2/objdetect/objdetect.hpp"
#import "opencv2/calib3d/calib3d.hpp"
#import "opencv2/ml/ml.hpp"
#import "opencv2/highgui/highgui_c.h"
#import "opencv2/highgui/highgui.hpp"
#import "opencv2/contrib/contrib.hpp"

typedef struct {
    float Position[3];
    float TexCoord[2];
} PieceCoords;

@class Graphics;

@interface Vision : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>

//ViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate>

@property IBOutlet UIView *view;
@property AVCaptureSession *session;
@property AVCaptureDevice *videoCaptureDevice;
@property AVCaptureVideoDataOutput *videoDataOutput;
@property Graphics *graphics;
//@property IBOutlet UIImageView *imageView;

- (void) visionInit:(Graphics *) graphics;

#ifdef __cplusplus
- (void) fromSampleBuffer:(CMSampleBufferRef)sampleBuffer
                  toCVMat:(cv::Mat &)mat;
-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat;
#endif

@end

