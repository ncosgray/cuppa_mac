/*
 **************************************************************************************************
 Package:  Cuppa
 Class:    main
 ----------------------------------------------------------------------------------------------------
 Copyright (c) 2005-2021 Nathan Cosgray. All rights reserved.
 
 This source code is licensed under the BSD-style license found in LICENSE.txt.
 **************************************************************************************************
 */

//  Originally created by Timothy Wayper on 2002/01/27.
//
//  Modifications by Nathan Cosgray on 2005/08/21 (v. 1.2.0):
//  * built with Xcode 2.1 on Tiger
//  * new features:
//    - display an alert window when brewing is complete
//  * UI improvements:
//    - sized beverages list so that it doesn't scroll unnecessarily
//    - set defaultfirstresponder to Close button
//    - dock icon now bounces until user activates the app
//    - Preferences window now forces activation
//
//  Modifications by Nathan Cosgray on 2005/09/07 (v. 1.3.0):
//  * updated copyright notices, InfoPlist.strings and HTML help file
//  * new features:
//    - countdown timer for dock icon
//
//  Modifications by Mathias Meyer on 2005/09/17 (v. 1.4.0):
//  * new features:
//    - Growl support
//  * bugfixes:
//    - dock icon render reset bug
//
//  Modifications by Nathan Cosgray on 2005/09/24 (v. 1.4.0):
//  * created better-quality dock icons
//  * bugfixes:
//    - fixed another dock icon rendering bug
//
//  Modifications by Nathan Cosgray on 2005/09/25 (v. 1.4.2):
//  * bugfixes:
//    - changes now saved to prefs after drag 'n' drop operation
//  * UI improvements:
//    - order beverage list via column sort
//    - Growl and alert notification texts now consistent
//
//  Modifications by Nathan Cosgray on 2005/11/18 (v. 1.4.4):
//  * new features:
//    - added "Quick Timer" and "Cancel Timer" options
//    - added 5-second warning countdown sound
//
//  Modifications by Nathan Cosgray on 2006/01/31 (v. 1.5):
//  * Universal Binary built with Xcode 2.2.1
//  * upgraded Growl framework to 0.7.4
//  * UI improvements:
//    - improved documentation
//    - beverage list added to main application menu
//
//  Modifications by Nathan Cosgray on 2006/04/20 (v. 1.5.2):
//  * new features:
//    - Cuppa can now handle times up to 9h:59m:59s
//  * UI improvements:
//    - preference setting to include steep times in menus
//  * bugfixes:
//    - improved parsing for time input fields
//    - time input fields accept values with no leading zero
//
//  Modifications by Nathan Cosgray on 2007/09/15 (v. 1.5.4):
//  * upgraded Growl framework to 1.1.1
//
//  Modifications by Nathan Cosgray on 2007/11/04 (v. 1.5.6):
//  * built with Xcode 3.0
//  * improved Cuppa icon
//  * UI improvements:
//    - new beverages now added to beginning of list
//
//  Modifications by Nathan Cosgray on 2008/04/26 (v. 1.5.6):
//  * upgraded Growl framework to 1.1.2
//  * UI improvements:
//    - set tab stops for keyboard navigation
//    - set key equivalents for menu items
//
//  Modifications by Eric McMurry on 2008/11/25 (v. 1.6):
//  * new features:
//    - warn before quitting when timer active
//    - use absolute time for countdown timer
//
//  Modifications by Nathan Cosgray on 2009/09/07 (v. 1.6):
//  * built with Xcode 3.2
//  * upgraded Growl framework to 1.1.6
//  * new features:
//    - Cuppa now uses Sparkle to check for program updates
//  * bugfixes:
//    - fixed dock icon rendering for Snow Leopard
//
//  Modifications by Nathan Cosgray on 2009/09/16 (v. 1.6.2):
//  * upgraded Growl framework to 1.2b3
//  * bugfixes:
//    - corrected a memory leak in dock icon rendering
//    - now completely silent when "Play Sound" disabled
//  * UI improvements:
//    - reorganized Preferences window
//    - added option to disable automatic program updates
//
//  Modifications by Nathan Cosgray on 2009/10/22 (v. 1.6.4):
//  * upgraded Growl framework to 1.2
//  * UI improvements:
//    - simplified quit warning message when timer active
//
//  Modifications by Nathan Cosgray on 2010/04/18 (v. 1.6.6):
//  * upgraded Growl framework to 1.2.1
//  * include a link to iCuppa in the App Store
//  * help screen updated
//  * UI improvements:
//    - added Quit button to brewing complete dialog box
//
//  Modifications by Benedikt Hopmann on 2010/11/10 (v. 1.6.8):
//  * added German localization
//
//  Modifications by Nathan Cosgray on 2012/02/08 (v. 1.7):
//  * upgraded Growl framework to 1.2.3
//    - fixes for compatibility with new versions of Growl 1.3+
//  * corrections to German localization
//
//  Modifications by Nathan Cosgray on 2013/10/27 (v. 1.7.2):
//  ! NOTE: this release removes support for PowerPC
//  * built with Xcode 5
//  * new features:
//    - full OS X 10.9 Mavericks compatibility
//    - added support for OS X Notification Center
//    - added Czech localization
//
//  Modifications by Nathan Cosgray on 2013/11/02 (v. 1.7.4):
//  * corrections to Czech localization
//
//  Modifications by Nathan Cosgray on 2013/11/03 (v. 1.7.6):
//  * bugfixes:
//    - timer broken on some previous versions of OS X
//
//  Modifications by Nathan Cosgray on 2013/11/15 (v. 1.7.8):
//  * added Italian and French localization
//
//  Modifications by Nathan Cosgray on 2016/02/20 (v. 1.7.9):
//  * use secure URLs for Cuppa updates
//  * built with Xcode 7
//  * minor cleanup of unused code
//  * consistent localization file encoding (UTF-8)
//
//  Modifications by Nathan Cosgray on 2017/10/01 (v. 1.8):
//  ! NOTE: this release requires OS 10.7 (Lion) or newer
//  * Cuppa is now code-signed with my Apple Developer ID
//  * high-res icons for Retina displays
//  * now using native dock badge for countdown timer
//    - sadly, this means the dock icon no longer animates
//  * updated links to Cuppa mobile apps
//  * changed bundle identifier
//    - your preferences will be copied from the old bundle ID
//  * built with Xcode 9
//  * upgraded Growl framework to 2.0
//  * upgraded Sparkle framework to 1.18.1
//
//  Modifications by Nathan Cosgray on 2018/09/25 (v. 1.8.1):
//  * UI improvements:
//    - support macOS Mojave Dark Aqua mode
//    - reorder beverage list in Preferences with drag 'n' drop
//    - prefer system font in help pages and menu
//  * added more default teas (e.g. green)
//  * built with Xcode 10
//  * upgraded Sparkle framework to 1.20.0
//
//  Modifications by Nathan Cosgray on 2019/03/31 (v. 1.8.2):
//  * bugfix:
//    - improve timer reliability on High Sierra and later
//  * Retina graphics for help pages and DMG
//  * cleaned up and centered app icon
//  * upgraded Sparkle framework to 1.21.3
//
//  Modifications by Nathan Cosgray on 2020/02/20 (v. 1.8.3):
//  ! NOTE: this release requires OS 10.9 (Mavericks) or newer
//  * new feature:
//    - option to auto-start a timer at launch
//  * bugfixes:
//    - improve icon badge reliability on Catalina and later
//    - quick timer now respects Play Sound preference
//  * added Test Notification button
//  * removed support for Growl
//  * upgraded Sparkle framework to 1.22
//
//  Modifications by Nathan Cosgray on 2020/11/14 (v. 1.8.4):
//  * new feature:
//    - option to speak alerts using speech synthesizer
//  * Big Sur-style app icon
//  * Universal 2 binary compatible with Intel and Apple Silicon
//  * upgraded Sparkle framework to 1.24.0
//
//  Modifications by Nathan Cosgray on 2021/09/21 (v. 1.8.5):
//  * bugfix:
//    - improve timer reliability on Big Sur

#import <Cocoa/Cocoa.h>

int main(int argc, const char *argv[])
{
    return NSApplicationMain(argc, argv);
}
