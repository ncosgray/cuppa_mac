/***************************************************************************************************

Classification:	Obj-C, OSX, StdC

----------------------------------------------------------------------------------------------------

Copyright (c) 2005-2013 Nathan Cosgray. All rights reserved.

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


// Cuppa Includes

#import "Cuppa_Bevy.h"
#import "Cuppa_Control.h"


// Code!

@interface Cuppa_Control (CuppaGrowl)
- (void) notifyGrowl;
@end


@implementation Cuppa_Control;

// *************************************************************************************************


// Initialise Cuppa_Control object.
- (id) init {

	NSMutableDictionary *appDefaults;	// dictionary of these application defaults
	NSUserDefaults *defaults;			// user defaults object used to store preferences
	NSMethodSignature *sig;				// used to setup update timer
	NSInvocation *inv;					// ditto
    
	// chain up to superclass
    self = [super init];
    
	// create the render object to do our dirty work
	mRender = [[Cuppa_Render alloc] init];

	// additional bevy table setup
	[mBevyTable setVerticalMotionCanBeginDrag:true];

    // determine if OS X Notification Center is available on system
    mOSXNofifyAvail = (NSClassFromString(@"NSUserNotificationCenter") != nil);
    
    // determine if Growl is installed on system
    mGrowlInstalled = [GrowlApplicationBridge isGrowlRunning];  // isGrowlInstalled deprecated as of Growl 1.3
    if (mGrowlInstalled)
    {
        [GrowlApplicationBridge setGrowlDelegate:self];
    }
	
	// set application defaults to guarantee our searches will succeed
	defaults = [NSUserDefaults standardUserDefaults];
    appDefaults = [NSMutableDictionary dictionary];
	mBevys = [Cuppa_Bevy defaultBevys];
	[appDefaults setObject:@"YES" forKey:@"bounceIcon"];
	[appDefaults setObject:@"YES" forKey:@"makeSound"];
	[appDefaults setObject:@"YES" forKey:@"showAlert"];
	[appDefaults setObject:@"YES" forKey:@"showTimer"];
	[appDefaults setObject:@"NO" forKey:@"showSteep"];
	[appDefaults setObject:@"NO" forKey:@"notifyOSX"];
    if (mGrowlInstalled)
    {
        [appDefaults setObject:@"YES" forKey:@"notifyGrowl"];
    }
    else
    {
       [appDefaults setObject:@"NO" forKey:@"notifyGrowl"];
    }
	[appDefaults setObject:[Cuppa_Bevy toDictionary:mBevys] forKey:@"bevys"];
    [defaults registerDefaults:appDefaults];
	
	// apply current settings
	mBounceIcon = [defaults boolForKey:@"bounceIcon"];
	mMakeSound = [defaults boolForKey:@"makeSound"];
	mShowAlert = [defaults boolForKey:@"showAlert"];
	mShowTimer = [defaults boolForKey:@"showTimer"];
	mShowSteep = [defaults boolForKey:@"showSteep"];
	mNotifyOSX = [defaults boolForKey:@"notifyOSX"];
	mNotifyGrowl = [defaults boolForKey:@"notifyGrowl"];
	
	mBevys = [Cuppa_Bevy fromDictionary:[defaults objectForKey:@"bevys"]];
	[mBevys retain];
	mDockMenu = nil;
	[self setBevys:mBevys];
    
    // define a generic beverage for the quick timer
	genericbevy = [[Cuppa_Bevy alloc] init];
	[genericbevy setName:@"Cuppa"];
	[genericbevy setBrewTime:120];
    
	// create the brew timer object
	// this is set to fire every second
	// TODO: only run timer when active
	sig = [Cuppa_Control instanceMethodSignatureForSelector:@selector(updateTick:)];
	inv = [NSInvocation invocationWithMethodSignature:sig];
	[inv setSelector:@selector(updateTick:)];
	[inv setTarget:self];

	// TODO: this isn't the smartest design, and should be improved. The timer will fire
	// every second, regardless of whether we are actually brewing anything. This is a
	// (very minor) waste of CPU time.
	mBrewTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 invocation:inv repeats:YES];
    
	// return the initialised object!
    return self;

} // end -init


// *************************************************************************************************


// Handle setup once we've been fully woken.
- (void) awakeFromNib
{
	NSImageCell *imageCell;     // image cell for preference bevy setup images
	NSTableColumn *column;      // column in mBevyTable displaying bevy images
	NSMenu *mMainMenu;          // main menu object
	NSMenuItem *item;			// current menu item
    
	// setup preferences table to display bevy images properly
	imageCell = [[NSImageCell alloc] init];
	[imageCell setImageFrameStyle:NSImageFrameNone];
	[imageCell setImageScaling:NSScaleNone];
	column = [[mBevyTable tableColumns] objectAtIndex:0];
	[column setDataCell:imageCell];
	[imageCell release];
	
	// setup preferences table for drag 'n' drop
	[mBevyTable registerForDraggedTypes:[NSArray arrayWithObjects:@"RowIndexPboardType", nil]];
	
	// ensure settings are up to date
	if ([mBounceSwitch state] != (mBounceIcon ? NSOnState : NSOffState))
	{
		[mBounceSwitch setNextState];
	}

	if ([mSoundSwitch state] != (mMakeSound ? NSOnState : NSOffState))
	{
		[mSoundSwitch setNextState];
	}

	if ([mAlertSwitch state] != (mShowAlert ? NSOnState : NSOffState))
	{
		[mAlertSwitch setNextState];
	}
    
	if ([mTimerSwitch state] != (mShowTimer ? NSOnState : NSOffState))
	{
		[mTimerSwitch setNextState];
	}
    
	if ([mSteepSwitch state] != (mShowSteep ? NSOnState : NSOffState))
	{
		[mSteepSwitch setNextState];
	}
    
    if (!mOSXNofifyAvail)
    {
        [mOSXNotifySwitch setEnabled:NO];
        [mOSXNotifySwitch setState:NSOffState];
    }
	else
    {
        if ([mOSXNotifySwitch state] != (mNotifyOSX ? NSOnState : NSOffState))
        {
            [mOSXNotifySwitch setNextState];
        }
    }
    
    if (!mGrowlInstalled)
    {
       [mGrowlNotifySwitch setEnabled:NO];
       [mGrowlNotifySwitch setState:NSOffState];
    }
    else
    {
       if ([mGrowlNotifySwitch state] != (mNotifyGrowl ? NSOnState : NSOffState))
       {
          [mGrowlNotifySwitch setNextState];
       }
    }
    
    // reset quick timer value
    [mQTimerValue setStringValue:@"2:00"];
    
    // add the Beverages menu to the main menu
    mMainMenu = [NSApp mainMenu];
    item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Beverages", nil) action:nil keyEquivalent:@""];
    [mMainMenu insertItem:item atIndex:1];
    mAppMenu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Beverages", nil)];
    [mMainMenu setSubmenu:mAppMenu forItem:item];
    
    // add a separator
    [mAppMenu insertItem:[NSMenuItem separatorItem] atIndex:0];
    
    // add the quick timer item
    item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Quick Timer...", nil) // TODO: allow localisation
                                      action:@selector(showQuickTimer:) keyEquivalent:@"t"];
    [item setTarget:self];
    [item setEnabled:YES];
    [mAppMenu insertItem:item atIndex:1];
    
    // add the cancel timer item
    item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) // TODO: allow localisation
                                      action:@selector(cancelTimer:) keyEquivalent:@"."];
    [item setTarget:self];
    [item setEnabled:YES];
    [mAppMenu insertItem:item atIndex:2];
    
    // make sure to update the dock menu and the Beverages application menu
    [self setBevys:mBevys];

} // end -awakeFromNib


// *************************************************************************************************


// Handle a tick from the brew timer.
- (void) updateTick : (id) sender
{
    
	// update the brew state
	if (mSecondsRemain > 0)
	{
        
        // tell the OS we are doing something important
        if ([[NSProcessInfo processInfo] respondsToSelector:@selector(beginActivityWithOptions:reason:)])
        {
            timerActivity = [[NSProcessInfo processInfo]
                             beginActivityWithOptions:(NSActivityUserInitiated | NSActivityLatencyCritical)
                             reason:@"Cuppa timer"];
        }
        
		// decrement the brew counter
		// we could be paranoid about timer drift here, but for things that only last a few
		// minutes anyway, it seems pointless to worry
		//--mSecondsRemain;

        mSecondsRemain = floor([mAlarmTime timeIntervalSinceNow]);
        
		// update brew time remaining for countdown timer
        if (mShowTimer)
        {
            [mRender setBrewRemain : mSecondsRemain];
        }
        else
        {
            [mRender setBrewRemain : 0];
        }

		// update brew state
		[mRender setBrewState : ((float) (mSecondsTotal - mSecondsRemain) / (float) mSecondsTotal)];
        [mRender render];

        // emit a beep for the final 5 seconds
        if (mMakeSound && mSecondsRemain <=5 && mSecondsRemain >= 1)
        {
            NSSound *beepSound = [NSSound soundNamed:@"beep"];
            [beepSound play];
        }
        
		// is the bevarage ready?
		if (mSecondsRemain == 0)
		{
            #if !defined(NDEBUG)
			printf("Brew complete!\n");
			#endif
			
			// bounce the dock icon until user clicks (more useful than NSInformationalRequest)
			if (mBounceIcon)
			{
				[NSApp requestUserAttention:NSCriticalRequest];
			}
			
			// play a nice sound
			if (mMakeSound)
			{
				NSSound *doneSound = [NSSound soundNamed:@"spoon"];
				[doneSound play];
			}

            // show a Growl notification
            if (mNotifyGrowl)
            {            
                [self notifyGrowl];
            }
         
            // send a message to OS X Notification Center
            if (mNotifyOSX)
            {
                [self notifyOSX];
            }
            
			// show a little alert window
			if (mShowAlert)
			{
                //if(NSRunAlertPanel (@"Brewing complete...",
				//				 [NSString stringWithFormat:@"%@ is now ready!", [mCurrentBevy name]],
				//				 NULL,
				//				 @"Quit Cuppa",
				//				 NULL,
				//				 NULL) != 1 ) [[NSApplication sharedApplication] terminate:self];
				
				// It's more complicated if we want to allow keyboard shortcuts
				NSAlert *brewAlert = [[[NSAlert alloc] init] autorelease];
				[brewAlert setMessageText:NSLocalizedString(@"Brewing complete...", nil)];
				[brewAlert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"%@ is now ready!", nil), [mCurrentBevy name]]];
				NSButton *okButton = [brewAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
				[okButton setKeyEquivalent:@"\r"];
				NSButton *quitButton = [brewAlert addButtonWithTitle:NSLocalizedString(@"Quit Cuppa", nil)];
				[quitButton setKeyEquivalent:@"q"];
				[quitButton setKeyEquivalentModifierMask:NSCommandKeyMask];
				if ([brewAlert runModal] == NSAlertSecondButtonReturn)
				{
					// User wants to quit, how sad!
					[[NSApplication sharedApplication] terminate:self];
				}
			}
            
            // tell the OS we're done timing
            if (timerActivity != nil)
            {
                [[NSProcessInfo processInfo] endActivity:timerActivity];
            }
            
			// ensure the final image is displayed
			[mRender setBrewState : 0.0f];
		}
		
		// render dock tile, just in case
		[mRender render];

    } // end if
} // end -updateTick:


// *************************************************************************************************


// A particular beverage has been selected for brewing.
- (void) startBrewing : (id) sender
{
	Cuppa_Bevy *bevy;		// matching beverage object
	NSSound *startSound;	// start sound

	// Why do we have to do things this way? Here's what the Apple sample code has to say:
	
	// "This sample shows how to have many dock menu items hooked up to one action method.
	// Because of bug #2751274, on Mac OS X 10.1.x the sender for this action method when called
	// from a dock menu item is always the NSApplication object, not the actual menu item.  This
	// ordinarily makes it impossible to take action based on which menu item was selected, because
	// we don't know which menu item called our action method. We have a workaround in this sample
	// for the bug (using NSInvocations)..."

	// Oh well.. we want to support 10.1 forward, so we'll stick with the work-around.

	// which beverage have they choosen?
	bevy = (Cuppa_Bevy *) [sender representedObject];
	
	if (!bevy)
	{
		// Bother, we didn't find it! This shouldn't happen.
		NSAssert(bevy != nil, @"Could not find matching bevy in array!\n");
		mSecondsRemain = 0;
	}

	// setup the brewing state
	#if !defined(NDEBUG)
	printf("Start brewing %s (%d secs)\n", [[bevy name] cString], [bevy brewTime]);
	#endif
    
	mSecondsTotal = [bevy brewTime];
    mSecondsRemain = mSecondsTotal + 1;
    
    mAlarmTime = [[NSDate alloc] initWithTimeIntervalSinceNow:mSecondsRemain];

	// play the start sound
	if (mMakeSound)
	{
		startSound = [NSSound soundNamed:@"pour"];
		[startSound play];
	}

    mCurrentBevy = bevy;

    // tell the OS we are doing something important... disable App Nap
    if ([[NSProcessInfo processInfo] respondsToSelector:@selector(beginActivityWithOptions:reason:)])
    {
        timerActivity = [[NSProcessInfo processInfo]
                         beginActivityWithOptions:(NSActivityUserInitiated | NSActivityLatencyCritical)
                         reason:@"Cuppa timer"];
    }

	// update the onscreen image
	[self updateTick:self];

} // end -startBrewing:


// *************************************************************************************************


// A request to cancel the timer has been made.
- (void) cancelTimer : (id) sender
{
#if !defined(NDEBUG)
	printf("Cancel timer.\n");
#endif
    
	// reset the timer variable
	mSecondsRemain = 0;
    
    // reset the dock icon
    [mRender restore];

} // end -cancelTimer:


// *************************************************************************************************


// A request to configure application preferences has been made.
- (void) showPrefs : (id) sender
{
#if !defined(NDEBUG)
	printf("Show prefs.\n");
#endif
    
	// display the prefs window
	[mPrefsWindow makeKeyAndOrderFront:self];
    
    // also force activation
	[NSApp activateIgnoringOtherApps:YES];
    
} // end -showPrefs:


// *************************************************************************************************


// A request to show the quick timer has been made.
- (void) showQuickTimer : (id) sender
{
#if !defined(NDEBUG)
	printf("Show quick timer.\n");
#endif
    
	// display the quick timer
	[mQTimerPanel makeKeyAndOrderFront:self];
    
    // also force activation
	[NSApp activateIgnoringOtherApps:YES];
    
} // end -showQuickTimer:


// *************************************************************************************************


// A request to start the quick timer has been made.
- (void) startQuickTimer : (id) sender
{
    NSSound *startSound;	  // start sound
    int hours = -1, mins = -1, secs = -1;   // time values
    
    // set up the quick timer value scanner
    NSScanner *scanner = [NSScanner scannerWithString:[mQTimerValue stringValue]];
    
    // get hours
    if ([scanner scanInt:&hours] != YES)
    {
        // skip over any separators
        while (([scanner scanInt:&hours] != YES) && ([scanner scanLocation] < [[mQTimerValue stringValue] length]))
        {
            [scanner setScanLocation:[scanner scanLocation] + 1];
        }
    }
    
    // get minutes
    if ([scanner scanInt:&mins] != YES)
    {
        // skip over any separators
        while (([scanner scanInt:&mins] != YES) && ([scanner scanLocation] < [[mQTimerValue stringValue] length]))
        {
            [scanner setScanLocation:[scanner scanLocation] + 1];
        }
    }
    
    // get seconds
    if ([scanner scanInt:&secs] != YES)
    {
        // skip over any separators
        while (([scanner scanInt:&secs] != YES) && ([scanner scanLocation] < [[mQTimerValue stringValue] length]))
        {
            [scanner setScanLocation:[scanner scanLocation] + 1];
        }
    }
    
    // translate to seconds
    if (secs != -1)
    {
        // calculate time in seconds
        secs = hours * 3600 + mins * 60 + secs;
    }
    else if (mins != -1)
    {
        // calculate time in seconds
        secs = hours * 60 + mins;
    }
    else
    {
        // just treat the first/only number as seconds
        secs = hours;
    }
    
    mCurrentBevy = genericbevy;
    
    // final check for time limits
    if (secs < CUPPA_BEVY_BREW_TIME_MIN) secs = CUPPA_BEVY_BREW_TIME_MIN;
    if (secs > CUPPA_BEVY_BREW_TIME_MAX) secs = CUPPA_BEVY_BREW_TIME_MAX;
        
	// setup the brewing state
#if !defined(NDEBUG)
	printf("Start quick timer (%d secs)\n", secs);
#endif
    
	mSecondsTotal = secs;
    mSecondsRemain = mSecondsTotal + 1;
    
    mAlarmTime = [[NSDate alloc] initWithTimeIntervalSinceNow:mSecondsRemain];
    
    // we're done with the quick timer panel so close it
    [mQTimerPanel close];
    
	// play the start sound
	startSound = [NSSound soundNamed:@"pour"];
	[startSound play];
    
    // tell the OS we are doing something important... disable App Nap
    if ([[NSProcessInfo processInfo] respondsToSelector:@selector(beginActivityWithOptions:reason:)])
    {
        timerActivity = [[NSProcessInfo processInfo]
                         beginActivityWithOptions:(NSActivityUserInitiated | NSActivityLatencyCritical)
                         reason:@"Cuppa timer"];
    }
    
	// update the onscreen image
	[self updateTick:self];

} // end -startQuickTimer:


// *************************************************************************************************


// Handle toggle of bounce icon flag.
- (void) toggleBounce : (id) sender
{
	#if !defined(NDEBUG)
	printf("Toggle bounce (now %s).\n", !mBounceIcon ? "on" : "off");
	#endif
	
	// flip the flag
	mBounceIcon = !mBounceIcon;
	
	// store to prefs
	[[NSUserDefaults standardUserDefaults] setBool:mBounceIcon forKey:@"bounceIcon"];
	
} // end -toggleBounce:


// *************************************************************************************************


// Handle toggle of make sound flag.
- (void) toggleSound : (id) sender
{
	#if !defined(NDEBUG)
	printf("Toggle sound (now %s).\n", !mMakeSound ? "on" : "off");
	#endif
	
	// flip the flag
	mMakeSound = !mMakeSound;
	
	// store to prefs
	[[NSUserDefaults standardUserDefaults] setBool:mMakeSound forKey:@"makeSound"];
	
} // end -toggleSound:


// *************************************************************************************************


// Handle toggle of show alert flag.
- (void) toggleAlert : (id) sender
{
#if !defined(NDEBUG)
printf("Toggle alert (now %s).\n", !mShowAlert ? "on" : "off");
#endif
	
	// flip the flag
	mShowAlert = !mShowAlert;
	
	// store to prefs
	[[NSUserDefaults standardUserDefaults] setBool:mShowAlert forKey:@"showAlert"];
	
} // end -toggleAlert:


// *************************************************************************************************


// Handle toggle of countdown timer flag.
- (void) toggleTimer : (id) sender
{
#if !defined(NDEBUG)
    printf("Toggle countdown timer (now %s).\n", !mShowTimer ? "on" : "off");
#endif
	
	// flip the flag
	mShowTimer = !mShowTimer;
	
	// store to prefs
	[[NSUserDefaults standardUserDefaults] setBool:mShowTimer forKey:@"showTimer"];
	
} // end -toggleTimer:


// *************************************************************************************************


// Handle toggle of show steep flag.
- (void) toggleSteep : (id) sender
{
#if !defined(NDEBUG)
    printf("Toggle show steep time (now %s).\n", !mShowSteep ? "on" : "off");
#endif
	
	// flip the flag
	mShowSteep = !mShowSteep;
	
	// store to prefs
	[[NSUserDefaults standardUserDefaults] setBool:mShowSteep forKey:@"showSteep"];
	
    // update the menus
    [self setBevys:mBevys];
    
} // end -toggleSteep:


// *************************************************************************************************


// Handle toggle of OS X Notification Center alert flag.
- (void) toggleNotifyOSX : (id) sender
{
    
    // do nothing if OS X Notification Center not available
    if (!mOSXNofifyAvail)
    {
        return;
    }
    
#if !defined(NDEBUG)
    printf("Toggle OS X Notification Center notification (now %s).\n", !mNotifyOSX ? "on" : "off");
#endif
    
    // flip the flag
    mNotifyOSX = !mNotifyOSX;
    
    // store to prefs
    [[NSUserDefaults standardUserDefaults] setBool:mNotifyOSX forKey:@"notifyOSX"];
    
} // end -toggleNotifyOSX


// *************************************************************************************************


// Handle toggle of Growl alert flag.
- (void) toggleNotifyGrowl : (id) sender
{
    
    // do nothing if Growl not present
    if (!mGrowlInstalled)
    {
        return;
    }
    
#if !defined(NDEBUG)
    printf("Toggle Growl notification (now %s).\n", !mNotifyGrowl ? "on" : "off");
#endif
    
    // flip the flag
    mNotifyGrowl = !mNotifyGrowl;
    
    // store to prefs
    [[NSUserDefaults standardUserDefaults] setBool:mNotifyGrowl forKey:@"notifyGrowl"];
    
} // end -toggleNotifyGrowl


// *************************************************************************************************


// Handle click on the add beverage button.
- (void) addBevyButton : (id) sender
{
	Cuppa_Bevy *bevy;	// the new beverage

	#if !defined(NDEBUG)
	printf("Add bevy click.\n");
	#endif

	// if there's not already a newly added "dummy" beverage, add one
	bevy = [[Cuppa_Bevy alloc] init];
	[bevy setName:NSLocalizedString(@"New Beverage", nil)];
	[bevy setBrewTime:120];
	
	[mBevys insertObject:bevy atIndex:0];
	[self setBevys:mBevys];
	[mBevyTable reloadData];

} // end -addBevyButton:


// *************************************************************************************************


// Handle click on the delete beverage button.
- (void) deleteBevyButton : (id) sender
{
	#if !defined(NDEBUG)
	printf("Delete bevy click.\n");
	#endif
	
	// remove the selected beverage from the array, provided there's at least one left
	if ([mBevys count] > 1)
	{
		[mBevys removeObjectAtIndex:[mBevyTable selectedRow]];
		[self setBevys:mBevys];
		[mBevyTable reloadData];
		
		// store to prefs
		[[NSUserDefaults standardUserDefaults] setObject:[Cuppa_Bevy toDictionary:mBevys]
			forKey:@"bevys"];
	}
	else
	{
		// complain if they try to delete the last beverage, this would be ugly
		NSBeep();
	}
	
} // end -deleteBevyButton:


// *************************************************************************************************


// Return the number of known beverages.
- (int) numberOfRowsInTableView : (NSTableView *) aTableView
{
	/*
	#if !defined(NDEBUG)
	printf("-numberOfRowsInTableView: (returning %d)\n", [mBevys count]);
	#endif
	*/
	
	return (int) [mBevys count];

} // end -numberOfRowsInTableView:


