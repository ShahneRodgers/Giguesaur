/*
    File: Debug.h
    Author: Ashley Manson
    
    Debug macros
 */

#ifndef DEBUG_H
#define DEBUG_H

#define DEBUG_LEVEL 0

#define DEBUG_SAY(string) \
        do { if (DEBUG_LEVEL > 0) fprintf(stderr, string); } while(0)

#define DEBUG_PRINT_1(format, ...) \
        do { if (DEBUG_LEVEL > 0) fprintf(stderr, format, __VA_ARGS__); } while(0)

#define DEBUG_PRINT_2(format, ...) \
        do { if (DEBUG_LEVEL > 1) fprintf(stderr, format, __VA_ARGS__); } while(0)

#endif
