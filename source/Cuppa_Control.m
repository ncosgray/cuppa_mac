/*
 **************************************************************************************************
 Package:  Cuppa
 Class:    Cuppa_Control
           - Controls for the Cuppa user interface, such as changing preferences and setting timers.
 ----------------------------------------------------------------------------------------------------
 Copyright (c) 2005-2026 Nathan Cosgray. All rights reserved.
 
 This source code is licensed under the BSD-style license found in LICENSE.txt.
 **************************************************************************************************
 */

// Cuppa Includes

#import "Cuppa_Bevy.h"
#import "Cuppa_Control.h"
#if !APPSTORE_BUILD
#import "Sparkle/SPUStandardUpdaterController.h"
#endif

// Code!

@implementation Cuppa_Control
;

// *************************************************************************************************

// Initialise Cuppa_Control object.
- (id)init
{
    
    NSMutableDictionary *appDefaults; // dictionary of these application defaults
    NSUserDefaults *defaults; // user defaults object used to store preferences
    
    // chain up to superclass
    self = [super init];
    
    // set app delegate
    if (@available(macOS 10.14, *)) {
        [[UNUserNotificationCenter currentNotificationCenter] setDelegate:self];
    }
    
    // create the render object to do our dirty work
    mRender = [[Cuppa_Render alloc] init];
    
    // additional bevy table setup
    [mBevyTable setVerticalMotionCanBeginDrag:true];
    
    // determine if OS X Notification Center is available on system
    mOSXNotifyAvail = (NSClassFromString(@"NSUserNotificationCenter") != nil);
    
    // set application defaults to guarantee our searches will succeed
    defaults = [NSUserDefaults standardUserDefaults];
    appDefaults = [NSMutableDictionary dictionary];
    mBevys = [Cuppa_Bevy defaultBevys];
    [appDefaults setObject:@"YES" forKey:@"bounceIcon"];
    [appDefaults setObject:@"YES" forKey:@"makeSound"];
    [appDefaults setObject:@"YES" forKey:@"showAlert"];
    [appDefaults setObject:@"YES" forKey:@"showTimer"];
    [appDefaults setObject:@"NO" forKey:@"showSteep"];
    [appDefaults setObject:@"NO" forKey:@"autoStart"];
    [appDefaults setObject:@"YES" forKey:@"notifyOSX"];
    [appDefaults setObject:[Cuppa_Bevy toDictionary:mBevys] forKey:@"bevys"];
    [defaults registerDefaults:appDefaults];
    
    // migrate settings from old bundle identifier, if needed
    if (![defaults boolForKey:@"migratedPrefs"])
    {
        // check for defaults from old com.wunderbear.Cuppa application identifier
        // IMPORTANT: This will not work after Cuppa is sandboxed!
        NSUserDefaults *oldDefaults = [NSUserDefaults new];
        NSDictionary *oldDefaultsDict = [oldDefaults persistentDomainForName:@"com.wunderbear.Cuppa"];
        if (oldDefaultsDict)
        {
            // load the old defaults and set flag to skip subsequent imports
            [defaults setPersistentDomain:oldDefaultsDict forName:[[NSBundle mainBundle] bundleIdentifier]];
            [defaults setBool:YES forKey:@"migratedPrefs"];
            [defaults synchronize];
            
#if !defined(NDEBUG)
            printf("Imported defaults from com.wunderbear.Cuppa\n");
#endif
        }
    }
    
    // apply current settings
    mBounceIcon = [defaults boolForKey:@"bounceIcon"];
    mMakeSound = [defaults boolForKey:@"makeSound"];
    mSpeakAlert = [defaults boolForKey:@"speakAlert"];
    mShowAlert = [defaults boolForKey:@"showAlert"];
    mShowTimer = [defaults boolForKey:@"showTimer"];
    mShowSteep = [defaults boolForKey:@"showSteep"];
    mAutoStart = [defaults boolForKey:@"autoStart"];
    mNotifyOSX = [defaults boolForKey:@"notifyOSX"];
    
    mBevys = [Cuppa_Bevy fromDictionary:[defaults objectForKey:@"bevys"]];
    [mBevys retain];
    mDockMenu = nil;
    [self setBevys:mBevys];
    
    // define a generic beverage for the quick timer
    genericbevy = [[Cuppa_Bevy alloc] init];
    [genericbevy setName:@"Cuppa"];
    [genericbevy setBrewTime:120];
    
    // we are not testing by default
    mTestNotify = false;
    
    // no active timer on startup
    mBrewTimer = nil;
    mSecondsRemain = 0;
    mAlarmTime = nil;
    
    // initialize speech synthesizer
    _speechSynth = [[NSSpeechSynthesizer alloc] initWithVoice:nil];
    
    // return the initialised object!
    return self;
    
} // end -init

// *************************************************************************************************