// *************************************************************************************************


// Return the object associated with a particular cell in the beverage table.
- (id) tableView : (NSTableView *) aTableView
    objectValueForTableColumn : (NSTableColumn *) aTableColumn
    row : (int) rowIndex
{
    Cuppa_Bevy *bevy;
    int hours;              // hours digit of brew time
	
	/*
	#if !defined(NDEBUG)
	printf("-tableView:objectValueForTableColumn:row:\n");
	#endif
	*/
	
	// parameter checks
    assert(rowIndex >= 0 && rowIndex < [mBevys count]);
	
	// retrieve the bevy associated with this row
    bevy = [mBevys objectAtIndex:rowIndex];
	
	// which column does this apply to?
	if ([[aTableColumn identifier] isEqualToString:@"image"])
	{
		static NSImage *image = NULL;
		if (!image)
		{
			image = [NSImage imageNamed:@"teacup16"];
			[image retain]; // TODO: crude
		}
		return image;
	}
	
	if ([[aTableColumn identifier] isEqualToString:@"name"])
	{
		return [bevy name];
	}
	
	if ([[aTableColumn identifier] isEqualToString:@"time"])
	{
        hours = [bevy brewTime] / 3600;
        if(hours > 0)
        {
            return [NSString stringWithFormat:@"%d:%02d:%02d",
                hours,
                ([bevy brewTime] - (hours * 3600)) / 60,
                ([bevy brewTime] - (hours * 3600)) % 60];
        }
        else
        {
            return [NSString stringWithFormat:@"%d:%02d",
                [bevy brewTime] / 60,
                [bevy brewTime] % 60];
        }
	}
	
	// unknown column?
    return nil;
	
} // end -tableView:objectValueForTableColumn:row:


