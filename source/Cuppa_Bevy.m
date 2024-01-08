/*
 **************************************************************************************************
 Package:  Cuppa
 Class:    Cuppa_Bevy
           - The Bevy class tracks information about a single beverage, such as name and brew time.
 ----------------------------------------------------------------------------------------------------
 Copyright (c) 2005-2024 Nathan Cosgray. All rights reserved.
 
 This source code is licensed under the BSD-style license found in LICENSE.txt.
 **************************************************************************************************
 */

// OSX Includes

#import <Foundation/Foundation.h>

// Cuppa Includes

#import "Cuppa_Bevy.h"
#import "Cuppa_Shape.h"

// Code!

@implementation Cuppa_Bevy
;

// *************************************************************************************************

// Return an array of the default set of beverages.
+ (NSMutableArray *)defaultBevys
{
    NSMutableArray *bevys;
    Cuppa_Bevy *bevy[8];
    
    // create an empty array
    bevys = [NSMutableArray array];
    
    // Blackcurrant Tea
    bevy[0] = [[[Cuppa_Bevy alloc] init] autorelease];
    [bevy[0] setName:NSLocalizedString(@"Blackcurrant Tea", nil)];
    [bevy[0] setBrewTime:210];
    [bevy[0] setCupShape:CUPPA_SHAPE_TEA];
    [bevys addObject:bevy[0]];
    
    // Chamomile
    bevy[1] = [[[Cuppa_Bevy alloc] init] autorelease];
    [bevy[1] setName:NSLocalizedString(@"Chamomile", nil)];
    [bevy[1] setBrewTime:300];
    [bevy[1] setCupShape:CUPPA_SHAPE_TEA];
    [bevys addObject:bevy[1]];
    
    // Earl Grey
    bevy[2] = [[[Cuppa_Bevy alloc] init] autorelease];
    [bevy[2] setName:NSLocalizedString(@"Earl Grey", nil)];
    [bevy[2] setBrewTime:240];
    [bevy[2] setCupShape:CUPPA_SHAPE_TEA];
    [bevys addObject:bevy[2]];
    
    // English Breakfast
    bevy[3] = [[[Cuppa_Bevy alloc] init] autorelease];
    [bevy[3] setName:NSLocalizedString(@"English Breakfast", nil)];
    [bevy[3] setBrewTime:240];
    [bevy[3] setCupShape:CUPPA_SHAPE_TEA];
    [bevys addObject:bevy[3]];
    
    // Green Tea
    bevy[4] = [[[Cuppa_Bevy alloc] init] autorelease];
    [bevy[4] setName:NSLocalizedString(@"Green Tea", nil)];
    [bevy[4] setBrewTime:150];
    [bevy[4] setCupShape:CUPPA_SHAPE_TEA];
    [bevys addObject:bevy[4]];
    
    // Mint Tea
    bevy[5] = [[[Cuppa_Bevy alloc] init] autorelease];
    [bevy[5] setName:NSLocalizedString(@"Libby's Mint Tea", nil)];
    [bevy[5] setBrewTime:240];
    [bevy[5] setCupShape:CUPPA_SHAPE_TEA];
    [bevys addObject:bevy[5]];
    
    // Oolong Tea
    bevy[6] = [[[Cuppa_Bevy alloc] init] autorelease];
    [bevy[6] setName:NSLocalizedString(@"Oolong Tea", nil)];
    [bevy[6] setBrewTime:240];
    [bevy[6] setCupShape:CUPPA_SHAPE_TEA];
    [bevys addObject:bevy[6]];
    
    // Rooibos
    bevy[7] = [[[Cuppa_Bevy alloc] init] autorelease];
    [bevy[7] setName:NSLocalizedString(@"Rooibos", nil)];
    [bevy[7] setBrewTime:180];
    [bevy[7] setCupShape:CUPPA_SHAPE_TEA];
    [bevys addObject:bevy[7]];
    
    // return the array of standard bevys
    return bevys;
    
} // end +defaultBevys

// *************************************************************************************************

