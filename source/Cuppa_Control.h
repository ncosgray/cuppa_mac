/*
 **************************************************************************************************
 Package:  Cuppa
 Class:    Cuppa_Control
           - Controls for the Cuppa user interface, such as changing preferences and setting timers.
 ----------------------------------------------------------------------------------------------------
 Copyright (c) 2005-2025 Nathan Cosgray. All rights reserved.
 
 This source code is licensed under the BSD-style license found in LICENSE.txt.
 **************************************************************************************************
 */

#ifndef _CUPPA_CONTROL_H
#define _CUPPA_CONTROL_H

#if !defined(__OBJC__)
#error "Objective-C only source file."
#endif

// Toggle debug messages
#define NDEBUG

// OSX Includes

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

// Cuppa Includes

#import "Cuppa_Bevy.h"
#import "Cuppa_Render.h"
#if !APPSTORE_BUILD
#import "Sparkle/SPUStandardUpdaterController.h"
#endif

// defines

#define BREWING_COMPLETE @"Brewing complete"
#define BREWING_STARTED @"Brewing started"

// Class Interface

@interface Cuppa_Control : NSObject <NSUserNotificationCenterDelegate, UNUserNotificationCenterDelegate>
{
    // IB connected objects
    IBOutlet NSWindow *mPrefsWindow; // application preferences window
    IBOutlet NSWindow *mQTimerPanel; // quick timer panel
    IBOutlet NSButton *mStartButton; // start quick timer button
    IBOutlet NSTextField *mQTimerValue; // quick timer value field
    IBOutlet NSButton *mBounceSwitch; // switch on bounce control
    IBOutlet NSButton *mSoundSwitch; // switch on sound control
    IBOutlet NSButton *mSpeakSwitch; // switch on speak control
    IBOutlet NSButton *mAlertSwitch; // switch on alert control
    IBOutlet NSButton *mTimerSwitch; // switch on timer control
    IBOutlet NSButton *mSteepSwitch; // switch on steep control
    IBOutlet NSButton *mAutoStartSwitch; // switch on auto-start timer control
    IBOutlet NSButton *mOSXNotifySwitch; // switch for Notification Center control
    IBOutlet NSButton *mTestNotifyButton; // test notifications button
    IBOutlet NSTextField *mAdditionalSettings; // System Preferences label
    IBOutlet NSButton *mDeleteBevyButton; // delete beverage button
    IBOutlet NSButton *mAddBevyButton; // edit beverage button
    IBOutlet NSTableView *mBevyTable; // table of beverages
    
    // general data
    NSMutableArray *mBevys; // array of beverages
    NSMenu *mDockMenu; // popup dock tile menu
    NSMenu *mAppMenu; // application menu
    NSTimer *mBrewTimer; // used to time the brew process
    int mSecondsRemain; // seconds remaining until the brew is complete
    int mSecondsTotal; // total seconds to brew
    NSDate *mAlarmTime; // absolute time for next alarm
    Cuppa_Render *mRender; // render state and operations
    int mBounceIcon; // flag: bounce dock icon when brew complete?
    int mMakeSound; // flag: make sound when brew complete?
    int mSpeakAlert; // flag: speak alert when brew complete?
    int mShowAlert; // flag: show alert when brew complete?
    int mShowTimer; // flag: show countown timer during brew?
    int mShowSteep; // flag: show steep times in menus?
    int mAutoStart; // flag: enable auto-start timer?
    int mNotifyOSX; // flag: notify Notification Center?
    bool mTestNotify; // flag: indicates we are doing a test notification
    bool mOSXNotifyAvail; // flag: shows if OS X Notification Center is available
    Cuppa_Bevy *mCurrentBevy; // the currently brewing beverage
    Cuppa_Bevy *genericbevy; // quick timer beverage
    
}

// timer activity
@property (strong) id timerActivity;

// speech synthesizer
@property (strong) NSSpeechSynthesizer *speechSynth;

#if !APPSTORE_BUILD
// Sparkle updater
@property (strong, nonatomic) SPUStandardUpdaterController *updaterController;
#endif