// *************************************************************************************************


// Modify the object associated with a particular cell in the beverage table.
- (void) tableView : (NSTableView *) aTableView
	setObjectValue : (id) anObject
	forTableColumn : (NSTableColumn *) aTableColumn
	row : (int) rowIndex
{
	Cuppa_Bevy *bevy;
    int hours = -1, mins = -1, secs = -1;   // time values
    	
	#if !defined(NDEBUG)
	printf("-tableView:setObjectValue:forTableColumn:row:\n");
	#endif
	
	// parameter checks
    NSAssert(rowIndex >= 0 && rowIndex < [mBevys count], @"Row index out of range.\n");
	
	// retrieve the bevy associated with this row
    bevy = [mBevys objectAtIndex:rowIndex];
	
	// which column does this apply to?
	if ([[aTableColumn identifier] isEqualToString:@"image"])
	{
		// TODO!
	}
	
	if ([[aTableColumn identifier] isEqualToString:@"name"])
	{
		[bevy setName:anObject];
		[self setBevys:mBevys];
	}
	
	if ([[aTableColumn identifier] isEqualToString:@"time"])
	{
        // set up the time value scanner
        NSScanner *scanner = [NSScanner scannerWithString:anObject];
        
        // get hours
        if ([scanner scanInt:&hours] != YES)
        {
            // skip over any separators
            while (([scanner scanInt:&hours] != YES) && ([scanner scanLocation] < [anObject length]))
            {
                [scanner setScanLocation:[scanner scanLocation] + 1];
            }
        }
        
        // get minutes
        if ([scanner scanInt:&mins] != YES)
        {
            // skip over any separators
            while (([scanner scanInt:&mins] != YES) && ([scanner scanLocation] < [anObject length]))
            {
                [scanner setScanLocation:[scanner scanLocation] + 1];
            }
        }
        
        // get seconds
        if ([scanner scanInt:&secs] != YES)
        {
            // skip over any separators
            while (([scanner scanInt:&secs] != YES) && ([scanner scanLocation] < [anObject length]))
            {
                [scanner setScanLocation:[scanner scanLocation] + 1];
            }
        }
        
        // translate to seconds
        if (secs != -1)
        {
            // calculate time in seconds
            secs = hours * 3600 + mins * 60 + secs;
        }
        else if (mins != -1)
        {
            // calculate time in seconds
            secs = hours * 60 + mins;
        }
        else
        {
            // just treat the first/only number as seconds
            secs = hours;
        }
                
        // final check for time limits
        if (secs < CUPPA_BEVY_BREW_TIME_MIN) secs = CUPPA_BEVY_BREW_TIME_MIN;
        if (secs > CUPPA_BEVY_BREW_TIME_MAX) secs = CUPPA_BEVY_BREW_TIME_MAX;
        
        // apply modified time
        [bevy setBrewTime:secs];
        [self setBevys:mBevys];
	}
	
	// store to prefs
	[[NSUserDefaults standardUserDefaults] setObject:[Cuppa_Bevy toDictionary:mBevys]
		forKey:@"bevys"];
	
} // end -tableView:setObjectValue:forTableColumn:row:


