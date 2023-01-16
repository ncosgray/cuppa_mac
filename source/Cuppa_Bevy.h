/*
 **************************************************************************************************
 Package:  Cuppa
 Class:    Cuppa_Bevy
           - The Bevy class tracks information about a single beverage, such as name and brew time.
 ----------------------------------------------------------------------------------------------------
 Copyright (c) 2005-2023 Nathan Cosgray. All rights reserved.
 
 This source code is licensed under the BSD-style license found in LICENSE.txt.
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
