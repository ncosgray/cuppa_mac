/*
 **************************************************************************************************
 Package:  Cuppa
 Class:    Cuppa_Shape
           - Constants for cup shape types and associated abstract support class.
 ----------------------------------------------------------------------------------------------------
 Copyright (c) 2005-2021 Nathan Cosgray. All rights reserved.
 
 This source code is licensed under the BSD-style license found in LICENSE.txt.
 **************************************************************************************************
 */

// OSX Includes

#import <Foundation/Foundation.h>

// Cuppa Includes

#import "Cuppa_Shape.h"

// Internal Constants

static NSString *sLabels[] =
{
    @"default",
    @"tea",
    @"mug",
    @"noodle"};

// Code!

@implementation Cuppa_Shape
;

// *************************************************************************************************

// Returns a (non human interface) string which represents the shape.
// Param shape must be on of the shape CUPPA_SHAPE_* constants defined above.
+ (NSString *)labelForShape:(int)shape
{
    // parameter checks
    NSAssert(shape >= 0, @"Cup shape index < 0.\n");
    NSAssert(shape < CUPPA_SHAPE_MAX, @"Cup shape index >= MAX.\n");
    
    // return label string
    return sLabels[shape];
    
} // end +labelForShape:

// *************************************************************************************************

// Returns a shape constant from a (non human interface) label returned by LabelForShape:.
// Returns CUPPA_SHAPE_DEFAULT if the label string is not recognised.
+ (int)shapeForLabel:(NSString *)label
{
    int i; // loop counter
    
    // parameter checks
    NSAssert(label != nil, @"Bad label parameter.");
    
    // check for label matchs
    for (i = 0; i < CUPPA_SHAPE_MAX; i++)
    {
        if ([label isEqualToString:sLabels[i]])
            return i;
    }
    
    // match not found! fallback to default
    return CUPPA_SHAPE_DEFAULT;
    
} // end +shapeForLabel:

// *************************************************************************************************

@end // @implementation Cuppa_Shape

// end Cuppa_Shape.m
