/*
 **************************************************************************************************
 Package:  Cuppa
 Class:    Cuppa_Render
           - Handles rendering and render state management for the Cuppa dock icon.
 ----------------------------------------------------------------------------------------------------
 Copyright (c) 2005-2021 Nathan Cosgray. All rights reserved.
 
 This source code is licensed under the BSD-style license found in LICENSE.txt.
 **************************************************************************************************
 */

#ifndef _CUPPA_RENDER_H
#define _CUPPA_RENDER_H

#if !defined(__OBJC__)
#error "Objective-C only source file."
#endif

// OSX Includes

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

// Class Interface

@interface Cuppa_Render : NSObject
{
    int mCupShape; // what kind of cuppa are we using (one of CUPPA_RENDER_SHAPE_*).
    float mBrewState; // what brew state are we in?
    int mBrewRemain; // brewing time remaining
}

// ------ Manipulators ------

// Set the cup shape.
// Param cupShape must be one of the shape CUPPA_SHAPE_* constants defined in Cuppa_Shape.h.
- (void)setCupShape:(int)cupShape;

// Set the brew state.
// Param brewState must be in the range [0, 1], where 0 is the start of the steeping cycle,
//   and 1 represents completion.
- (void)setBrewState:(float)brewState;

// Set the brew time remaining.
- (void)setBrewRemain:(int)brewRemain;

// ------ Accessors ------

// Render the interface in it's current state. No state changes will be visible until this call.
- (void)render;

// Restore the standard Cuppa dock tile (must call this on application exit).
- (void)restore;

// Returns the current cup shape.
- (int)cupShape;

@end // @interface Cuppa_Render

// *************************************************************************************************

#endif // _CUPPA_RENDER_H

// end Cuppa_Render.h
