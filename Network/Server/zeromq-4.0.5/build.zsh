#!/usr/bin/env zsh

make clean &>>|/dev/null

BUILD_DIR=`pwd`/build

if [[ -d $BUILD_DIR ]]; then
  rm -fr $BUILD_DIR
fi

mkdir -p $BUILD_DIR

ZMQ_BUILD_LOG_FILE=$BUILD_DIR/build.log

echo "-- Configuring with prefix $BUILD_DIR"

./configure --disable-dependency-tracking --enable-static --disable-shared --host=arm-apple-darwin10 --prefix=$BUILD_DIR &>>| $ZMQ_BUILD_LOG_FILE

echo "-- Building"
make &>>| $ZMQ_BUILD_LOG_FILE

echo "-- Installing to $BUILD_DIR"
make install &>>| $ZMQ_BUILD_LOG_FILE

echo "-- Cleaning up"
make clean &>>| /dev/null

echo "-- Copying headers"
mkdir $BUILD_DIR/usr && cp -R include $BUILD_DIR/usr
