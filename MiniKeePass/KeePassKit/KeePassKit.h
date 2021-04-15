//
//  KeePassKit.h
//  KeePassKit
//
//  Created by Michael Starke on 28/10/15.
//  Copyright © 2015 HicknHack Software GmbH. All rights reserved.
//

@import Foundation;
//! Project version number for KeePassKit.
FOUNDATION_EXPORT double KeePassKitVersionNumber;

//! Project version string for KeePassKit.
FOUNDATION_EXPORT const unsigned char KeePassKitVersionString[];

#import "Utilites/KPKPlatformIncludes.h"
#import "Utilites//KPKTypes.h"
#import "Utilites/KPKUTIs.h"
#import "Utilites/KPKIconTypes.h"
#import "Format/KPKSynchronizationOptions.h"

#import "Utilites/KPKData.h"
#import "Utilites/KPKNumber.h"
#import "Utilites/KPKPair.h"
#import "Token/KPKToken.h"

#import "Utilites/KPKScopedSet.h"
#import "Utilites/KPKReferenceBuilder.h"

#import "Format/KPKFormat.h"
#import "Format/KPKKdbxFormat.h"
#import "Keyderivation/KPKKeyDerivation.h"
#import "Keyderivation/KPKAESKeyDerivation.h"
#import "Keyderivation/KPKArgon2DKeyDerivation.h"
#import "Keyderivation/KPKArgon2IDKeyDerivation.h"
#import "Keys/KPKCompositeKey.h"
#import "Keys/KPKKey.h"
#import "Keys/KPKPasswordKey.h"
#import "Keys/KPKFileKey.h"
#import "Cipher/KPKCipher.h"
#import "Cipher/KPKChaCha20Cipher.h"
#import "Cipher/KPKAESCipher.h"
#import "Cipher/KPKTwofishCipher.h"
#import "Cryptography/KPKOTPGenerator.h"
#import "Cryptography/KPKHmacOTPGenerator.h"
#import "Cryptography/KPKTimeOTPGenerator.h"
#import "Cryptography/KPKSteamOTPGenerator.h"

#import "Core/KPKTree.h"
#import "IO/KPKTree+Serializing.h"
#import "Core/KPKNode.h"
#import "Core/KPKEntry.h"
#import "Core/KPKGroup.h"

#import "Core/KPKBinary.h"
#import "Core/KPKAttribute.h"
#import "Core/KPKIcon.h"
#import "Core/KPKDeletedNode.h"
#import "Core/KPKMetaData.h"
#import "Core/KPKTimeInfo.h"
#import "Core/KPKAutotype.h"
#import "Core/KPKWindowAssociation.h"

#import "Protocols/KPKModificationRecording.h"
#import "Commands/KPKCommandEvaluationContext.h"

#import "Core/KPKErrors.h"

#import "Categories/NSData+KPKHashedData.h"
#import "Categories/NSData+KPKKeyfile.h"
#import "Categories/NSData+KPKRandom.h"
#import "Categories/NSData+KPKBase32.h"
#import "Categories/NSData+CommonCrypto.h"
#import "Categories/NSDictionary+KPKVariant.h"
#import "Categories/NSString+KPKCommands.h"
#import "Categories/NSString+KPKEmpty.h"
#import "Categories/NSString+KPKXmlUtilities.h"
#import "Categories/NSUUID+KPKAdditions.h"
#import "Categories/NSUIColor+KPKAdditions.h"
#import "Categories/NSUIImage+KPKAdditions.h"
#import "Categories/NSURL+KPKAdditions.h"

#import "Streams/KPKSalsa20RandomStream.h"

