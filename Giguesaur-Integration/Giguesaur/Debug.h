/*
    File: Debug.h
    Author: Ashley Manson
    
    Debug print macros
 */

#ifndef DEBUG_H
#define DEBUG_H

#define DEBUG_LEVEL 0

#define DEBUG_SAY(lvl, string) \
        do { if (DEBUG_LEVEL > lvl) fprintf(stderr, string); } while(0)

#define DEBUG_PRINT(lvl, format, ...) \
    do { if (DEBUG_LEVEL > lvl) fprintf(stderr, format, __VA_ARGS__); } while(0)


#endif
