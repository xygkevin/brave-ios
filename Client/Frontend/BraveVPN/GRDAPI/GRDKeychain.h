//
//  GRDKeychain.h
//  Guardian
//
//  Copyright © 2017 Sudo Security Group Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kKeychainStr_EapUsername @"eap-username"
#define kKeychainStr_EapPassword @"eap-password"
#define kKeychainStr_DeviceIdentifier @"device-token"
#define kKeychainStr_AuthToken @"auth-token"

@interface GRDKeychain : NSObject

+ (OSStatus)storePassword:(NSString *)passwordStr forAccount:(NSString *)accountKeyStr;
+ (NSString *)getPasswordStringForAccount:(NSString *)accountKeyStr;
+ (NSData *)getPasswordRefForAccount:(NSString *)accountKeyStr;
+ (void)removeAllKeychainItems;
+ (void)removeGuardianKeychainItems;

@end
