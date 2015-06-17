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
    vector<Point3f> polypoints;
    
    //bottom
    polypoints.push_back(Point3f(float(0), float(0), float(0)));
    polypoints.push_back(Point3f(float(56), float(0), float(0)));
    polypoints.push_back(Point3f(float(56), float(56), float(0)));
    polypoints.push_back(Point3f(float(0), float(56), float(0)));
    
    //back
    /*polypoints.push_back(Point3f(float(0), float(0), 0));
    polypoints.push_back(Point3f(float(28), float(0), 0));
    polypoints.push_back(Point3f(float(28), float(0), float(28)));
    polypoints.push_back(Point3f(float(0), float(0), float(28)));

    //right
    polypoints.push_back(Point3f(float(28), float(0), 0));
    polypoints.push_back(Point3f(float(28), float(28), 0));
    polypoints.push_back(Point3f(float(28), float(28), float(28)));
    polypoints.push_back(Point3f(float(28), float(0), float(28)));

    //front
    polypoints.push_back(Point3f(float(0), float(28), 0));
    polypoints.push_back(Point3f(float(28), float(28), 0));
    polypoints.push_back(Point3f(float(28), float(28), float(28)));
    polypoints.push_back(Point3f(float(0), float(28), float(28)));

    //left
    polypoints.push_back(Point3f(float(0), float(0), 0));
    polypoints.push_back(Point3f(float(0), float(28), 0));
    polypoints.push_back(Point3f(float(0), float(28), float(28)));
    polypoints.push_back(Point3f(float(0), float(0), float(28)));*/

    //top
    polypoints.push_back(Point3f(float(0), float(0), float(-56)));
    polypoints.push_back(Point3f(float(56), float(0), float(-56)));
    polypoints.push_back(Point3f(float(56), float(56), float(-56)));
    polypoints.push_back(Point3f(float(0), float(56), float(-56)));
   
    
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
        vector<Point2f> imagepoints;
        //Point imagepointsformat[1][4];
        //vector<vector<Point2f> > fillpoints;
        bool vectors = false;
        
        bool patternfound = findChessboardCorners(frame, boardSize, pixelcorners,
                                                  CALIB_CB_ADAPTIVE_THRESH + CALIB_CB_NORMALIZE_IMAGE
                                                  + CALIB_CB_FAST_CHECK);

        if(patternfound){
            vectors = solvePnP(corners, pixelcorners, cameraMatrix, distCoeffs, rvec, tvec, false);
        }
        
   
        if(vectors){
            //cout << "Rotation matrix: " << rvec << endl;
            //cout << "Translation matrix: " <<tvec << endl;
            projectPoints(polypoints, rvec, tvec, cameraMatrix, distCoeffs, imagepoints);
            line(frame, imagepoints[0], imagepoints[1], Scalar(255,0,0), 5, 8);
            line(frame, imagepoints[1], imagepoints[2], Scalar(255,0,0), 5, 8);
            line(frame, imagepoints[2], imagepoints[3], Scalar(255,0,0), 5, 8);
            line(frame, imagepoints[3], imagepoints[0], Scalar(255,0,0), 5, 8);
            
            line(frame, imagepoints[0], imagepoints[4], Scalar(255,0,0), 5, 8);
            line(frame, imagepoints[1], imagepoints[5], Scalar(255,0,0), 5, 8);
            line(frame, imagepoints[2], imagepoints[6], Scalar(255,0,0), 5, 8);
            line(frame, imagepoints[3], imagepoints[7], Scalar(255,0,0), 5, 8);
            
            line(frame, imagepoints[4], imagepoints[5], Scalar(255,0,0), 5, 8);
            line(frame, imagepoints[5], imagepoints[6], Scalar(255,0,0), 5, 8);
            line(frame, imagepoints[6], imagepoints[7], Scalar(255,0,0), 5, 8);
            line(frame, imagepoints[7], imagepoints[4], Scalar(255,0,0), 5, 8);
            /*for(int i = 0; i < 4; i++){
                imagepointsformat[0][i] = imagepoints[i];
            }
            /*int j = 0;
            for(int i = 0; i < 6; i++){
                fillpoints[i].push_back(imagepoints[j++]);
                fillpoints[i].push_back(imagepoints[j++]);
                fillpoints[i].push_back(imagepoints[j++]);
                fillpoints[i].push_back(imagepoints[j++]);*/
            //}
           // const Point* ppt[1] = {imagepointsformat[0]};
            //int n[] = {4};
           // fillPoly(frame, imagepointsformat, n, 1, Scalar(0,0,0));
        }
        
        //drawChessboardCorners(frame, boardSize, pixelcorners, patternfound);
        imshow("It worked!", frame);
        waitKey(1);
        
    }
    
    return 0;
}