// Handle setup once we've been fully woken.
- (void)awakeFromNib
{
    NSMenu *mMainMenu; // main menu object
    NSMenuItem *item; // current menu item
    
    // On older macOS versions, keep App Nap permanently disabled as a
    // workaround for bugs where long-running timers could be interrupted
    if (@available(macOS 13.0, *)) {
        // App Nap managed dynamically in startBrewTimer/stopBrewTimer
    } else {
        if (!self.timerActivity &&
            [[NSProcessInfo processInfo] respondsToSelector:@selector(beginActivityWithOptions:reason:)])
        {
            self.timerActivity = [[[NSProcessInfo processInfo]
                                  beginActivityWithOptions:NSActivityUserInitiatedAllowingIdleSystemSleep
                                  reason:@"Cuppa timer"] retain];
        }
    }
    
    // request notification permissions
    if (@available(macOS 10.14, *)) {
        mOSXNotifyAvail = true;
        [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:
         (UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error)
        {
          if (!granted || error)
          {
              // cannot use Notification Center
              mOSXNotifyAvail = false;
              
              // hide options that require Notification Center
              [mOSXNotifySwitch setEnabled:NO];
              [mTimerSwitch setEnabled:NO];
          }
        }];
    }

    mMainMenu = [NSApp mainMenu];
    
#if !APPSTORE_BUILD
    // add Check for Updates menu item if not already present
    NSMenu *mCuppaMenu = [[mMainMenu itemAtIndex:0] submenu];
    if ([mCuppaMenu indexOfItemWithTitle:NSLocalizedString(@"Check for Updates...", nil)] == -1)
    {
        item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Check for Updates...", nil)
                                          action:@selector(checkForUpdates:)
                                   keyEquivalent:@""];
        [item setTarget:self.updaterController];
        [item setEnabled:YES];
        [mCuppaMenu insertItem:item atIndex:1];
    }
#endif
    
    // ensure delegate and data source are set
    [mBevyTable setDelegate:self];
    [mBevyTable setDataSource:self];
    
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
    
    if ([mSpeakSwitch state] != (mSpeakAlert ? NSOnState : NSOffState))
    {
        [mSpeakSwitch setNextState];
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
    
    if ([mAutoStartSwitch state] != (mAutoStart ? NSOnState : NSOffState))
    {
        [mAutoStartSwitch setNextState];
    }
    
    if (!mOSXNotifyAvail)
    {
        [mOSXNotifySwitch setEnabled:NO];
        [mOSXNotifySwitch setState:NSOffState];
        
        [mAdditionalSettings setHidden:YES];
    }
    else
    {
        if ([mOSXNotifySwitch state] != (mNotifyOSX ? NSOnState : NSOffState))
        {
            [mOSXNotifySwitch setNextState];
        }
    }
    
    // reset quick timer value
    [mQTimerValue setStringValue:@"2:00"];
    
    // add the Beverages menu to the main menu if not already present
    if (!mAppMenu || [mMainMenu indexOfItemWithSubmenu:mAppMenu] == -1)
    {
        item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Beverages", nil) action:nil keyEquivalent:@""];
        [mMainMenu insertItem:item atIndex:1];
        mAppMenu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Beverages", nil)];
        [mMainMenu setSubmenu:mAppMenu forItem:item];
        
        // add a separator
        [mAppMenu insertItem:[NSMenuItem separatorItem] atIndex:0];
        
        // add the quick timer item
        item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Quick Timer...", nil)
                                          action:@selector(showQuickTimer:)
                                   keyEquivalent:@"t"];
        [item setTarget:self];
        [item setEnabled:YES];
        [item setImage:[Cuppa_Shape imageForShape:CUPPA_SHAPE_DEFAULT]];
        [mAppMenu insertItem:item atIndex:1];
        
        // add the cancel timer item
        item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil)
                                          action:@selector(cancelTimer:)
                                   keyEquivalent:@"."];
        [item setTarget:self];
        [item setEnabled:YES];
        [item setImage:[NSImage imageNamed:NSImageNameStopProgressTemplate]];
        [mAppMenu insertItem:item atIndex:2];
    }
    
    // make sure to update the dock menu and the Beverages application menu
    [self setBevys:mBevys];
    
    // auto-start the first timer in the Beverage List, if that option is enabled
    if (mAutoStart && [mBevys count] > 0)
    {
        Cuppa_Bevy *bevy; // matching beverage object
        
        // which beverage is the chosen (first) one?
        bevy = mBevys[0];
        
#if !defined(NDEBUG)
        printf("Auto-start brewing %s (%d secs)\n", [[bevy name] cString], [bevy brewTime]);
#endif
        
        // start!
        [self setTimer:bevy];
    }
    
} // end -awakeFromNib

// *************************************************************************************************