// *************************************************************************************************


// Support for drag and drop within preferences bevy table.
- (BOOL) tableView : (NSTableView *) tableView
	writeRows : (NSArray *) rows
	toPasteboard : (NSPasteboard *) pboard
{
	NSArray *typeArray; // array of types
	int dragRow;		// selected row of table for drag

	#if !defined(NDEBUG)
	printf("Starting drag 'n' drop!\n");
	#endif

	// This webpage was helpful in sorting out DnD for NSTableViews:
	// http://www.mosx.net/dev/NSTableView2.shtml

	// we don't allow multi-row drags
	if ([rows count] == 1)
	{
		// write the beverage to the pasteboard as a Cuppa_Bevy, and a vanilla string
		// there doesn't seem to be a standard on what format custom type strings should take
		typeArray = [NSArray arrayWithObjects:@"RowIndexPboardType", nil];
		[pboard declareTypes:typeArray owner:self];
		dragRow = [[rows objectAtIndex:0] intValue];
		[pboard setData: [NSData dataWithBytes: (void *)&dragRow length:sizeof(int)]
			forType:@"RowIndexPboardType"];
	
		// yep! let them drag it away
		return YES;
	}
	else
	{
		// disallow multi-row drag
		return NO;
	}

} // end -tableView:writeRows:toPasteboard:


