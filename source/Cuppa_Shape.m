/*
 **************************************************************************************************
 Package:  Cuppa
 Class:    Cuppa_Shape
           - Constants for cup shape types and associated abstract support class.
 ----------------------------------------------------------------------------------------------------
 Copyright (c) 2005-2017 Nathan Cosgray. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted
 provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice, this list of
 conditions and the following disclaimer in the documentation and/or other materials provided with
 the distribution.
 
 3.  Neither the name of the Nathanatos Software nor the names of its contributors may be used to
 endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COMPANY OR CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
 THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