// Handle a tick from the brew timer.
- (void)updateTick:(id)sender
{
    
    // update the brew state
    if (mAlarmTime != nil || mSecondsRemain > 0)
    {
        // calculate time remaining til brewing complete
        if (mAlarmTime != nil)
        {
            mSecondsRemain = floor([mAlarmTime timeIntervalSinceNow]);
        }
        else
        {
            mSecondsRemain = 0;
        }
        
        // still timing?
        if (mSecondsRemain > 0)
        {
            // update brew time remaining for countdown timer
            if (mShowTimer)
            {
                [mRender setBrewRemain:mSecondsRemain];
            }
            else
            {
                // hide countdown timer if show timer option got disabled
                [mRender setBrewRemain:0];
            }
            
            // update brew state
            [mRender setBrewState:((float)(mSecondsTotal - mSecondsRemain) / (float)mSecondsTotal)];
            [mRender render];
            
            // emit a beep for the final 5 seconds
            if (mMakeSound && mSecondsRemain <= 5 && mSecondsRemain >= 1)
            {
                NSSound *beepSound = [NSSound soundNamed:@"beep"];
                [beepSound play];
            }
        }
    
        // or is the beverage ready?
        else
        {
#if !defined(NDEBUG)
            printf("Brew complete!\n");
#endif
            
            // reset the timer variables
            mSecondsRemain = 0;
            mAlarmTime = nil;
            
            // stop the repeating tick timer
            [self stopBrewTimer];
        
            // no brew time remaining for countdown timer
            [mRender setBrewRemain:0];
            
            // ensure the final image is displayed
            [mRender setBrewState:0.0f];
            [mRender render];

            // alert message text contains beverage name
            NSString *alertInfoText = [NSString stringWithFormat:NSLocalizedString(@"%@ is now ready!",
                                                                                   nil),
                                       [mCurrentBevy name]];
        
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
        
            // speak it
            if (mSpeakAlert)
            {
                [self.speechSynth startSpeakingString:alertInfoText];
            }
        
            // send a message to OS X Notification Center
            if (mNotifyOSX)
            {
                [self notifyOSX];
            }
        
            // show a little alert window
            if (mShowAlert)
            {
                // force activation
                [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
        
                // It's more complicated if we want to allow keyboard shortcuts
                NSAlert *brewAlert = [[[NSAlert alloc] init] autorelease];
                [brewAlert setMessageText:NSLocalizedString(@"Brewing complete...", nil)];
                [brewAlert setInformativeText:alertInfoText];
                NSButton *okButton = [brewAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
                [okButton setKeyEquivalent:@"\r"];
                NSButton *quitButton = [brewAlert addButtonWithTitle:NSLocalizedString(@"Quit Cuppa", nil)];
                [quitButton setKeyEquivalent:@"q"];
                [quitButton setKeyEquivalentModifierMask:NSEventModifierFlagCommand];
                if ([brewAlert runModal] == NSAlertSecondButtonReturn)
                {
                    // User wants to quit, how sad!
                    [[NSApplication sharedApplication] terminate:self];
                }
            }

            // as a courtesy, reopen Preferences if user was testing
            if (mTestNotify)
            {
                mTestNotify = false;
        
                [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
                [self showPrefs:nil];
            }
            
        } // end if
        
    } // end if
} // end -updateTick:

// *************************************************************************************************

// A particular beverage has been selected for brewing.
- (void)startBrewing:(id)sender
{
    Cuppa_Bevy *bevy; // matching beverage object
    
    // which beverage have they choosen?
    bevy = (Cuppa_Bevy *)[sender representedObject];
    if (!bevy)
    {
        // Bother, we didn't find it! This shouldn't happen.
        NSAssert(bevy != nil, @"Could not find matching bevy in array!\n");
        mSecondsRemain = 0;
        mAlarmTime = nil;
    }
    
#if !defined(NDEBUG)
    printf("Start brewing %s (%d secs)\n", [[bevy name] cString], [bevy brewTime]);
#endif
    
    // Make sure Cuppa is not hidden while a timer is starting up.
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    
    // start!
    [self setTimer:bevy];
    
} // end -startBrewing:

// *************************************************************************************************

// A request to cancel the timer has been made.
- (IBAction)cancelTimer:(id)sender
{
#if !defined(NDEBUG)
    printf("Cancel timer.\n");
#endif
    
    // reset the timer variables
    mSecondsRemain = 0;
    mAlarmTime = nil;
    
    // stop the repeating tick timer
    [self stopBrewTimer];
    
    // reset the dock icon
    [mRender restore];
    
} // end -cancelTimer:

// *************************************************************************************************

// A request to configure application preferences has been made.
- (IBAction)showPrefs:(id)sender
{
#if !defined(NDEBUG)
    printf("Show prefs.\n");
#endif
    
    // scroll beverage table to the top
    if ([mBevyTable numberOfRows] > 0)
    {
        [mBevyTable scrollRowToVisible:0];
    }
    
    // display the prefs window
    [mPrefsWindow makeKeyAndOrderFront:self];
    
    // also force activation
    [NSApp activateIgnoringOtherApps:YES];
    
} // end -showPrefs:

// *************************************************************************************************

// A request to show the quick timer has been made.
- (IBAction)showQuickTimer:(id)sender
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
- (IBAction)startQuickTimer:(id)sender
{
    int hours = -1, mins = -1, secs = -1; // time values
    
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
    
    // final check for time limits
    if (secs < CUPPA_BEVY_BREW_TIME_MIN)
        secs = CUPPA_BEVY_BREW_TIME_MIN;
    if (secs > CUPPA_BEVY_BREW_TIME_MAX)
        secs = CUPPA_BEVY_BREW_TIME_MAX;
    
    // set quick timer duration
    [genericbevy setBrewTime:secs];
    
#if !defined(NDEBUG)
    printf("Start quick timer (%d secs)\n", secs);
#endif
    
    // we're done with the quick timer panel so close it
    [mQTimerPanel close];
    
    // Make sure Cuppa is not hidden while a timer is starting up.
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    
    // start!
    [self setTimer:genericbevy];
    
} // end -startQuickTimer:

// *************************************************************************************************

// A request to do a notification test has been made.
- (IBAction)testNotify:(id)sender
{
    // test timer duration is always 10 seconds
    int secs = 10;
    [genericbevy setBrewTime:secs];
    
#if !defined(NDEBUG)
    printf("Start notification test (%d secs)\n", secs);
#endif
    
    // make sure everyone knows we're testing (so we can reopen Preferences window later)
    mTestNotify = true;
    
    // some notifications aren't displayed if we're in the foreground, so let's deactivate
    [[NSApplication sharedApplication] hide: self];
    [[NSApplication sharedApplication] miniaturizeAll: self];
    
    // start!
    [self setTimer:genericbevy];
    
} // end -testNotify:

// *************************************************************************************************

// Start the repeating brew timer (fires every second).
- (void)startBrewTimer
{
    // Invalidate any existing timer first
    [mBrewTimer invalidate];
    mBrewTimer = nil;
    
    // Disable App Nap while brewing (macOS 13+ only; older versions keep it always disabled)
    if (@available(macOS 13.0, *)) {
        if (!self.timerActivity &&
            [[NSProcessInfo processInfo] respondsToSelector:@selector(beginActivityWithOptions:reason:)])
        {
            self.timerActivity = [[[NSProcessInfo processInfo]
                                  beginActivityWithOptions:NSActivityUserInitiatedAllowingIdleSystemSleep
                                  reason:@"Cuppa timer"] retain];
        }
    }
    
    mBrewTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                  target:self
                                                selector:@selector(updateTick:)
                                                userInfo:nil
                                                 repeats:YES];
}

// *************************************************************************************************

// Stop the repeating brew timer.
- (void)stopBrewTimer
{
    [mBrewTimer invalidate];
    mBrewTimer = nil;
    
    // Re-enable App Nap when not brewing (macOS 13+ only; older versions keep it always disabled)
    if (@available(macOS 13.0, *)) {
        if (self.timerActivity)
        {
            [[NSProcessInfo processInfo] endActivity:self.timerActivity];
            [self.timerActivity release];
            self.timerActivity = nil;
        }
    }
}

// *************************************************************************************************

// Set up and start a timer.
- (void)setTimer:(Cuppa_Bevy *)bevy
{
    // Do we have a timer outstanding?
    if (mSecondsRemain > 0)
    {
        // Check with the user before starting a new timer
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:NSLocalizedString(@"Warning!", nil)];
        [alert setInformativeText:NSLocalizedString(@"There is an active timer. Cancel and start a new timer?", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"No", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Yes", nil)];
        [alert setAlertStyle:NSAlertStyleCritical];
        NSInteger returnCode = [alert runModal];
        if (returnCode == NSAlertFirstButtonReturn) {
            return;
        }
    }

    NSSound *startSound; // start sound
    
    // setup the brewing state
    mCurrentBevy = bevy;
    mSecondsTotal = [bevy brewTime];
    mSecondsRemain = mSecondsTotal + 1;
    mAlarmTime = [[NSDate alloc] initWithTimeIntervalSinceNow:mSecondsRemain];
    
    // start the repeating tick timer
    [self startBrewTimer];
    
    // play the start sound
    if (mMakeSound)
    {
        startSound = [NSSound soundNamed:@"pour"];
        [startSound play];
    }
    
    // update the onscreen image
    [self updateTick:self];
    
} // end -setTimer:

// *************************************************************************************************

// Handle toggle of bounce icon flag.
- (IBAction)toggleBounce:(id)sender
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
- (IBAction)toggleSound:(id)sender
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

// Handle toggle of speak alert flag.
- (IBAction)toggleSpeak:(id)sender
{
#if !defined(NDEBUG)
    printf("Toggle speak (now %s).\n", !mSpeakAlert ? "on" : "off");
#endif
    
    // flip the flag
    mSpeakAlert = !mSpeakAlert;
    
    // store to prefs
    [[NSUserDefaults standardUserDefaults] setBool:mSpeakAlert forKey:@"speakAlert"];
    
} // end -toggleSpeak:

// *************************************************************************************************

// Handle toggle of show alert flag.
- (IBAction)toggleAlert:(id)sender
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
- (IBAction)toggleTimer:(id)sender
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
- (IBAction)toggleSteep:(id)sender
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

// Handle toggle of auto-start timer flag.
- (IBAction)toggleAutoStart:(id)sender
{
#if !defined(NDEBUG)
    printf("Toggle auto-start timer (now %s).\n", !mAutoStart ? "on" : "off");
#endif
    
    // flip the flag
    mAutoStart = !mAutoStart;
    
    // store to prefs
    [[NSUserDefaults standardUserDefaults] setBool:mAutoStart forKey:@"autoStart"];
    
} // end -toggleSteep:

// *************************************************************************************************

// Handle toggle of OS X Notification Center alert flag.
- (IBAction)toggleNotifyOSX:(id)sender
{
    
    // do nothing if OS X Notification Center not available
    if (!mOSXNotifyAvail)
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

// Handle click on the add beverage button.
- (IBAction)addBevyButton:(id)sender
{
    Cuppa_Bevy *bevy; // the new beverage
    
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
    
    // store to prefs
    [[NSUserDefaults standardUserDefaults] setObject:[Cuppa_Bevy toDictionary:mBevys]
                                              forKey:@"bevys"];
    
} // end -addBevyButton:

// *************************************************************************************************

// Handle click on the delete beverage button.
- (IBAction)deleteBevyButton:(id)sender
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
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    
    return (int)[mBevys count];
    
} // end -numberOfRowsInTableView:

// *************************************************************************************************

// Return the view for a cell in the beverage table (view-based).
- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row
{
    Cuppa_Bevy *bevy = [mBevys objectAtIndex:row];
    
    if ([[tableColumn identifier] isEqualToString:@"image"])
    {
        NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"image" owner:self];
        
        // Find the popup button in this cell view
        NSPopUpButton *popup = nil;
        for (NSView *subview in [cellView subviews])
        {
            if ([subview isKindOfClass:[NSPopUpButton class]])
            {
                popup = (NSPopUpButton *)subview;
                break;
            }
        }
        
        if (popup)
        {
            // Populate if empty
            if ([popup numberOfItems] == 0)
            {
                for (int shape = 0; shape < CUPPA_SHAPE_MAX; shape++)
                {
                    [popup addItemWithTitle:@""];
                    NSMenuItem *item = [popup lastItem];
                    [item setImage:[Cuppa_Shape imageForShape:shape]];
                    [item setTag:shape];
                }
            }
            [popup selectItemWithTag:[bevy cupShape]];
        }
        
        return cellView;
    }
    
    if ([[tableColumn identifier] isEqualToString:@"name"])
    {
        NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"name" owner:self];
        [[cellView textField] setStringValue:[bevy name]];
        [[cellView textField] setEditable:YES];
        [[cellView textField] setDelegate:self];
        return cellView;
    }
    
    if ([[tableColumn identifier] isEqualToString:@"time"])
    {
        NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"time" owner:self];
        
        // Find the NSDatePicker in the cell view
        NSDatePicker *picker = nil;
        for (NSView *subview in [cellView subviews])
        {
            if ([subview isKindOfClass:[NSDatePicker class]])
            {
                picker = (NSDatePicker *)subview;
                break;
            }
        }
        
        if (picker)
        {
            // Configure picker for duration display (24-hour, no AM/PM, UTC timezone)
            NSLocale *posixLocale = [NSLocale localeWithLocaleIdentifier:@"en_GB"];
            NSTimeZone *utc = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
            NSCalendar *utcCal = [[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian] autorelease];
            [utcCal setTimeZone:utc];
            [utcCal setLocale:posixLocale];
            [picker setLocale:posixLocale];
            [picker setTimeZone:utc];
            [picker setCalendar:utcCal];
            [[picker cell] setLocale:posixLocale];
            [[picker cell] setTimeZone:utc];
            [[picker cell] setCalendar:utcCal];
            [picker setDatePickerStyle:NSDatePickerStyleTextFieldAndStepper];
            
            // Convert brew time (seconds) to an NSDate using a fixed reference date
            // Reference date is 2001-01-01 00:00:00 UTC; with UTC timezone on picker,
            // adding brewTime seconds gives us h:m:s directly
            int brewTime = [bevy brewTime];
            NSDate *midnight = [NSDate dateWithTimeIntervalSinceReferenceDate:0];
            [picker setDateValue:[midnight dateByAddingTimeInterval:brewTime]];
        }
        
        return cellView;
    }
    
    return nil;
    
} // end -tableView:viewForTableColumn:row:

