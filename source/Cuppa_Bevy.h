/*
 **************************************************************************************************
 Package:  Cuppa
 Class:    Cuppa_Bevy
           - The Bevy class tracks information about a single beverage, such as name and brew time.
 ----------------------------------------------------------------------------------------------------
 Copyright (c) 2005-2020 Nathan Cosgray. All rights reserved.
 
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

#ifndef _CUPPA_BEVY_H
#define _CUPPA_BEVY_H

#if !defined(__OBJC__)
#error "Objective-C only source file."
#endif

// OSX Includes

#import <Foundation/Foundation.h>

// Cuppa Includes

#import "Cuppa_Shape.h"

// Constants

enum
{
    CUPPA_BEVY_BREW_TIME_MIN = 10, // 00:10
    CUPPA_BEVY_BREW_TIME_MAX = 35999 // 9:59:59
};

// Class Interface

@interface Cuppa_Bevy : NSObject
{
    NSString *mName; // name of the beverage
    int mBrewTime; // brew time of the bevy in seconds
    int mCupShape; // cup shape of bevy, one of the CUPPA_SHAPE_* constants in Cuppa_Shape.h
}

// ------ Classs Methods ------

// Return a array of the default set of beverages.
+ (NSMutableArray *)defaultBevys;

// Convert an array of beverages to an array of dictionaries, to allow user defaults storage.
+ (NSMutableArray *)toDictionary:(NSArray *)bevyArray;

// Convert an array of beverages from an array of dictionaries, to allow user defaults retrieval.
+ (NSMutableArray *)fromDictionary:(NSArray *)dictArray;

// ------ Life Cycle ------

// Default initializer.
- (id)init;

// Deallocate.
- (void)dealloc;

// ------ Manipulators ------

// Sets the name of this bevy.
- (void)setName:(NSString *)name;

// Sets the name of this bevy.
- (void)setBrewTime:(int)brewTime;

// Sets the name of this bevy.
- (void)setCupShape:(int)cupShape;

// ------ Accessors ------

// Returns the name of this bevy.
- (NSString *)name;

// Returns the brew time of this bevy.
- (int)brewTime;

// Returns the cup shape of this bevy.
- (int)cupShape;

@end // @interface Cuppa_Bevy

// *************************************************************************************************

#endif // _CUPPA_BEVY_H

// end Cuppa_Bevy.h
