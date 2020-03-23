//
//  GRDKeychain.m
//  Guardian
//
//  Copyright © 2017 Sudo Security Group Inc. All rights reserved.
//

#import "GRDKeychain.h"

@interface GRDKeychain ()

@end

@implementation GRDKeychain

// TODO
// - look into if we should be using an app tag for this in the dictionary ???
// - find if there is a better way around "Enter VPN Password" bug than kSecAttrAccessibleAlwaysThisDeviceOnly (not even sure if this fixes it)
// - Use kSecAttrAccount for EAP username
// - Use kSecAttrServer for VPN server hostname
+ (OSStatus)storePassword:(NSString *)passwordStr forAccount:(NSString *)accountKeyStr {
    CFTypeRef result = NULL;
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    NSData *valueData = [passwordStr dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *secItem = @{
        (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService : bundleId,
        (__bridge id)kSecAttrAccessible : (__bridge id)kSecAttrAccessibleAlways,
        (__bridge id)kSecAttrSynchronizable : (__bridge id)kCFBooleanFalse,
        (__bridge id)kSecAttrAccount : accountKeyStr,
        (__bridge id)kSecValueData : valueData,
    };
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)secItem, &result);
    if (status == errSecSuccess) {
        //NSLog(@"[GRDKeychain] successfully stored password %@ for %@", passwordStr, accountKeyStr);
    } else {
        NSLog(@"[GRDKeychain] error storing password (%@): %ld", passwordStr, (long)status);
    }
    return status;
}

+ (NSString *)getPasswordStringForAccount:(NSString *)accountKeyStr {
    CFTypeRef copyResult = NULL;
    NSString *passStr = nil;
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    NSDictionary *query = @{
                            (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService : bundleId,
                            (__bridge id)kSecAttrAccount : accountKeyStr,
                            (__bridge id)kSecMatchLimit : (__bridge id)kSecMatchLimitOne,
                            (__bridge id)kSecReturnData : (__bridge id)kCFBooleanTrue,
                            };
    OSStatus results = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&copyResult);
    if (results == errSecSuccess) {
        //NSLog(@"[GRDKeychain] successfully copied password data %@ for %@", copyResult, accountKeyStr);
        passStr = [[NSString alloc] initWithBytes:[(__bridge_transfer NSData *)copyResult bytes]
                                           length:[(__bridge NSData *)copyResult length] encoding:NSUTF8StringEncoding];
    } else {
        NSLog(@"[GRDKeychain] error obtaining password data: %ld", (long)results);
    }
    
    return passStr;
}

+ (NSData *)getPasswordRefForAccount:(NSString *)accountKeyStr {
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    CFTypeRef copyResult = NULL;
    NSDictionary *query = @{
        (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService : bundleId,
        (__bridge id)kSecAttrAccount : accountKeyStr,
        (__bridge id)kSecMatchLimit : (__bridge id)kSecMatchLimitOne,
        (__bridge id)kSecReturnPersistentRef : (__bridge id)kCFBooleanTrue,
    };
    OSStatus results = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&copyResult);
    if (results == errSecSuccess) {
        //NSLog(@"[GRDKeychain] successfully copied password ref for %@", accountKeyStr);
    } else {
        NSLog(@"[GRDKeychain] error obtaining password ref: %ld", (long)results);
    }
    
    return (__bridge NSData *)copyResult;
}

+ (void)removeGuardianKeychainItems {
    NSArray *guardianKeys = @[kKeychainStr_EapUsername,
                              kKeychainStr_EapPassword,
                              kKeychainStr_AuthToken,
                              kKeychainStr_DeviceIdentifier];
    [guardianKeys enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self removeKeychanItemForAccount:obj];
    }];
}

+ (OSStatus)removeKeychanItemForAccount:(NSString *)accountKeyStr {
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    NSDictionary *query = @{
                            (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService : bundleId,
                            (__bridge id)kSecAttrAccount : accountKeyStr,
                            (__bridge id)kSecReturnPersistentRef : (__bridge id)kCFBooleanTrue,
                            };
    OSStatus result = SecItemDelete((__bridge CFDictionaryRef)query);
    if (result != errSecSuccess) {
        if (@available(iOS 11.3, *)) {
            NSString *errMessage = CFBridgingRelease(SecCopyErrorMessageString(result, nil));
            NSLog(@"[GRDKeychain] SecItemDelete error message: %@", errMessage);
        }
        NSLog(@"[GRDKeychain] error deleting password entry %@ with status: %ld", query, (long)result);
    }
    
    return result;
}

+ (void)removeAllKeychainItems {
    NSArray *secItemClasses = @[(__bridge id)kSecClassGenericPassword,
                                (__bridge id)kSecClassInternetPassword,
                                (__bridge id)kSecClassCertificate,
                                (__bridge id)kSecClassKey,
                                (__bridge id)kSecClassIdentity];
    for (id secItemClass in secItemClasses) {
        NSDictionary *itemClass = @{(__bridge id)kSecClass:secItemClass};
        NSLog(@"[DEBUG][removeAllKeychainItems] removed item class: %@", itemClass);
        SecItemDelete((__bridge CFDictionaryRef)itemClass);
    }
}

@end
