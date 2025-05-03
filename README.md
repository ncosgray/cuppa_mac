## ☕ Cuppa

Cuppa is a small application to time your cup of tea as it steeps. Tired of leaving your tea too long, to become bitter and cold, or drinking it too soon and not appreciating its full potential? Then this utility is for you!

[![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/ncosgray/cuppa?label=latest%20version&sort=semver)](https://github.com/ncosgray/cuppa/releases)
[![GitHub issues](https://img.shields.io/github/issues/ncosgray/cuppa?color=red)](https://github.com/ncosgray/cuppa/issues)
[![Weblate project translated](https://img.shields.io/weblate/progress/cuppa?color=green&server=https%3A%2F%2Fhosted.weblate.org)](https://hosted.weblate.org/engage/cuppa/)
[![GitHub license](https://img.shields.io/github/license/ncosgray/cuppa?color=lightgrey)](https://github.com/ncosgray/cuppa/blob/master/LICENSE.txt)

### Tea Timer App for macOS

Cuppa is an application that lives in your Dock: just right-click or control-click on Cuppa's icon and select the beverage you are brewing (the beverage list and times can be edited, and even expanded to time things other than tea!). When you choose a beverage, Cuppa will begin timing the brew for you, with a countdown timer that's optionally displayed as a badge on the dock icon. When the tea is done Cuppa will attempt to get your attention by various configurable means.

<img src="https://www.nathanatos.com/software/images/Cuppa-notification-small.png" width="500" />

Screenshots: [Dock menu](https://www.nathanatos.com/software/images/Cuppa-dock-menu.png), [Cuppa preferences](https://www.nathanatos.com/software/images/Cuppa-preferences.png), [Dock icon timer badge](https://www.nathanatos.com/software/images/Cuppa-timer.png)

### Install

| macOS DMG | Mac App Store |
| :--: | :--: |
| <a href="https://github.com/ncosgray/cuppa/releases/latest"><img src="https://www.nathanatos.com/software/images/file-zip-icon.png" alt="Download macOS DMG" width="80" height="80"/></a> | <a href="https://itunes.apple.com/us/app/cuppa-tea-timer/id1297865739"><img src="https://www.nathanatos.com/software/images/mac-app-store-badge.png" alt="Download on the App Store" width="206" height="50"/></a> |

### Features

- All functionality is available from the Dock menu.
- Dock icon can display a small countdown timer as the beverage steeps.
- Customize the beverage list and steeping times.
- Quick Timer feature turns Cuppa into a versatile freeform timer.
- Customize the brew complete notification (supports macOS Notification Center).
- Also great for timing French press coffee or anything else you can think of!
- Full Cocoa source code available.
- Runs on macOS 10.13+.
- Universal 2 binary compatible with Intel and Apple Silicon.
- Localized to English, Czech, Danish, Dutch, French, German, Irish, Italian, Russian, Spanish, and Ukrainian.

### Join the Team

- Pull requests for new features or bugfixes are welcome.
  - Target "cuppa" builds non-App Store distribution version with Sparkle updater and DMG
  - Target "cuppa-appstore" builds App Store distribution version
  - Localizations are exported to the XCLocalization folder
  - Prerequisites: Xcode 10+ for building, and [create-dmg](https://github.com/create-dmg/create-dmg) for packaging

- Use [Weblate](https://hosted.weblate.org/engage/cuppa/) to contribute a translation for your language.

<a href="https://hosted.weblate.org/engage/cuppa/" target="_blank" rel="noopener"><img src="https://hosted.weblate.org/widgets/cuppa/-/open-graph.png" alt="Translation status" width="400"></a>

<details>
  <summary>Translation status</summary>

#### macOS app:

[![macOS app](https://hosted.weblate.org/widgets/cuppa/-/cuppa-macos-app/multi-auto.svg)](https://hosted.weblate.org/projects/cuppa/cuppa-macos-app/)

#### macOS app help:

[![macOS app help](https://hosted.weblate.org/widgets/cuppa/-/cuppa-macos-app-help/multi-auto.svg)](https://hosted.weblate.org/projects/cuppa/cuppa-macos-app-help/)

</details>

### Support the Project

Buy us a cup of tea to support active development of Cuppa.

<a href="https://paypal.me/ncosgray"><img src="https://www.nathanatos.com/software/images/paypal-badge.png" alt="Donate with PayPal" width="185" height="50"/></a><br/>
<a href="https://venmo.com/nathancosgray"><img src="https://www.nathanatos.com/software/images/venmo-badge.png" alt="Donate with Venmo" width="185" height="50"/></a><br/>
<img src="https://www.nathanatos.com/software/images/ethereum-logo.png" alt="Ethereum Logo" width="15" height="25"/> <a href="ethereum:0xc5be97ea75ad15854ed09529139e672fae2f63c0">Ethereum: 0xc5be97ea75ad15854ed09529139e672fae2f63c0</a><br/>

### History

- [Full changelog](https://github.com/ncosgray/Cuppa/blob/master/source/main.m)
- [Cuppa 1.8.7](https://www.nathanatos.com/software/downloads/Cuppa-1.8.7.zip) supported OS 10.9+
- [Cuppa 1.8.2](https://www.nathanatos.com/software/downloads/Cuppa-1.8.2.zip) supported OS 10.7+
- [Cuppa 1.7.9](https://www.nathanatos.com/software/downloads/Cuppa-1.7.9.zip) supported OS 10.4+
- [Cuppa 1.7](https://www.nathanatos.com/software/downloads/Cuppa-1.7.zip) was the last version to support PowerPC
- [Cuppa 1.8.2](https://www.nathanatos.com/software/downloads/Cuppa-1.8.2.zip) was the last version to support Growl notifications

### About

Cuppa Mobile is a free, open-source mobile app licensed under the terms of the BSD license.

Author: [Nathan Cosgray](https://www.nathanatos.com)

Cuppa for macOS includes contributions from Mathias Meyer and Eric McMurry. Original German translation by Benedikt Hopmann. Original Czech translation by Tomáš Klos. Original Italian translation by Giuseppe Morelli. Original French translation by Christian Parent.

This application was inspired by The Tea Cooker for Linux and is based on work done by Wunderbear Software.