// ------ Manipulators ------

// Handle setup once we've been fully woken.
- (void)awakeFromNib;

// Handle a tick from the brew timer.
- (void)updateTick:(id)sender;

// A particular beverage has been selected for brewing.
- (void)startBrewing:(id)sender;

// A request to configure application preferences has been made.
- (IBAction)showPrefs:(id)sender;

// A request to show the quick timer has been made.
- (IBAction)showQuickTimer:(id)sender;

// A request to cancel the timer has been made.
- (IBAction)cancelTimer:(id)sender;

// A request to start the quick timer has been made.
- (IBAction)startQuickTimer:(id)sender;

// A request to do a notification test has been made.
- (IBAction)testNotify:(id)sender;

// Set up and start a timer.
- (void)setTimer:(Cuppa_Bevy *)bevy;

// Handle toggle of bounce icon flag.
- (IBAction)toggleBounce:(id)sender;

// Handle toggle of make sound flag.
- (IBAction)toggleSound:(id)sender;

// Handle toggle of speak alert flag.
- (IBAction)toggleSpeak:(id)sender;

// Handle toggle of show alert flag.
- (IBAction)toggleAlert:(id)sender;

// Handle toggle of countdown timer flag.
- (IBAction)toggleTimer:(id)sender;

// Handle toggle of show steep flag.
- (IBAction)toggleSteep:(id)sender;

// Handle toggle of auto-start timer flag.
- (IBAction)toggleAutoStart:(id)sender;

// Handle toggle of Notification Center notification.
- (IBAction)toggleNotifyOSX:(id)sender;

// Handle click on the add beverage button.
- (IBAction)addBevyButton:(id)sender;

// Handle click on the delete beverage button.
- (IBAction)deleteBevyButton:(id)sender;

// Return the number of known beverages.
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;

// Return the object associated with a particular cell in the beverage table.
- (id)tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(int)rowIndex;

// Modify the object associated with a particular cell in the beverage table.
- (void)tableView:(NSTableView *)aTableView
   setObjectValue:(id)anObject
   forTableColumn:(NSTableColumn *)aTableColumn
              row:(int)rowIndex;

// Support for drag and drop within preferences bevy table.
- (BOOL)tableView:(NSTableView *)tableView
        writeRows:(NSArray *)rows
     toPasteboard:(NSPasteboard *)pboard;

// Handle incoming drag 'n' drops. We only accepts drops to reorder items.
- (BOOL)tableView:(NSTableView *)tableView
       acceptDrop:(id<NSDraggingInfo>)info
              row:(int)row
    dropOperation:(NSTableViewDropOperation)operation;

// Determines if a drop should be accepted. We only accept drops to reorder items.
- (NSDragOperation)tableView:(NSTableView *)tableView
                validateDrop:(id<NSDraggingInfo>)info
                 proposedRow:(int)row
       proposedDropOperation:(NSTableViewDropOperation)operation;

// Handle incoming column sort requests.
- (void)tableView:(NSTableView *)tableView
sortDescriptorsDidChange:(NSArray *)oldDescriptors;

// Update the active beverage list, including a rebuild of the dock menu.
// Param bevys is an ordered array of the beverages to use.
- (void)setBevys:(NSMutableArray *)bevys;

// Handle a click on the link to iTunes App Store
- (IBAction)loadWebsite:(id)sender;

#if !APPSTORE_BUILD
// Handle a click on the Check for Updates menu item
- (IBAction)checkForUpdates:(id)sender;
#endif

// Handle an application quit.
- (void)applicationWillTerminate:(NSNotification *)aNotification;

// Restore default settings/beverages.
- (void)restoreDefaults:(id)sender;

// Build the application dock menu as required.
- (NSMenu *)applicationDockMenu:(NSApplication *)sender;

// Send notification to OS X Notification Center
- (void)notifyOSX;

@end // @interface Cuppa_Control

// *************************************************************************************************

#endif // _CUPPA_CONTROL_H

// end Cuppa_Control.h