// *************************************************************************************************


// Determines if a drop should be accepted. We only accept drops to reorder items.
- (NSDragOperation) tableView : (NSTableView *) tableView
	validateDrop : (id <NSDraggingInfo>) info
	proposedRow : (int) row
	proposedDropOperation : (NSTableViewDropOperation) operation
{
	NSArray *typeArray; // array of types
	int dragRow;		// selected row of table for drag (we don't allow multi-row drags)

	#if !defined(NDEBUG)
	// printf("Accept drag 'n' drop?\n");
	#endif

	// retrieve data from drag and drop pasteboard
	typeArray = [[info draggingPasteboard] types];
	
	// ensure that we are the owner (this limits table drops to row re-arrangements)
	// also double-check drag format and destination drop
	// TODO: self check fails for some reason
	if (/* [info draggingSource] == self && */ [typeArray count] == 1 && row != -1 &&
		[[typeArray objectAtIndex:0] isEqualToString:@"RowIndexPboardType"] == YES &&
		operation == NSTableViewDropAbove)
	{
		// retrieve the dragged row index from the pasteboard data
		dragRow = *((int *) [[[info draggingPasteboard]
			dataForType:@"RowIndexPboardType"] bytes]);

		// check the target row is different from the drag row
		if (row < dragRow || row > (dragRow + 1)) return NSDragOperationMove;
		else return NSDragOperationNone;
	}
	else
	{
		// unacceptable drag
		return NSDragOperationNone;
	}

} // end -tableView:validateDrop:proposedRow:proposedDropOperation:


