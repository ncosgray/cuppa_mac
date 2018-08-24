/*
 **************************************************************************************************
 Package:  Cuppa
 Class:    Cuppa_Render
           - Handles rendering and render state management for the Cuppa dock icon.
 ----------------------------------------------------------------------------------------------------
 Copyright (c) 2005-2018 Nathan Cosgray. All rights reserved.
 
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

#import <Carbon/Carbon.h>

// Cuppa Includes

#import "Cuppa_Bevy.h"
#import "Cuppa_Render.h"
#import "Cuppa_Shape.h"

// Code!

@implementation Cuppa_Render

// *************************************************************************************************

// Set the cup shape.
// Param cupShape must be one of the shape CUPPA_SHAPE_* constants defined in Cuppa_Shape.h.
- (void)setCupShape:(int)cupShape
{
    // parameter checks
    NSAssert(cupShape >= 0, @"Cup shape index < 0.\n");
    NSAssert(cupShape < CUPPA_SHAPE_MAX, @"Cup shape index >= MAX.\n");
    
    // store the new state, image will change on next call to -render
    mCupShape = cupShape;
    
} // end -setCupShape:

// *************************************************************************************************

// Set the brew state.
// Param brewState must be in the range [0, 1], where 0 is the start of the steeping cycle,
//   and 1 represents completion.
- (void)setBrewState:(float)brewState
{
    // parameter checks
    NSAssert(brewState >= 0.0, @"-setBrewState: brewState too low");
    NSAssert(brewState <= 1.0, @"-setBrewState: brewState too high");
    
    // store the new state, image will change on next call to -render
    mBrewState = brewState;
    
} // end -setBrewState:

// *************************************************************************************************

// Set the brewing time.
- (void)setBrewRemain:(int)brewRemain
{
    // parameter checks
    NSAssert(brewRemain >= 0, @"-setBrewRemain: brewRemain too low");
    
    // store the new time counter, image will change on next call to -render
    mBrewRemain = brewRemain;
    
} // end -setBrewRemain:

// *************************************************************************************************

// Render the interface in its current state. No state changes will be visible until this call.
- (void)render
{
    int hours;
    char countString[8];
    
    if (mBrewRemain > 0)
    {
        // Convert seconds into a time string of format 'hh:mm:ss' or 'mm:ss'.
        hours = mBrewRemain / 3600;
        if (hours > 0)
        {
            sprintf(countString, "%01d:%02d:%02d",
                    hours,
                    (mBrewRemain - (hours * 3600)) / 60,
                    (mBrewRemain - (hours * 3600)) % 60);
        }
        else
        {
            sprintf(countString, "%01d:%02d",
                    mBrewRemain / 60,
                    mBrewRemain % 60);
        }
        
        // Add a badge to the dock icon.
        [[[NSApplication sharedApplication] dockTile] setBadgeLabel:
         [NSString stringWithFormat:@"%s", countString]];
    }
    else
        [[[NSApplication sharedApplication] dockTile] setBadgeLabel:nil];
    
    return;
    
} // end -render

// *************************************************************************************************

// Restore the standard Cuppa dock tile (must call this on application exit).
- (void)restore
{
    // Remove badge
    [[[NSApplication sharedApplication] dockTile] setBadgeLabel:nil];
    
} // end -restore

// *************************************************************************************************

// Returns the current cup shape.
- (int)cupShape
{
    // return the requested info
    return mCupShape;
    
} // end -cupShape

// *************************************************************************************************

@end // @implementation Cuppa_Render

// end Cuppa_Render.m