// Convert an array of beverages to an array of dictionaries, to allow user defaults storage.
+ (NSMutableArray *)toDictionary:(NSArray *)bevyArray
{
    // We could just uses dictionary objects to store all the Cuppa_Bevy info, but I'm against it
    // on principle ;-) As soon as the object becomes a little more complex, it wouldn't be a good
    // choice. Even now it would reduce the amount of runtime checking. So here we go...
    // (BTW, what would be cool is if any object conforming to NSCoding could be stored into the
    // defaults... but it was not to be.
    
    int i; // loop counter
    NSMutableArray *dictArray; // array of dictionarys
    NSMutableDictionary *dict; // dictionary object
    Cuppa_Bevy *bevy; // beverage object
    
    dictArray = [NSMutableArray array];
    for (i = 0; i < [bevyArray count]; i++)
    {
        bevy = [bevyArray objectAtIndex:i];
        dict = [NSMutableDictionary dictionary];
        [dict setObject:[bevy name] forKey:@"name"];
        [dict setObject:[NSNumber numberWithInt:[bevy brewTime]] forKey:@"brewTime"];
        [dict setObject:[Cuppa_Shape labelForShape:[bevy cupShape]] forKey:@"cupShape"];
        [dictArray addObject:dict];
    }
    
    return dictArray;
    
} // end +toDictionary:

// *************************************************************************************************

// Convert an array of beverages from an array of dictionaries, to allow user defaults retrieval.
+ (NSMutableArray *)fromDictionary:(NSArray *)dictArray
{
    int i; // loop counter
    NSMutableArray *bevyArray; // array of Cuppa_Bevys
    NSDictionary *dict; // dictionary object
    Cuppa_Bevy *bevy; // beverage object
    
    bevyArray = [NSMutableArray array];
    for (i = 0; i < [dictArray count]; i++)
    {
        dict = [dictArray objectAtIndex:i];
        bevy = [[[Cuppa_Bevy alloc] init] autorelease];
        [bevy setName:[dict objectForKey:@"name"]];
        [bevy setBrewTime:[[dict objectForKey:@"brewTime"] intValue]];
        [bevy setCupShape:[Cuppa_Shape shapeForLabel:[dict objectForKey:@"cupShape"]]];
        [bevyArray addObject:bevy];
    }
    
    return bevyArray;
    
} // end +fromDictionary:

// *************************************************************************************************

// Default initializer.
- (id)init
{
    self = [super init];
    mName = [[NSString alloc] init];
    mBrewTime = CUPPA_BEVY_BREW_TIME_MIN;
    mCupShape = 0;
    return self;
    
} // end -init

// *************************************************************************************************

// Deallocate.
- (void)dealloc
{
    // release our hold on the name string
    [mName release];
    [super dealloc];
    
} // end -dealloc

// *************************************************************************************************

// Returns the name of this bevy.
- (NSString *)name
{
    // return requested info
    return mName;
    
} // end -name

// *************************************************************************************************

// Sets the name of this bevy.
- (void)setName:(NSString *)name
{
    // parameter checks
    NSAssert(name != nil, @"Bad name parameter.\n");
    
    // record new info
    [mName release];
    mName = name;
    [mName retain];
    
} // end -setName:

// *************************************************************************************************

// Returns the brew time of this bevy.
- (int)brewTime
{
    // return requested info
    return mBrewTime;
    
} // end -brewTime

// *************************************************************************************************

// Sets the name of this bevy.
- (void)setBrewTime:(int)brewTime
{
    // parameter checks
    NSAssert(brewTime >= CUPPA_BEVY_BREW_TIME_MIN, @"Brew time too short.\n");
    NSAssert(brewTime <= CUPPA_BEVY_BREW_TIME_MAX, @"Brew time too long.\n");
    
    // record new info
    mBrewTime = brewTime;
    
} // end -setBrewTime:

// *************************************************************************************************

// Returns the cup shape of this bevy.
- (int)cupShape
{
    // return requested info
    return mCupShape;
    
} // end -cupShape

// *************************************************************************************************

// Sets the name of this bevy.
- (void)setCupShape:(int)cupShape
{
    // parameter checks
    NSAssert(cupShape >= 0, @"Cup shape index < 0.\n");
    NSAssert(cupShape < CUPPA_SHAPE_MAX, @"Cup shape index >= MAX.\n");
    
    // record new info
    mCupShape = cupShape;
    
} // end -setCupShape:

// *************************************************************************************************

@end // @implementation Cuppa_Bevy

// end Cuppa_Bevy.m