// *************************************************************************************************


// Handle incoming drag 'n' drops.
- (BOOL) tableView : (NSTableView *) tableView
	acceptDrop : (id <NSDraggingInfo>) info
	row : (int) row 
	dropOperation : (NSTableViewDropOperation) operation
{
	int dragRow;		// selected row of table for drag (we don't allow multi-row drags)
	
	// retrieve row index data from pasteboard
	dragRow = *((int *) [[[info draggingPasteboard] dataForType:@"RowIndexPboardType"] bytes]);

	// debug info
	#if !defined(NDEBUG)
	printf("Received drag 'n' drop: moving rows %d to %d\n", dragRow, row);
	#endif

	// move drag row to row
	if (dragRow != row)
	{
		id temp = [mBevys objectAtIndex:dragRow];
		[temp retain];
		[mBevys removeObjectAtIndex:dragRow];
		[mBevys insertObject:temp atIndex:(dragRow < row ? (row - 1) : row)];
		[temp release];
	}
	
	// update dock menu and preferences table
	[self setBevys:mBevys];
	[mBevyTable reloadData];
    [[NSUserDefaults standardUserDefaults] setObject:[Cuppa_Bevy toDictionary:mBevys]
                                              forKey:@"bevys"];
    
	// drop accepted!
	return YES;
	
} // end -tableView:acceptDrop:row:dropOperation:


// *************************************************************************************************


// Handle incoming column sort requests.
- (void) tableView : (NSTableView *) tableView
        sortDescriptorsDidChange : (NSArray *) oldDescriptors
{
    #if !defined(NDEBUG)
	printf("Sorting!\n");
    #endif
    
    // find out the sort parameters
    NSArray *newDescriptors = [tableView sortDescriptors];
    
    // do the sort
    [mBevys sortUsingDescriptors:newDescriptors];

    // update dock menu and preferences table
	[self setBevys:mBevys];
	[mBevyTable reloadData];
    [[NSUserDefaults standardUserDefaults] setObject:[Cuppa_Bevy toDictionary:mBevys]
                                              forKey:@"bevys"];
}


// *************************************************************************************************