// *************************************************************************************************

// Handle change of brew time via date picker in beverage table.
- (IBAction)brewTimePicked:(id)sender
{
    NSDatePicker *picker = (NSDatePicker *)sender;
    
    // Determine which row this picker belongs to
    NSInteger row = [mBevyTable rowForView:picker];
    if (row < 0 || row >= (NSInteger)[mBevys count])
        return;
    
    // Extract brew time as seconds since midnight reference date
    NSDate *midnight = [NSDate dateWithTimeIntervalSinceReferenceDate:0];
    int secs = (int)[[picker dateValue] timeIntervalSinceDate:midnight];
    
    // Clamp to valid range
    if (secs < CUPPA_BEVY_BREW_TIME_MIN)
        secs = CUPPA_BEVY_BREW_TIME_MIN;
    if (secs > CUPPA_BEVY_BREW_TIME_MAX)
        secs = CUPPA_BEVY_BREW_TIME_MAX;
    
    // Apply to the beverage
    Cuppa_Bevy *bevy = [mBevys objectAtIndex:row];
    [bevy setBrewTime:secs];
    [self setBevys:mBevys];
    
    // Store to prefs
    [[NSUserDefaults standardUserDefaults] setObject:[Cuppa_Bevy toDictionary:mBevys]
                                              forKey:@"bevys"];
    
} // end -brewTimePicked:

