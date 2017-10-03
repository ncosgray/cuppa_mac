/***************************************************************************************************

Classification:	Obj-C, OSX, StdC

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
***************************************************************************************************/


// OSX Includes

#import <Foundation/Foundation.h>


// Cuppa Includes

#import "Cuppa_Shape.h"
#import "Cuppa_Bevy.h"


// Code!

@implementation Cuppa_Bevy;

// *************************************************************************************************


// Return an array of the default set of beverages.
+ (NSMutableArray *) defaultBevys
{
	NSMutableArray *bevys;
	Cuppa_Bevy *bevy[4];
	
	// create an empty array
	bevys = [NSMutableArray array];
	
	// Blackcurrent Tea
	bevy[0] = [[[Cuppa_Bevy alloc] init] autorelease];
	[bevy[0] setName:NSLocalizedString(@"Blackcurrant Tea", nil)];
	[bevy[0] setBrewTime:210];
	[bevy[0] setCupShape:CUPPA_SHAPE_TEA];
	[bevys addObject:bevy[0]];
    
	// Earl Grey Tea
	bevy[1] = [[[Cuppa_Bevy alloc] init] autorelease];
	[bevy[1] setName:NSLocalizedString(@"Earl Grey", nil)];
	[bevy[1] setBrewTime:240];
	[bevy[1] setCupShape:CUPPA_SHAPE_TEA];
	[bevys addObject:bevy[1]];
    
	// Mint Tea
	bevy[2] = [[[Cuppa_Bevy alloc] init] autorelease];
	[bevy[2] setName:NSLocalizedString(@"Libby's Mint Tea", nil)];
	[bevy[2] setBrewTime:240];
	[bevy[2] setCupShape:CUPPA_SHAPE_TEA];
	[bevys addObject:bevy[2]];
    
	// Rooibos
	bevy[3] = [[[Cuppa_Bevy alloc] init] autorelease];
	[bevy[3] setName:NSLocalizedString(@"Rooibos", nil)];
	[bevy[3] setBrewTime:180];
	[bevy[3] setCupShape:CUPPA_SHAPE_TEA];
	[bevys addObject:bevy[3]];
	
	// return the array of standard bevys
	return bevys;

} // end +defaultBevys


// *************************************************************************************************


// Convert an array of beverages to an array of dictionaries, to allow user defaults storage.
+ (NSMutableArray *) toDictionary : (NSArray *) bevyArray
{
	// We could just uses dictionary objects to store all the Cuppa_Bevy info, but I'm against it
	// on principle ;-) As soon as the object becomes a little more complex, it wouldn't be a good
	// choice. Even now it would reduce the amount of runtime checking. So here we go...
	// (BTW, what would be cool is if any object conforming to NSCoding could be stored into the
	// defaults... but it was not to be.
	
	int i;						// loop counter
	NSMutableArray *dictArray;	// array of dictionarys
	NSMutableDictionary *dict;	// dictionary object
	Cuppa_Bevy *bevy;			// beverage object
	
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
+ (NSMutableArray *) fromDictionary : (NSArray *) dictArray
{
	int i;						// loop counter
	NSMutableArray *bevyArray;	// array of Cuppa_Bevys
	NSDictionary *dict;			// dictionary object
	Cuppa_Bevy *bevy;			// beverage object
	
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
- (id) init
{
	self = [super init];
	mName = [[NSString alloc] init];
	mBrewTime = CUPPA_BEVY_BREW_TIME_MIN;
    mCupShape = 0;
    return self;
	
} // end -init


// *************************************************************************************************


// Deallocate.
- (void) dealloc
{
	// release our hold on the name string
	[mName release];
    [super dealloc];
   
} // end -dealloc


// *************************************************************************************************


// Returns the name of this bevy.
- (NSString *) name
{
	// return requested info
	return mName;

} // end -name


// *************************************************************************************************


// Sets the name of this bevy.
- (void) setName : (NSString *) name
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
- (int) brewTime
{
	// return requested info
	return mBrewTime;

} // end -brewTime


// *************************************************************************************************


// Sets the name of this bevy.
- (void) setBrewTime : (int) brewTime
{
	// parameter checks
	NSAssert(brewTime >= CUPPA_BEVY_BREW_TIME_MIN, @"Brew time too short.\n");
	NSAssert(brewTime <= CUPPA_BEVY_BREW_TIME_MAX, @"Brew time too long.\n");
	
	// record new info
	mBrewTime = brewTime;

} // end -setBrewTime:


// *************************************************************************************************


// Returns the cup shape of this bevy.
- (int) cupShape
{
	// return requested info
	return mCupShape;

} // end -cupShape


// *************************************************************************************************


// Sets the name of this bevy.
- (void) setCupShape : (int) cupShape
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