// Update the active beverage list, including a rebuild of the dock menu.
// Param bevys is an ordered array of the beverages to use.
- (void) setBevys : (NSMutableArray *) bevys
{
	int i;						// loop counter
    int hours;                  // hours digit of brew time
	Cuppa_Bevy *bevy;			// current beverage object
	NSMenuItem *item;			// current menu item
	NSInvocation *invocation;	// invocation used to determine item selected
	
	// parameter checks
	assert(bevys);

	// clear out the old menu if it exists
	if (mDockMenu)
	{
		// clear out old menu items first, since we're rebuilding the menu
		// we don't count the separators, prefs and other items
		i = (int) [mDockMenu numberOfItems] - 5;
		while (i-- > 0)
		{
			// we've been using NSInvocations to get around the sender-is-NSApplication bug and
			// we need to go release them here
			[[[mDockMenu itemAtIndex: 0] target] release];
			[mDockMenu removeItemAtIndex: 0];
		}
		
		// just remove the separators, prefs and other items
		[mDockMenu removeItemAtIndex: 0];
		[mDockMenu removeItemAtIndex: 0];
		[mDockMenu removeItemAtIndex: 0];
		[mDockMenu removeItemAtIndex: 0];
		[mDockMenu removeItemAtIndex: 0];
	}
	else
	{
		// this menu is "merged" onto the top of the standard dock menu
		mDockMenu = [[NSMenu alloc] initWithTitle : @"Cuppa"]; // title not used
	}
    
	// create new dock menu
	// this menu is "merged" onto the top of the standard dock menu
    
	// iterate over the beverages in order
	for (i = 0; i < [bevys count]; i++)
	{
		// access the beverage object
		bevy = (Cuppa_Bevy *) [bevys objectAtIndex:i];
		NSAssert(bevy != nil, @"Could not find bevy in array.\n");
		
		// created an invocation used to determine which item has been selected
		// this is required to avoid the OSX bug described in -startBrewing:
        invocation = [NSInvocation invocationWithMethodSignature:[self
			methodSignatureForSelector:@selector(startBrewing:)]];
			
        if (mShowSteep)
        {
            // build a menu item for the beverage -- with steep times
            hours = [bevy brewTime] / 3600;
            if(hours > 0)
            {
                item = [[[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%d:%02d:%02d)",
                    [bevy name],
                    hours,
                    ([bevy brewTime] - (hours * 3600)) / 60,
                    ([bevy brewTime] - (hours * 3600)) % 60]
                                                   action:@selector(invoke) keyEquivalent:@""] autorelease];
                [item setRepresentedObject:bevy];
            }
            else
            {
                item = [[[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%d:%02d)",
                    [bevy name],
                    [bevy brewTime] / 60,
                    [bevy brewTime] % 60]
                                                   action:@selector(invoke) keyEquivalent:@""] autorelease];
                [item setRepresentedObject:bevy];
            }
        }
		else
        {
            // build a menu item for the beverage -- without steep times
            item = [[[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@",
                [bevy name]]
                                               action:@selector(invoke) keyEquivalent:@""] autorelease];
            [item setRepresentedObject:bevy];
        }
		
		// wire up the invocation and the item
        [invocation setSelector:@selector(startBrewing:)];
        [invocation setTarget:self];
        [invocation setArgument:&item atIndex:2];
		[item setTarget:[invocation retain]];
        //[item setImage:[NSImage imageNamed:@"teacup16"]];
		[item setEnabled:YES];
        
		// append the item to the menu
		[mDockMenu insertItem:item atIndex:i];
        
	} // end for
	
    // add a separator
	[mDockMenu insertItem:[NSMenuItem separatorItem] atIndex:i];
    i++;
    
	// add the quick timer item
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Quick Timer...", nil) // TODO: allow localisation
                                      action:@selector(showQuickTimer:) keyEquivalent:@""];
	[item setTarget:self];
	[item setEnabled:YES];
	[mDockMenu insertItem:item atIndex:(i)];
	i++;
	
	// add the cancel timer item
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) // TODO: allow localisation
                                      action:@selector(cancelTimer:) keyEquivalent:@""];
	[item setTarget:self];
	[item setEnabled:YES];
	[mDockMenu insertItem:item atIndex:(i)];
    i++;
	
    // add a separator
	[mDockMenu insertItem:[NSMenuItem separatorItem] atIndex:i];
    i++;
    
	// add the preferences item
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Preferences...", nil) // TODO: allow localisation
                                      action:@selector(showPrefs:) keyEquivalent:@""];
	[item setTarget:self];
	[item setEnabled:YES];
	[mDockMenu insertItem:item atIndex:(i)];
    i++;
    
	// we use static item enabling
	[mDockMenu setAutoenablesItems:NO];
	
    // update the bevy menu
    if(mAppMenu)
    {
    
        // clear out the old menu
        i = (int) [mAppMenu numberOfItems] - 3;
        while (i-- > 0)
        {
            [mAppMenu removeItemAtIndex: 0];
        }
        
        // iterate over the beverages in order
        for (i = 0; i < [bevys count]; i++)
        {
            // access the beverage object
            bevy = (Cuppa_Bevy *) [bevys objectAtIndex:i];
            NSAssert(bevy != nil, @"Could not find bevy in array.\n");
            
            // created an invocation used to determine which item has been selected
            // this is required to avoid the OSX bug described in -startBrewing:
            invocation = [NSInvocation invocationWithMethodSignature:[self
			methodSignatureForSelector:@selector(startBrewing:)]];
            
            if (mShowSteep)
            {
                // build a menu item for the beverage -- with steep times
                hours = [bevy brewTime] / 3600;
                if(hours > 0)
                {
                    item = [[[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%d:%02d:%02d)",
                        [bevy name],
                        hours,
                        ([bevy brewTime] - (hours * 3600)) / 60,
                        ([bevy brewTime] - (hours * 3600)) % 60]
                                                       action:@selector(invoke) keyEquivalent:@""] autorelease];
                    [item setRepresentedObject:bevy];
                }
                else
                {
                    item = [[[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%d:%02d)",
                        [bevy name],
                        [bevy brewTime] / 60,
                        [bevy brewTime] % 60]
                                                       action:@selector(invoke) keyEquivalent:@""] autorelease];
                    [item setRepresentedObject:bevy];
                }
            }
            else
            {
                // build a menu item for the beverage -- without steep times
                item = [[[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@",
                    [bevy name]]
                                                   action:@selector(invoke) keyEquivalent:@""] autorelease];
                [item setRepresentedObject:bevy];
            }
            
            // wire up the invocation and the item
            [invocation setSelector:@selector(startBrewing:)];
            [invocation setTarget:self];
            [invocation setArgument:&item atIndex:2];
            [item setTarget:[invocation retain]];
            //[item setImage:[NSImage imageNamed:@"teacup16"]];
			
			// set the key equivalent for this item
			if (i < 40)
			{
				[item setKeyEquivalent:[NSString stringWithFormat:@"%d", (i % 10)]];
				if (i < 10)
				{
					[item setKeyEquivalentModifierMask:NSCommandKeyMask];
				}
				else if (i < 20)
				{
					[item setKeyEquivalentModifierMask:NSCommandKeyMask+NSAlternateKeyMask];
				}
				else if (i < 30)
				{
					[item setKeyEquivalentModifierMask:NSCommandKeyMask+NSControlKeyMask];
				}
				else
				{
					[item setKeyEquivalentModifierMask:NSCommandKeyMask+NSShiftKeyMask];
				}
			}
			
			// enable the item
            [item setEnabled:YES];
            
            // append the item to the menu
            [mAppMenu insertItem:item atIndex:i];
            
        } // end for
    }
    
} // end -setBevys:


// *************************************************************************************************


// Handle a click on the link to mobile app info
- (IBAction) loadWebsite : (id) sender {
	NSURL *url=[NSURL
                URLWithString:@"https://www.nathanatos.com"];
	[[NSWorkspace sharedWorkspace] openURL:url];
}

// *************************************************************************************************


// Handle an application quit notice.
- (NSApplicationTerminateReply) applicationShouldTerminate : (NSApplication *) theApplication
{
	int hours;
	char countString[16];
	
#if !defined(NDEBUG)
	printf("Application terminating?.\n");
#endif
    
	// Do we have a timer outstanding?
	if (mSecondsRemain <= 0)
    {
        return NSTerminateNow;
    }
	
    // yep we do, check with the user before quitting
	hours = mSecondsRemain / 3600;
	if(hours > 0)
	{
		sprintf(countString, "%01d:%02d:%02d",
				hours,
				(mSecondsRemain - (hours * 3600)) / 60,
				(mSecondsRemain - (hours * 3600)) % 60);
	}
	else
	{
		sprintf(countString, "%01d:%02d",
				mSecondsRemain / 60,
				mSecondsRemain % 60);
	}
	
    if (NSRunCriticalAlertPanel(NSLocalizedString(@"Warning!", nil),
                                NSLocalizedString(@"The Cuppa timer is still active for another %s.\n\nDo you really want to quit?", nil), NSLocalizedString(@"No", nil), NSLocalizedString(@"Yes", nil),
                                nil,
								countString) == NSAlertDefaultReturn)
    {
        return NSTerminateCancel;
    }
    else
    {
        return NSTerminateNow;
    }    
} // end -applicationShouldTerminate:



// *************************************************************************************************


// Handle an application quit.
- (void) applicationWillTerminate : (NSNotification *) aNotification
{
	#if !defined(NDEBUG)
	printf("Application terminating.\n");
	#endif

	// Restore our application's dock tile back to its standard state, otherwise the wind will
	// change and it will be stuck as it is.
    NSAssert(mRender, @"Render object is nil.\n");
    [mRender restore];
    
	// Ensure the user's settings are saved for the next run.
	[[NSUserDefaults standardUserDefaults] synchronize];

} // end -appQuit:


