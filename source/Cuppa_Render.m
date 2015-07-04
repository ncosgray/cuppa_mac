/***************************************************************************************************

Classification:	Obj-C, OSX, Std-C

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


// OSX Includes

#import <Carbon/Carbon.h>


// Cuppa Includes

#import "Cuppa_Shape.h"
#import "Cuppa_Render.h"
#import "Cuppa_Bevy.h"


// Internal C Prototypes

// Dummy function to release image data after CGImageCreate().
static void releaseData(void *info, const void *data, size_t size);


// Code!

@implementation Cuppa_Render

// *************************************************************************************************


// Set the cup shape.
// Param cupShape must be one of the shape CUPPA_SHAPE_* constants defined in Cuppa_Shape.h.
- (void) setCupShape : (int) cupShape
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
- (void) setBrewState : (float) brewState
{
	// parameter checks
	NSAssert(brewState >= 0.0, @"-setBrewState: brewState too low");
	NSAssert(brewState <= 1.0, @"-setBrewState: brewState too high");
	
	// store the new state, image will change on next call to -render
	mBrewState = brewState;
    
} // end -setBrewState:


// *************************************************************************************************


// Set the brewing time.
- (void) setBrewRemain : (int) brewRemain
{
	// parameter checks
	NSAssert(brewRemain >= 0, @"-setBrewRemain: brewRemain too low");
	
	// store the new time counter, image will change on next call to -render
	mBrewRemain = brewRemain;
    
} // end -setBrewRemain:


// *************************************************************************************************


// Render the interface in its current state. No state changes will be visible until this call.
// Removed the tea darkening compositing on the dock icon for Snow Leopard compatibility.
// Some of this routine comes from Apple's DockBrowser example and other sources online.
- (void) render
{
	int hours;
    int digits;
	char countString[8];
    CGImageRef badgeImage = NULL;
    int previousDigits = 0;
    CGContextRef cgContext;
	
	// Load icon images.
    CGImageRef iconImage = MyCreateCGImageFromPNG(CFSTR("tea_start.png"));
    CGImageRef endImage = MyCreateCGImageFromPNG(CFSTR("tea_end.png"));
	
	if (mBrewRemain > 0)
	{		
		// Limit the maximum number of digits displayed on dock tile.
		if(mBrewRemain > CUPPA_BEVY_BREW_TIME_MAX)
		{
			mBrewRemain = CUPPA_BEVY_BREW_TIME_MAX;
		}
				
		// Convert seconds into a time string of format 'hh:mm:ss' or 'mm:ss'.
		hours = mBrewRemain / 3600;
		if(hours > 0)
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
		
		// NB.
		// On 10.5 and later, we can use 'setBadgeLabel' method to set a badge label very easily:
		//   [[[NSApplication sharedApplication] dockTile] setBadgeLabel:
		//    [NSString stringWithFormat:@"%s", countString]];
		// For now I would like to support 10.4 and later, so let's do it the hard way and
		// draw the badge manually.

		// Decide what size badge to use according to number of digits left in time.
        digits = strlen(countString);		
        if (badgeImage == NULL || digits != previousDigits) {
            
            if (digits != previousDigits && badgeImage != NULL) {
                CGImageRelease(badgeImage);
            }
            
            switch (digits) {
				case 1:
				case 2:
                case 3:
				case 4:
                    badgeImage = MyCreateCGImageFromPNG(CFSTR("Badge3.png"));
                    break;
				case 5:
                    badgeImage = MyCreateCGImageFromPNG(CFSTR("Badge4.png"));
                    break;
                default:
                    badgeImage = MyCreateCGImageFromPNG(CFSTR("Badge5.png"));
                    break;
            }
			
            previousDigits = digits;
        }

        // Modifications to the dock icon while brewing:
		// 1) Add a tea bag to the cup
		// 2) Gradually darken the color of the tea
		// 3) Show a countdown timer badge
		cgContext = BeginCGContextForApplicationDockTile();
		if (cgContext) {
		
			const CGRect iconRect = CGRectMake(0, 0, 128, 128);
			static const CGPoint lowerRightForBadge = { 128.0, 97.0 };
			CGRect badgeRect;
			CGPoint textLocation, badgeLocation;
			NSSize numSize;
			
			// Use tea brewing icon.
			CGContextClearRect(cgContext, iconRect);
			CGContextDrawImage(cgContext, iconRect, iconImage);
			
			// Change tea color according to brew state.
			if (mBrewState < 1.0 && mBrewState > 0.0)
			{
				CGContextBeginTransparencyLayer(cgContext, NULL);
				CGContextSetBlendMode(cgContext, kCGBlendModeDarken);
				CGContextSetAlpha(cgContext, mBrewState);
				CGContextDrawImage(cgContext, iconRect, endImage);
				CGContextEndTransparencyLayer(cgContext);
			}
			
			// Add countdown timer to dock icon.
			if (mBrewRemain >= 0 && badgeImage) {
			
				// Draw the badge.
				badgeLocation = lowerRightForBadge;
				badgeLocation.x -= CGImageGetWidth(badgeImage);
				badgeRect = CGRectMake(badgeLocation.x, badgeLocation.y, CGImageGetWidth(badgeImage), CGImageGetHeight(badgeImage));
				CGContextDrawImage(cgContext, badgeRect, badgeImage);
				
				// Measure the width of the count string so we can center it inside the badge.
				NSString *countdown = [NSString stringWithFormat:@"%s", countString];
				NSDictionary *attributes = [[NSDictionary alloc]
								initWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica-Bold" size:29.0],
								NSFontAttributeName, [NSColor whiteColor],
								NSForegroundColorAttributeName, NULL];
				numSize = [countdown sizeWithAttributes:attributes];
				textLocation.y = badgeLocation.y + CGImageGetHeight(badgeImage) / 2 - 10;
				textLocation.x = badgeLocation.x + CGImageGetWidth(badgeImage) / 2 - numSize.width / 2;
				[attributes release];
				
				// Draw the countdown time in the badge.
				// Use Core Graphics because that's the way we drew the badge. I never claimed to be a great programmer...
				CGContextSetTextDrawingMode(cgContext, kCGTextFill);
				CGContextSetRGBFillColor(cgContext, 1, 1, 1, 1);
				CGContextSelectFont(cgContext, "Helvetica-Bold", 29.0, kCGEncodingMacRoman);
				CGContextShowTextAtPoint(cgContext, textLocation.x, textLocation.y, countString, strlen(countString));
				
			}
			
			// Make the updates to the icon visible.
			CGContextFlush(cgContext);
			EndCGContextForApplicationDockTile(cgContext);
		}
	}
	else RestoreApplicationDockTileImage();
    
	// Clean up.
	if (badgeImage != NULL) CGImageRelease(badgeImage);
    CGImageRelease(iconImage);
    CGImageRelease(endImage);
	
    return;
		
} // end -render


// *************************************************************************************************


// Create CoreGraphics image from PNG resource (shamelessly lifted from Apple's DockBrowser example).
static CGImageRef MyCreateCGImageFromPNG(CFStringRef fileName)
{
    CGImageRef image;
    CFBundleRef bundle;
    CGDataProviderRef myProvider;
    CFURLRef url;
    
    assert(fileName != NULL);
    
    bundle = CFBundleGetMainBundle();
    assert(bundle != NULL);
    
    url = CFBundleCopyResourceURL(bundle, fileName, NULL, NULL);
    assert(url != NULL);
    
    myProvider = CGDataProviderCreateWithURL(url);
    assert(myProvider != NULL);
    
    image = CGImageCreateWithPNGDataProvider(myProvider, NULL, false, kCGRenderingIntentDefault);
    
    CGDataProviderRelease(myProvider);
    CFRelease(url);
    
    return image;
} // end MyCreateCGImageFromPNG


// *************************************************************************************************


// Restore the standard Cuppa dock tile (must call this on application exit).
- (void) restore
{
	// We can use this Carbon method to restore our application dock tile to its default.
	// The docs are actually a little unclear on whether this is required (eg, see the notes
	// on SetApplicationDockTileImage()) but experimentations says we have to...
	RestoreApplicationDockTileImage();

} // end -restore


// *************************************************************************************************


// Returns the current cup shape.
- (int) cupShape
{
	// return the requested info
	return mCupShape;
	
} // end -cupShape


// *************************************************************************************************


// Dummy function to release image data after CGImageCreate().
static void releaseData(void *info, const void *data, size_t size)
{
} // end releaseData()


// *************************************************************************************************

@end // @implementation Cuppa_Render

// end Cuppa_Render.m
