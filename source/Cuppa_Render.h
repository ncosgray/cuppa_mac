/***************************************************************************************************

Package:		Cuppa
Classification:	Obj-C, OSX
Primary Class:	Cuppa_Render
Other Classes:	-
Pattern:		Concrete.
Thread Safety:	Non thread safe.

Handles rendering and render state management for the Cuppa dock icon.

----------------------------------------------------------------------------------------------------

Copyright (c) 2005-2009 Nathan Cosgray. All rights reserved.

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
***************************************************************************************************/


#ifndef _CUPPA_RENDER_H
#define _CUPPA_RENDER_H

#if !defined(__OBJC__)
#error "Objective-C only source file."
#endif


// OSX Includes

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>


// Class Interface

@interface Cuppa_Render : NSObject
{
	int mCupShape;		// what kind of cuppa are we using (one of CUPPA_RENDER_SHAPE_*).
	float mBrewState;	// what brew state are we in?
    int mBrewRemain;    // brewing time remaining
}


// ------ Manipulators ------

// Set the cup shape.
// Param cupShape must be one of the shape CUPPA_SHAPE_* constants defined in Cuppa_Shape.h.
- (void) setCupShape : (int) cupShape;

// Set the brew state.
// Param brewState must be in the range [0, 1], where 0 is the start of the steeping cycle,
//   and 1 represents completion.
- (void) setBrewState : (float) brewState;

// Set the brew time remaining.
- (void) setBrewRemain : (int) brewRemain;

// ------ Accessors ------

// Render the interface in it's current state. No state changes will be visible until this call.
- (void) render;

// Restore the standard Cuppa dock tile (must call this on application exit).
- (void) restore;

// Returns the current cup shape.
- (int) cupShape;

// Create CoreGraphics image from PNG resource (shamelessly lifted from Apple's DockBrowser example).
static CGImageRef MyCreateCGImageFromPNG(CFStringRef fileName);

@end // @interface Cuppa_Render


// *************************************************************************************************

#endif // _CUPPA_RENDER_H

// end Cuppa_Render.h