// *************************************************************************************************


// Restore default beverages.
- (void) restoreDefaults : (id) sender
{
	#if !defined(NDEBUG)
	printf("Restoring defaults.\n");
	#endif
	
	// default notification settings
	mBounceIcon = true;
	if ([mBounceSwitch state] != NSOnState) [mBounceSwitch setNextState];
	[[NSUserDefaults standardUserDefaults] setBool:mBounceIcon forKey:@"bounceIcon"];
	
	mMakeSound = true;
	if ([mSoundSwitch state] != NSOnState) [mSoundSwitch setNextState];
	[[NSUserDefaults standardUserDefaults] setBool:mMakeSound forKey:@"makeSound"];
	
	mShowAlert = true;
	if ([mAlertSwitch state] != NSOnState) [mAlertSwitch setNextState];
	[[NSUserDefaults standardUserDefaults] setBool:mShowAlert forKey:@"showAlert"];
	
	mShowTimer = true;
	if ([mTimerSwitch state] != NSOnState) [mTimerSwitch setNextState];
	[[NSUserDefaults standardUserDefaults] setBool:mShowTimer forKey:@"showTimer"];
    
	mShowSteep = true;
	if ([mSteepSwitch state] != NSOnState) [mSteepSwitch setNextState];
	[[NSUserDefaults standardUserDefaults] setBool:mShowSteep forKey:@"showSteep"];
    
	mNotifyOSX = true;
	if ([mOSXNotifySwitch state] != NSOnState) [mOSXNotifySwitch setNextState];
	[[NSUserDefaults standardUserDefaults] setBool:mNotifyOSX forKey:@"notifyOSX"];
    
    mNotifyGrowl = true;
	if ([mGrowlNotifySwitch state] != NSOnState) [mGrowlNotifySwitch setNextState];
	[[NSUserDefaults standardUserDefaults] setBool:mNotifyGrowl forKey:@"notifyGrowl"];
   
	// apply the default beverage set
	[mBevys autorelease];
	mBevys = [Cuppa_Bevy defaultBevys];
	[mBevys retain];
	[self setBevys:mBevys];
	[mBevyTable reloadData];
	[[NSUserDefaults standardUserDefaults] setObject:[Cuppa_Bevy toDictionary:mBevys]
		forKey:@"bevys"];

} // end -restoreDefaults:


// *************************************************************************************************


// Build the application dock menu as required.
- (NSMenu *) applicationDockMenu : (NSApplication *) sender
{
	// return our custom dock menu
	return mDockMenu;
    
} // end -applicationDockMenu:


// *************************************************************************************************


// Get the registration dictionary for Growl
- (NSDictionary *) registrationDictionaryForGrowl
{
    NSArray *notifications = [NSArray arrayWithObjects:BREWING_STARTED, BREWING_COMPLETE, nil];
    NSDictionary *dict = [[NSMutableDictionary alloc] init];
    
    [dict setValue:notifications forKey:GROWL_NOTIFICATIONS_ALL];
    [dict setValue:notifications forKey:GROWL_NOTIFICATIONS_DEFAULT];
    
    return dict;
    
} // end -registrationDictionaryForGrowl


// *************************************************************************************************


// Send notification to OS X Notification Center
- (void) notifyOSX
{
    NSLog(@"notifying Notification Center, current bevy: %@", [mCurrentBevy name]);
    
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = NSLocalizedString(@"Brewing complete...", nil);
    notification.informativeText = [NSString stringWithFormat:NSLocalizedString(@"%@ is now ready!", nil), [mCurrentBevy name]];
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    
} // end -notifyOSX


// *************************************************************************************************


// Send notification to Growl
- (void) notifyGrowl
{
    NSLog(@"notifying Growl, current bevy: %@", [mCurrentBevy name]);
    
    [GrowlApplicationBridge notifyWithTitle:NSLocalizedString(@"Brewing complete...", nil)
                                description:[NSString stringWithFormat:NSLocalizedString(@"%@ is now ready!", nil), [mCurrentBevy name]]
                           notificationName:BREWING_COMPLETE
                                   iconData:[[NSImage imageNamed:@"tea_done"] TIFFRepresentation]
                                   priority:0.0
                                   isSticky:NO
                               clickContext:nil];
    
} // end -notifyGrowl


// *************************************************************************************************


// Define application name for Growl
- (NSString *) applicationNameForGrowl
{
    return @"Cuppa";
    
} // end -applicationNameForGrowl


// *************************************************************************************************
    
// Handle Growl network entitlement check.
- (BOOL) hasNetworkClientEntitlement;
{
        return YES;
        
} // end -hasNetworkClientEntitlement
    
    
// *************************************************************************************************

- (BOOL)application:(NSApplication *)sender 
 delegateHandlesKey:(NSString *)key
{
    if ([key isEqual:@"brewtime"]) {
        return YES;
    } else {
        return NO;
    }
}


// *************************************************************************************************

- (int) brewTime
{
	return 0;
}

- (void) setBrewTime : (int) brewvalue
{
    NSSound *startSound;	  // start sound
    
    mCurrentBevy = genericbevy;
    
    // final check for time limits
    if (brewvalue < CUPPA_BEVY_BREW_TIME_MIN) brewvalue = CUPPA_BEVY_BREW_TIME_MIN;
    if (brewvalue > CUPPA_BEVY_BREW_TIME_MAX) brewvalue = CUPPA_BEVY_BREW_TIME_MAX;
        
	// setup the brewing state
#if !defined(NDEBUG)
	printf("[AppleScript] Start quick timer (%d secs)\n", brewvalue);
#endif
    
	mSecondsTotal = brewvalue;
    mSecondsRemain = mSecondsTotal + 1;
    
	// play the start sound
	startSound = [NSSound soundNamed:@"pour"];
	[startSound play];
    
	// update the onscreen image
	[self updateTick:self];
}

@end // @implementation Cuppa_Control

// end Cuppa_Control.m