// *************************************************************************************************

// Handle change of cup shape via popup in beverage table.
- (IBAction)cupShapePicked:(id)sender
{
    NSPopUpButton *popup = (NSPopUpButton *)sender;
    
    // Determine which row this popup belongs to
    NSInteger row = [mBevyTable rowForView:popup];
    if (row < 0 || row >= (NSInteger)[mBevys count])
        return;
    
    int shapeTag = (int)[[popup selectedItem] tag];
    Cuppa_Bevy *bevy = [mBevys objectAtIndex:row];
    [bevy setCupShape:shapeTag];
    [self setBevys:mBevys];
    
    // Store to prefs
    [[NSUserDefaults standardUserDefaults] setObject:[Cuppa_Bevy toDictionary:mBevys]
                                              forKey:@"bevys"];
    
} // end -cupShapePicked:

// *************************************************************************************************

// Handle name editing via text field in beverage table.
- (void)controlTextDidEndEditing:(NSNotification *)notification
{
    NSTextField *textField = [notification object];
    NSInteger row = [mBevyTable rowForView:textField];
    if (row < 0 || row >= (NSInteger)[mBevys count])
        return;
    
    // Determine which column this text field belongs to
    NSInteger col = [mBevyTable columnForView:textField];
    if (col < 0)
        return;
    
    NSTableColumn *tableColumn = [[mBevyTable tableColumns] objectAtIndex:col];
    
    if ([[tableColumn identifier] isEqualToString:@"name"])
    {
        Cuppa_Bevy *bevy = [mBevys objectAtIndex:row];
        [bevy setName:[textField stringValue]];
        [self setBevys:mBevys];
        
        // Store to prefs
        [[NSUserDefaults standardUserDefaults] setObject:[Cuppa_Bevy toDictionary:mBevys]
                                                  forKey:@"bevys"];
    }
    
} // end -controlTextDidEndEditing:

// *************************************************************************************************

// Support for drag and drop within preferences bevy table.
- (BOOL)tableView:(NSTableView *)tableView
        writeRows:(NSArray *)rows
     toPasteboard:(NSPasteboard *)pboard
{
    NSArray *typeArray; // array of types
    int dragRow; // selected row of table for drag
    
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
        [pboard setData:[NSData dataWithBytes:(void *)&dragRow length:sizeof(int)]
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
- (NSDragOperation)tableView:(NSTableView *)tableView
                validateDrop:(id<NSDraggingInfo>)info
                 proposedRow:(int)row
       proposedDropOperation:(NSTableViewDropOperation)operation
{
    int dragRow; // selected row of table for drag (we don't allow multi-row drags)
    
#if !defined(NDEBUG)
    printf("Accept drag 'n' drop?\n");
#endif
    
    // ensure that we are the owner (this limits table drops to row re-arrangements)
    // also double-check drag format and destination drop
    if ([info draggingSource] == tableView && operation == NSTableViewDropAbove)
    {
        // retrieve the dragged row index from the pasteboard data
        dragRow = *((int *)[[[info draggingPasteboard]
                             dataForType:@"RowIndexPboardType"] bytes]);
        
        // check the target row is different from the drag row
        if (row < dragRow || row > (dragRow + 1))
            return NSDragOperationMove;
        else
            return NSDragOperationNone;
    }
    else
    {
        // unacceptable drag
        return NSDragOperationNone;
    }
    
} // end -tableView:validateDrop:proposedRow:proposedDropOperation:

// *************************************************************************************************

// Handle incoming drag 'n' drops.
- (BOOL)tableView:(NSTableView *)tableView
       acceptDrop:(id<NSDraggingInfo>)info
              row:(int)row
    dropOperation:(NSTableViewDropOperation)operation
{
    int dragRow; // selected row of table for drag (we don't allow multi-row drags)
    
    // retrieve row index data from pasteboard
    dragRow = *((int *)[[[info draggingPasteboard] dataForType:@"RowIndexPboardType"] bytes]);
    
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
- (void)tableView:(NSTableView *)tableView
sortDescriptorsDidChange:(NSArray *)oldDescriptors
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
- (void)setBevys:(NSMutableArray *)bevys
{
    int i; // loop counter
    int hours; // hours digit of brew time
    Cuppa_Bevy *bevy; // current beverage object
    NSMenuItem *item; // current menu item
    NSInvocation *invocation; // invocation used to determine item selected
    
    // parameter checks
    assert(bevys);
    
    // clear out the old menu if it exists
    if (mDockMenu)
    {
        // clear out old menu items first, since we're rebuilding the menu
        [mDockMenu removeAllItems];
    }
    else
    {
        // this menu is "merged" onto the top of the standard dock menu
        mDockMenu = [[NSMenu alloc] initWithTitle:@"Cuppa"]; // title not used
    }
    
    // create new dock menu
    // this menu is "merged" onto the top of the standard dock menu
    
    // iterate over the beverages in order
    for (i = 0; i < [bevys count]; i++)
    {
        // access the beverage object
        bevy = (Cuppa_Bevy *)[bevys objectAtIndex:i];
        NSAssert(bevy != nil, @"Could not find bevy in array.\n");
        
        // created an invocation used to determine which item has been selected
        // this is required to avoid the OSX bug described in -startBrewing:
        invocation = [NSInvocation invocationWithMethodSignature:[self
                                                                  methodSignatureForSelector:@selector(startBrewing:)]];
        
        // get the image for this beverage
        NSImage *bevyImage = [Cuppa_Shape imageForShape:[bevy cupShape]];
        
        if (mShowSteep)
        {
            // build a menu item for the beverage -- with steep times
            hours = [bevy brewTime] / 3600;
            if (hours > 0)
            {
                item = [[[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%d:%02d:%02d)",
                                                           [bevy name],
                                                           hours,
                                                           ([bevy brewTime] - (hours * 3600)) / 60,
                                                           ([bevy brewTime] - (hours * 3600)) % 60]
                                                   action:@selector(invoke)
                                            keyEquivalent:@""] autorelease];
                [item setRepresentedObject:bevy];
            }
            else
            {
                item = [[[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%d:%02d)",
                                                           [bevy name],
                                                           [bevy brewTime] / 60,
                                                           [bevy brewTime] % 60]
                                                   action:@selector(invoke)
                                            keyEquivalent:@""] autorelease];
                [item setRepresentedObject:bevy];
            }
        }
        else
        {
            // build a menu item for the beverage -- without steep times
            item = [[[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@",
                                                       [bevy name]]
                                               action:@selector(invoke)
                                        keyEquivalent:@""] autorelease];
            [item setRepresentedObject:bevy];
        }
        
        // wire up the invocation and the item
        [invocation setSelector:@selector(startBrewing:)];
        [invocation setTarget:self];
        [invocation setArgument:&item atIndex:2];
        [item setTarget:[invocation retain]];
        [item setEnabled:YES];
        [item setImage:bevyImage];
        
        // append the item to the menu
        [mDockMenu insertItem:item atIndex:i];
        
    } // end for
    
    // add a separator
    [mDockMenu insertItem:[NSMenuItem separatorItem] atIndex:i];
    i++;
    
    // add the quick timer item
    item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Quick Timer...", nil)
                                       action:@selector(showQuickTimer:)
                                keyEquivalent:@""] autorelease];
    [item setTarget:self];
    [item setEnabled:YES];
    [mDockMenu insertItem:item atIndex:(i)];
    i++;
    
    // add the cancel timer item
    item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil)
                                       action:@selector(cancelTimer:)
                                keyEquivalent:@""] autorelease];
    [item setTarget:self];
    [item setEnabled:YES];
    [mDockMenu insertItem:item atIndex:(i)];
    i++;
    
    // add a separator
    [mDockMenu insertItem:[NSMenuItem separatorItem] atIndex:i];
    i++;
    
    // add the preferences/settings item
    NSString *prefsTitle;
    if (@available(macOS 13.0, *))
    {
        prefsTitle = NSLocalizedString(@"Settings...", nil);
    }
    else
    {
        prefsTitle = NSLocalizedString(@"Preferences...", nil);
    }
    item = [[[NSMenuItem alloc] initWithTitle:prefsTitle
                                       action:@selector(showPrefs:)
                                keyEquivalent:@""] autorelease];
    [item setTarget:self];
    [item setEnabled:YES];
    [mDockMenu insertItem:item atIndex:(i)];
    i++;
    
    // we use static item enabling
    [mDockMenu setAutoenablesItems:NO];
    
    // update the bevy menu
    if (mAppMenu)
    {
        
        // clear out the old menu
        i = (int)[mAppMenu numberOfItems] - 3;
        while (i-- > 0)
        {
            [mAppMenu removeItemAtIndex:0];
        }
        
        // iterate over the beverages in order
        for (i = 0; i < [bevys count]; i++)
        {
            // access the beverage object
            bevy = (Cuppa_Bevy *)[bevys objectAtIndex:i];
            NSAssert(bevy != nil, @"Could not find bevy in array.\n");
            
            // created an invocation used to determine which item has been selected
            // this is required to avoid the OSX bug described in -startBrewing:
            invocation = [NSInvocation invocationWithMethodSignature:[self
                                                                      methodSignatureForSelector:@selector(startBrewing:)]];
            
            // get the image for this beverage
            NSImage *bevyImage = [Cuppa_Shape imageForShape:[bevy cupShape]];
            
            if (mShowSteep)
            {
                // build a menu item for the beverage -- with steep times
                hours = [bevy brewTime] / 3600;
                if (hours > 0)
                {
                    item = [[[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%d:%02d:%02d)",
                                                               [bevy name],
                                                               hours,
                                                               ([bevy brewTime] - (hours * 3600)) / 60,
                                                               ([bevy brewTime] - (hours * 3600)) % 60]
                                                       action:@selector(invoke)
                                                keyEquivalent:@""] autorelease];
                    [item setImage:bevyImage];
                    [item setRepresentedObject:bevy];
                }
                else
                {
                    item = [[[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%d:%02d)",
                                                               [bevy name],
                                                               [bevy brewTime] / 60,
                                                               [bevy brewTime] % 60]
                                                       action:@selector(invoke)
                                                keyEquivalent:@""] autorelease];
                    [item setImage:bevyImage];
                    [item setRepresentedObject:bevy];
                }
            }
            else
            {
                // build a menu item for the beverage -- without steep times
                item = [[[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@",
                                                           [bevy name]]
                                                   action:@selector(invoke)
                                            keyEquivalent:@""] autorelease];
                [item setImage:bevyImage];
                [item setRepresentedObject:bevy];
            }
            
            // wire up the invocation and the item
            [invocation setSelector:@selector(startBrewing:)];
            [invocation setTarget:self];
            [invocation setArgument:&item atIndex:2];
            [item setTarget:[invocation retain]];
            
            // set the key equivalent for this item
            if (i < 40)
            {
                [item setKeyEquivalent:[NSString stringWithFormat:@"%d", (i % 10)]];
                if (i < 10)
                {
                    [item setKeyEquivalentModifierMask:NSEventModifierFlagCommand];
                }
                else if (i < 20)
                {
                    [item setKeyEquivalentModifierMask:NSEventModifierFlagCommand + NSEventModifierFlagOption];
                }
                else if (i < 30)
                {
                    [item setKeyEquivalentModifierMask:NSEventModifierFlagCommand + NSEventModifierFlagControl];
                }
                else
                {
                    [item setKeyEquivalentModifierMask:NSEventModifierFlagCommand + NSEventModifierFlagShift];
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
- (IBAction)loadWebsite:(id)sender
{
    NSURL *url = [NSURL
                  URLWithString:@"https://www.nathanatos.com"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

#if !APPSTORE_BUILD
// Handle a click on the Check for Updates menu item
- (IBAction)checkForUpdates:(id)sender;
{
    [self.updaterController checkForUpdates:sender];
}
#endif

// *************************************************************************************************

// Handle an application quit notice.
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)theApplication
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
    if (hours > 0)
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
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:NSLocalizedString(@"Warning!", nil)];
    [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"The Cuppa timer is still active for another %s.\n\nDo you really want to quit?", nil), countString]];
    [alert addButtonWithTitle:NSLocalizedString(@"No", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Yes", nil)];
    [alert setAlertStyle:NSAlertStyleCritical];
    NSInteger returnCode = [alert runModal];
    if (returnCode == NSAlertFirstButtonReturn)
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
- (void)applicationWillTerminate:(NSNotification *)aNotification
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
- (void)restoreDefaults:(id)sender
{
#if !defined(NDEBUG)
    printf("Restoring defaults.\n");
#endif
    
    // default notification settings
    mBounceIcon = true;
    if ([mBounceSwitch state] != NSOnState)
        [mBounceSwitch setNextState];
    [[NSUserDefaults standardUserDefaults] setBool:mBounceIcon forKey:@"bounceIcon"];
    
    mMakeSound = true;
    if ([mSoundSwitch state] != NSOnState)
        [mSoundSwitch setNextState];
    [[NSUserDefaults standardUserDefaults] setBool:mMakeSound forKey:@"makeSound"];
    
    mSpeakAlert = false;
    if ([mSpeakSwitch state] != NSOnState)
        [mSpeakSwitch setNextState];
    [[NSUserDefaults standardUserDefaults] setBool:mSpeakAlert forKey:@"speakAlert"];
    
    mShowAlert = true;
    if ([mAlertSwitch state] != NSOnState)
        [mAlertSwitch setNextState];
    [[NSUserDefaults standardUserDefaults] setBool:mShowAlert forKey:@"showAlert"];
    
    mShowTimer = true;
    if ([mTimerSwitch state] != NSOnState)
        [mTimerSwitch setNextState];
    [[NSUserDefaults standardUserDefaults] setBool:mShowTimer forKey:@"showTimer"];
    
    mShowSteep = true;
    if ([mSteepSwitch state] != NSOnState)
        [mSteepSwitch setNextState];
    [[NSUserDefaults standardUserDefaults] setBool:mShowSteep forKey:@"showSteep"];
    
    mAutoStart = false;
    if ([mAutoStartSwitch state] != NSOnState)
        [mAutoStartSwitch setNextState];
    [[NSUserDefaults standardUserDefaults] setBool:mAutoStart forKey:@"autoStart"];
    
    mNotifyOSX = true;
    if ([mOSXNotifySwitch state] != NSOnState)
        [mOSXNotifySwitch setNextState];
    [[NSUserDefaults standardUserDefaults] setBool:mNotifyOSX forKey:@"notifyOSX"];
    
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
- (NSMenu *)applicationDockMenu:(NSApplication *)sender
{
    // return our custom dock menu
    return mDockMenu;
    
} // end -applicationDockMenu:

// *************************************************************************************************

// Send notification to OS X Notification Center
- (void)notifyOSX
{
#if !defined(NDEBUG)
    printf("notifying Notification Center, current bevy: %@\n", [mCurrentBevy name]);
#endif
    
    if (@available(macOS 10.14, *)) {
        // create a unique request identifier
        NSString *uuidString = [[NSUUID UUID] UUIDString];
        
        // use new Notification Center API, if available
        UNMutableNotificationContent *notification = [[UNMutableNotificationContent alloc] init];
        notification.title = NSLocalizedString(@"Brewing complete...", nil);
        notification.body = [NSString stringWithFormat:NSLocalizedString(@"%@ is now ready!", nil), [mCurrentBevy name]];
        // NB: playing a sound is handled in updateTick for consistency
        // notification.sound = [UNNotificationSound soundNamed:@"spoon.aiff"];
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:uuidString content:notification trigger:nil];
        [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {}];
    }
    else
    {
        // fall back to previous API
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = NSLocalizedString(@"Brewing complete...", nil);
        notification.informativeText = [NSString stringWithFormat:NSLocalizedString(@"%@ is now ready!", nil), [mCurrentBevy name]];
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }
    
} // end -notifyOSX

// App delegate to allow notification in foreground
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler API_AVAILABLE(macos(10.14)) API_AVAILABLE(macos(10.14)) API_AVAILABLE(macos(10.14)){
    if (@available(macOS 10.14, *)) {
        UNNotificationPresentationOptions presentationOptions =
        UNNotificationPresentationOptionSound
        | UNNotificationPresentationOptionAlert
        | UNNotificationPresentationOptionBadge;
        
        completionHandler(presentationOptions);
    }
} // end -userNotificationCenter

// *************************************************************************************************

- (BOOL)application:(NSApplication *)sender
 delegateHandlesKey:(NSString *)key
{
    if ([key isEqual:@"brewtime"])
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

// *************************************************************************************************

// Override method so Cuppa's Notification Center alerts are always displayed, even if in foreground
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
#if !APPSTORE_BUILD
    self.updaterController = [[SPUStandardUpdaterController alloc] initWithStartingUpdater:YES
                                                                           updaterDelegate:nil
                                                                        userDriverDelegate:nil];
#endif
}
- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
     shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

// *************************************************************************************************

@end // @implementation Cuppa_Control

// end Cuppa_Control.m
