/*
 **************************************************************************************************
 Package:  Cuppa
 Class:    Cuppa_Shape
           - Constants for cup shape types and associated abstract support class.
 ----------------------------------------------------------------------------------------------------
 Copyright (c) 2005-2026 Nathan Cosgray. All rights reserved.
 
 This source code is licensed under the BSD-style license found in LICENSE.txt.
 **************************************************************************************************
 */

// OSX Includes

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

// Cuppa Includes

#import "Cuppa_Shape.h"

// Internal Constants

static NSString *sLabels[] =
{
    @"default",
    @"cup",
    @"flower"};

static NSString * const CuppaShapeImageNames[] = {
    @"QuickAction",        // CUPPA_SHAPE_DEFAULT = 0
    @"QuickActionCup",     // CUPPA_SHAPE_CUP
    @"QuickActionFlower",  // CUPPA_SHAPE_FLOWER
};

// Code!

@implementation Cuppa_Shape
;

// *************************************************************************************************

// Returns a (non human interface) string which represents the shape.
// Returns CUPPA_SHAPE_DEFAULT if the shape is not recognized.
+ (NSString *)labelForShape:(int)shape
{
    // parameter checks - return default if not found (for backwards compatibility)
    if (shape < 0 || shape >= CUPPA_SHAPE_MAX)
        shape = CUPPA_SHAPE_DEFAULT;

    // return label string
    return sLabels[shape];
    
} // end +labelForShape:

// *************************************************************************************************

// Returns a shape constant from a (non human interface) label returned by LabelForShape:.
// Returns CUPPA_SHAPE_DEFAULT if the label string is not recognized.
+ (int)shapeForLabel:(NSString *)label
{
    int i; // loop counter
    
    // parameter checks - return default if nil (for backwards compatibility)
    if (label == nil)
        return CUPPA_SHAPE_DEFAULT;
    
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

// Returns an image which represents the shape.
// Returns CUPPA_SHAPE_DEFAULT if the shape is not recognized.
+ (NSImage *)imageForShape:(int)shape
{
    // parameter checks - return default if not found (for backwards compatibility)
    if (shape < 0 || shape >= CUPPA_SHAPE_MAX)
        shape = CUPPA_SHAPE_DEFAULT;

    NSImage *image = [NSImage imageNamed:CuppaShapeImageNames[shape]];
    [image setSize:NSMakeSize(16, 16)];
    return image;
}

// *************************************************************************************************

@end // @implementation Cuppa_Shape

// end Cuppa_Shape.m
