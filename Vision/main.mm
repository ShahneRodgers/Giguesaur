//
//  main.mm
//  Vision
//
//  Created by Local Joshua La Pine on 5/11/15.
//  Copyright (c) 2015 Local Joshua La Pine. All rights reserved.
//
#include <opencv2/core/core.hpp>
#include <opencv2/video/tracking.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/calib3d/calib3d.hpp>
#include <iostream>

using namespace std;
using namespace cv;

int main(int argc, char** argv){
    
    VideoCapture cap;
    cap.open(0);
    Mat frame;
    Size boardSize(9,6);
    vector<Point3f> corners;
    
    for( int i = 0; i < boardSize.height; ++i ){
        for( int j = 0; j < boardSize.width; ++j ){
            corners.push_back(Point3f(float(j*28), float(i*28), 0));
        }
    }
    
    FileStorage fs("/Users/localjosh/490/camera_params.xml", FileStorage::READ);
    if(!fs.isOpened())
        cout << "File io is not working" << endl;
    
    Mat cameraMatrix, distCoeffs;
    fs["Camera_Matrix"] >> cameraMatrix;
    fs["Distortion_Coefficients"] >> distCoeffs;
    fs.release();
    
    for(;;){
        cap >> frame;
  
        vector<Point2f> pixelcorners;
        Mat rvec;
        Mat tvec;
        bool vectors = false;
        
        bool patternfound = findChessboardCorners(frame, boardSize, pixelcorners,
                                                  CALIB_CB_ADAPTIVE_THRESH + CALIB_CB_NORMALIZE_IMAGE
                                                  + CALIB_CB_FAST_CHECK);

        if(patternfound){
            vectors = solvePnP(corners, pixelcorners, cameraMatrix, distCoeffs, rvec, tvec, false);
        }
        
        drawChessboardCorners(frame, boardSize, pixelcorners, patternfound);
        imshow("It worked!", frame);
        if(vectors){
            cout << "Rotation matrix: " << rvec << endl;
            cout << "Translation matrix: " <<tvec << endl;
        }
        waitKey(1);
        
    }
    
    return 0;
}


