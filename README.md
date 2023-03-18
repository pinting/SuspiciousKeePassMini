KeePassMini (formerly IOSKeePass)
===========

12.03.2023
We had to change the app name because we violated the
Apple App Store Policy 5.2.5 - Legal - Intellectual Property.
Your app metadata contains content that resembles designs or terms used for Apple products and services, which may cause confusion among users. Specifically, your metadata includes:

- Terms for iOS in the app name in an inappropriate manner.
- Terms for iOS in the app name displayed on the device. 

for this reason we call IOSKeePass after KeePassMini.


Free KeePass ist a fork of MinKeePassMini, i do it, because i find that this Software is great stuff for password storing
and sensible data to a local file, and only in the cloud with a strong enrcyption, also i mean, it was free and it should be keep for free in future.
I have create a new repo on Github, because the original Github project was setting to read only, and i can´t support the original Software development.

*New Stuff
- Change Master Password
- Add Context Menus
- OneDrive Sync support (Feb. 2022)
- Extract icons from Website to use as Customicons (Jan 2022)
- iCloud Sync Support (Jan. 2022)
- Webdav Protocol Support with a Sync on demand (Dez. 2021)
- IOS Autofill Credential Provider Support (June 2021)
- Support for KDBx Version 4 (Mar. 2021)
- IOS Darkmode Support (Aug. 2020)
- One Time password support secure secret key storing (Released in 1.80)
  The Time-based One-time Password algorithm (TOTP) is an extension of the HMAC-based One-time Password algorithm (HOTP) that generates a one-time password (OTP) by instead taking         
  uniqueness from the current time. It has been adopted as Internet Engineering Task Force (IETF)[1] standard RFC 6238,
  [1] is the cornerstone of Initiative for Open Authentication (OAUTH), and is used in a number of two-factor authentication (2FA) systems. 
- open key db file from ios local storage
- support open db by FaceID using LAPolicyDeviceOwnerAuthenticationWithBiometrics

*Older Stuff from Original
MinKeePassMini provides secure password storage on your phone that's compatible with KeePass.

- View, Edit, and Create KeePass 1.x and 2.x files
- Search for entries from the top of tables like in Mail
- Key File Support
- Import/Export files to Dropbox using the Dropbox iPhone app
- Copy password entries to the clipboard for easy entry
- Open websites in Safari while MinKeePassMini runs in the background
- Prevent unauthorized access to MinKeePassMini with a PIN
- Remember database passwords in the device's secure keychain
- Optionally clear the clipboard after set time on devices that support background tasks
- Generate new passwords

License
-------

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

Credits
-------
MinKeePassMini
Copyright 2011 Jason Rush and John Flanagan. All rights reserved.
IOSKeePass
Copyright 2019-2022 Frank Hausmann. All rigts reserved

German Translation - Florian Holzapfel<br />
Japanese Translation - Katherine Lake<br />
Russian Translation - Foster "Forst" Snowhill<br />
Italian Translation - Emanuele Di Vita and Gabriele Cirulli<br />
Simplified Chinese Translation - Caspar Zhang and David Wong<br />
French Translation - Patrice Lachance<br />
Brazilian Portuguese Translation - BR Lingo<br />
Turkish Translation - Durul Dalkanat<br />

MinKeePassMini Icon - Gabriele Cirulli

Nuvola Icons
Copyright (c) 2003-2004  David Vignoni. All rights reserved.
Released under GNU Lesser General Public License (LGPL)
http://www.gnu.org/licenses/lgpl-2.1.html

KeePass Database Library
Copyright 2010 Qiang Yu. All rights reserved.

KeePassKit DB Library
KeePassKit - Cocoa KeePass Library Copyright (c) 2012-2016 Michael Starke, HicknHack Software GmbH

References
-------
- KeePassKit uses code from the following projects
- Argon2 Copyright (c) 2015 Daniel Dinu, Dmitry Khovratovich (main authors), Jean-Philippe Aumasson and Samuel Neves
- ChaCha20 Simple Copyright (c) 2014 insane coder (http://insanecoding.blogspot.com/, http://chacha20.insanecoding.org/)
- Twofish Copyright (c) 2002 by Niels Ferguson.
- FaviconFinder Created by William Lumley on 16/10/19.
- FileProvider Created by Amir Abbas Mousavian.
- TOCropviewController Copyright 2017-2020 Timothy Oliver. All rights reserved.
- TwitterTextEditor Copyright 2021 Twitter, Inc.
- SwiftSpinner Copyright (c) 2015-present Marin Todorov, Underplot ltd.
- KissXML Copyright (c) 2012 Robbie Hanson. All rights reserved.
- MinKeePassMini Copyright (c) 2011 Jason Rush and John Flanagan. All rights reserved.
- KeePass Database Library Copyright (c) 2010 Qiang Yu. All rights reserved.
- KeepassX Copyright (c) 2012 Felix Geyer debfx@fobos.de
- NSData Gzip Category from the CocoaDev Wiki
- NSData CommonCrypto Category Copyright (c) 2008-2009 Jim Dovey, All rights reserved.

