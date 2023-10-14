/*
 **************************************************************************************************
 Package:  Cuppa
 Class:    Cuppa_Shape
           - Constants for cup shape types and associated abstract support class.
 ----------------------------------------------------------------------------------------------------
 Copyright (c) 2005-2023 Nathan Cosgray. All rights reserved.
 
 This source code is licensed under the BSD-style license found in LICENSE.txt.
 **************************************************************************************************
 */

#ifndef _CUPPA_SHAPE_H
#define _CUPPA_SHAPE_H

#if !defined(__OBJC__)
#error "Objective-C only source file."
#endif

// OSX Includes

#import <Foundation/Foundation.h>

// Constants

enum
{
    // Cup Shapes
    CUPPA_SHAPE_DEFAULT = 0,
    CUPPA_SHAPE_TEA,
    CUPPA_SHAPE_MUG,
    CUPPA_SHAPE_NOODLE,
    CUPPA_SHAPE_MAX
};

// Class Interface

@interface Cuppa_Shape : NSObject
{
    // no instance vars
}

// ------ Class Methods ------

// Returns a (non human interface) string which represents the shape.
// Param shape must be on of the shape CUPPA_SHAPE_* constants defined above.
+ (NSString *)labelForShape:(int)shape;

// Returns a shape constant from a (non human interface) label returned by LabelForShape:.
// Returns CUPPA_SHAPE_DEFAULT if the label string is not recognised.
+ (int)shapeForLabel:(NSString *)label;

@end // @interface Cuppa_Shape

// *************************************************************************************************

#endif // _CUPPA_SHAPE_H

// end Cuppa_Shape.h
