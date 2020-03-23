//
//  GRDVPNHelper.m
//  Guardian
//
//  Created by will on 4/28/19.
//  Copyright © 2019 Sudo Security Group Inc. All rights reserved.
//

#import "GRDVPNHelper.h"
#import "VPNConstants.h"

@implementation GRDVPNHelper

+ (OSStatus)saveEapUsername:(NSString *)usernameStr {
   return [GRDKeychain storePassword:usernameStr forAccount:kKeychainStr_EapUsername];
}

+ (OSStatus)saveEapPassword:(NSString *)passwordStr {
   return [GRDKeychain storePassword:passwordStr forAccount:kKeychainStr_EapPassword];
}

+ (OSStatus)saveApiAuthToken:(NSString *)apiAuthToken {
   return [GRDKeychain storePassword:apiAuthToken forAccount:kKeychainStr_AuthToken];
}

+ (OSStatus)saveApiDeviceIdentifier:(NSString *)apiDeviceIdentifier {
   return [GRDKeychain storePassword:apiDeviceIdentifier forAccount:kKeychainStr_DeviceIdentifier];
}

+ (void)saveAllInOneBoxHostname:(NSString *)host {
    [[NSUserDefaults standardUserDefaults] setObject:host forKey:@"GatewayHostname-Override"];
    [[NSUserDefaults standardUserDefaults] setObject:host forKey:@"APIHostname-Override"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)saveApiHostname:(NSString *)host {
    [[NSUserDefaults standardUserDefaults] setObject:host forKey:@"APIHostname-Override"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)saveGatewayHostname:(NSString *)host {
    [[NSUserDefaults standardUserDefaults] setObject:host forKey:@"GatewayHostname-Override"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)clearVpnConfiguration {
    [GRDKeychain removeGuardianKeychainItems];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"APIHostname-Override"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"GatewayHostname-Override"];
    
    // make sure Settings tab UI updates to not erroneously show name of cleared server
    [[NSNotificationCenter defaultCenter] postNotificationName:kGRDServerUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:kGRDLocationUpdatedNotification object:nil];
}

+ (NSString *)loadApiHostname {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"APIHostname-Override"];
}

+ (NSString *)loadGatewayHostname {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"GatewayHostname-Override"];
}

+ (NSString *)loadEapUsername {
    return [GRDKeychain getPasswordStringForAccount:kKeychainStr_EapUsername];
}

+ (NSData *)loadEapPasswordRef {
    return [GRDKeychain getPasswordRefForAccount:kKeychainStr_EapPassword];
}

+ (NSString *)loadApiAuthToken {
    return [GRDKeychain getPasswordStringForAccount:kKeychainStr_AuthToken];
}

+ (NSString *)loadApiDeviceIdentifier {
    return [GRDKeychain getPasswordStringForAccount:kKeychainStr_DeviceIdentifier];
}

+ (BOOL)isPayingUser {
    // We do not offer a freemium account, this should always return true.
    return true;
    // return [[NSUserDefaults standardUserDefaults] boolForKey:kGuardianSuccessfulSubscription];
}

+ (void)setIsPayingUser:(BOOL)isPaying {
    [[NSUserDefaults standardUserDefaults] setBool:isPaying forKey:kIsPremiumUser];
    [[NSUserDefaults standardUserDefaults] setBool:isPaying forKey:kGuardianSuccessfulSubscription];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)defaultBoxHostname {
    return kSGAPI_DefaultHostname;
}

+ (NSArray *)vpnOnDemandRules {
    // RULE: do not take action if certain types of inflight wifi, needed because they do not detect captive portal properly
    NEOnDemandRuleIgnore *onboardIgnoreRule = [[NEOnDemandRuleIgnore alloc] init];
    onboardIgnoreRule.interfaceTypeMatch = NEOnDemandRuleInterfaceTypeWiFi;
    onboardIgnoreRule.SSIDMatch = @[@"gogoinflight", @"AA Inflight", @"AA-Inflight"];
    
    // RULE: disconnect if 'xfinitywifi' as they apparently block IPSec traffic (???)
    NEOnDemandRuleDisconnect *xfinityDisconnect = [[NEOnDemandRuleDisconnect alloc] init];
    xfinityDisconnect.interfaceTypeMatch = NEOnDemandRuleInterfaceTypeWiFi;
    xfinityDisconnect.SSIDMatch = @[@"xfinitywifi"];
    
    // RULE: connect to VPN automatically if server reports that it is running OK
    NEOnDemandRuleConnect *vpnServerConnectRule = [[NEOnDemandRuleConnect alloc] init];
    vpnServerConnectRule.interfaceTypeMatch = NEOnDemandRuleInterfaceTypeAny;
    vpnServerConnectRule.probeURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@%@", [self loadApiHostname], kSGAPI_ServerStatus]];
    
    NSArray *onDemandArr = @[onboardIgnoreRule, xfinityDisconnect, vpnServerConnectRule];
    return onDemandArr;
}

+ (NSArray *)vpnOnDemandRulesFree {
    // RULE: do not take action if certain types of inflight wifi, needed because they do not detect captive portal properly
    NEOnDemandRuleIgnore *onboardIgnoreRule = [[NEOnDemandRuleIgnore alloc] init];
    onboardIgnoreRule.interfaceTypeMatch = NEOnDemandRuleInterfaceTypeWiFi;
    onboardIgnoreRule.SSIDMatch = @[@"gogoinflight", @"AA Inflight", @"AA-Inflight"];
    
    // RULE: disconnect if 'xfinitywifi' as they apparently block IPSec traffic (???)
    NEOnDemandRuleDisconnect *xfinityDisconnect = [[NEOnDemandRuleDisconnect alloc] init];
    xfinityDisconnect.interfaceTypeMatch = NEOnDemandRuleInterfaceTypeWiFi;
    xfinityDisconnect.SSIDMatch = @[@"xfinitywifi"];
    
    // RULE: connect to VPN automatically if server reports that it is running OK
    NEOnDemandRuleConnect *vpnServerConnectRule = [[NEOnDemandRuleConnect alloc] init];
    vpnServerConnectRule.interfaceTypeMatch = NEOnDemandRuleInterfaceTypeWiFi; //FIX: won't disconnect as users roam among multiple Access Points on big wifi networks now
    vpnServerConnectRule.probeURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@%@", [self loadApiHostname], kSGAPI_ServerStatus]];
    
    NSArray *onDemandArr = @[onboardIgnoreRule, xfinityDisconnect, vpnServerConnectRule];
    return onDemandArr;
}

+ (NSArray *)googleCloudServerHostnames {
    NSArray *gceServers = @[kServerBetaIpsecOne, kServerBetaIpsecTwo, kServerBetaIpsecThree, kServerBetaIpsecFour,
                            kServerBetaIpsecFive, kServerBetaIpsecSix, kServerBetaIpsecSeven, kServerBetaIpsecEight,
                            kServerBetaIpsecNine, kServerBetaIpsecTen, kServerBetaIpsecEleven, kServerBetaIpsecTwelve,
                            kServerBetaIpsecThirteen, kServerBetaIpsecFourteen, kServerBetaIpsecCentral5, kServerBetaIpsecCentral6,
                            kServerBetaIpsecCentral7, kServerBetaIpsecCentral8, kServerBetaIpsecCentral9, kServerBetaIpsecCentral10,
                            @"beta-migrated-us-east-1.sudosecuritygroup.com",
                            @"beta-migrated-us-east-2.sudosecuritygroup.com",
                            @"beta-migrated-us-west-1.sudosecuritygroup.com",
                            @"beta-migrated-us-west-2.sudosecuritygroup.com" ];
    
    return gceServers;
}

+ (NSArray *)usaEastCoastHostnames {
    NSArray *serversArr = nil;
    
    if([[GRDServerManager sharedManager] usaEastCoastHostnames] != nil) {
        NSLog(@"[DEBUG][usaEastCoast] cached usaEastCoastHostnames == %@", [[GRDServerManager sharedManager] usaEastCoastHostnames]);
        serversArr = [[GRDServerManager sharedManager] usaEastCoastHostnames];
        
        if([serversArr count] == 0) {
            NSLog(@"[DEBUG][usaEastCoast] no operational servers! returning all_usa array instead...");
            serversArr = [[GRDServerManager sharedManager] allUsaHostnames];
        }
    } else {
        NSLog(@"[DEBUG][usaEastCoast] no cached servers, using already known...");
        serversArr = @[ @"newjersey-ipsec-free-1.sudosecuritygroup.com",
                        @"newjersey-ipsec-free-2.sudosecuritygroup.com",
                        @"newjersey-ipsec-free-3.sudosecuritygroup.com",
                        @"newjersey-ipsec-free-4.sudosecuritygroup.com",
                        @"newjersey-ipsec-free-5.sudosecuritygroup.com",
                        @"newjersey-ipsec-free-6.sudosecuritygroup.com" ];
    }
    
    return serversArr;
}

+ (NSArray *)usaCentralHostnames {
    NSArray *serversArr = nil;
    
    if([[GRDServerManager sharedManager] usaCentralHostnames] != nil) {
        NSLog(@"[DEBUG][usaCentral] cached usaCentralHostnames == %@", [[GRDServerManager sharedManager] usaCentralHostnames]);
        serversArr = [[GRDServerManager sharedManager] usaCentralHostnames];
        
        if([serversArr count] == 0) {
            NSLog(@"[DEBUG][usaCentral] no operational servers! returning all_usa array instead...");
            serversArr = [[GRDServerManager sharedManager] allUsaHostnames];
        }
    } else {
        NSLog(@"[DEBUG][usaCentral] no cached servers, using already known...");
        serversArr = @[ @"dallas-ipsec-1.guardianapp.com", @"atlanta-ipsec-1.guardianapp.com" ];
    }
    
    return serversArr;
}

+ (NSArray *)usaMountainHostnames {
    NSArray *serversArr = nil;
    
    if([[GRDServerManager sharedManager] usaMountainHostnames] != nil) {
        NSLog(@"[DEBUG][usaMountain] cached usaMountainHostnames == %@", [[GRDServerManager sharedManager] usaMountainHostnames]);
        serversArr = [[GRDServerManager sharedManager] usaMountainHostnames];
        
        if([serversArr count] == 0) {
            NSLog(@"[DEBUG][usaMountain] no operational servers! returning all_usa array instead...");
            serversArr = [[GRDServerManager sharedManager] allUsaHostnames];
        }
    } else {
        NSLog(@"[DEBUG][usaMountain] no cached servers, using already known...");
        serversArr = @[ @"dallas-ipsec-1.guardianapp.com" ];
    }
    
    return serversArr;
}

+ (NSArray *)usaWestCoastHostnames {
    NSArray *serversArr = nil;
    
    if([[GRDServerManager sharedManager] usaWestCoastHostnames] != nil) {
        NSLog(@"[DEBUG][usaWestCoast] cached usaWestCoastHostnames == %@", [[GRDServerManager sharedManager] usaWestCoastHostnames]);
        serversArr = [[GRDServerManager sharedManager] usaWestCoastHostnames];
        
        if([serversArr count] == 0) {
            NSLog(@"[DEBUG][usaWestCoast] no operational servers! returning all_usa array instead...");
            serversArr = [[GRDServerManager sharedManager] allUsaHostnames];
        }
    } else {
        NSLog(@"[DEBUG][usaWestCoast] no cached servers, using already known...");
        serversArr = @[ @"sanjose-ipsec-free-1.sudosecuritygroup.com",
                        @"sanjose-ipsec-free-2.sudosecuritygroup.com",
                        @"sanjose-ipsec-free-3.sudosecuritygroup.com",
                        @"sanjose-ipsec-free-4.sudosecuritygroup.com",
                        @"sanjose-ipsec-free-5.sudosecuritygroup.com",
                        @"sanjose-ipsec-free-6.sudosecuritygroup.com" ];
    }
    
    return serversArr;
}

+ (NSArray *)canadaHostnames {
    NSArray *serversArr = nil;
    
    if([[GRDServerManager sharedManager] canadaHostnames] != nil) {
        NSLog(@"[DEBUG][canada] cached canadaHostnames == %@", [[GRDServerManager sharedManager] canadaHostnames]);
        serversArr = [[GRDServerManager sharedManager] canadaHostnames];
    } else {
        NSLog(@"[DEBUG][canada] no cached servers, using already known...");
        serversArr = @[ @"beauharnois-ipsec-1.sudosecuritygroup.com", @"beauharnois-ipsec-2.sudosecuritygroup.com" ];
    }
    
    return serversArr;
}

+ (NSArray *)allHighCapacityUsaHostnames {
    NSArray *serversArr = nil;
    
    if([[GRDServerManager sharedManager] allUsaHostnames] != nil) {
        NSLog(@"[DEBUG][allHighCapacityUsaHostnames] cached allUsaHostnames == %@", [[GRDServerManager sharedManager] allUsaHostnames]);
        serversArr = [[GRDServerManager sharedManager] allUsaHostnames];
    } else {
        NSLog(@"[DEBUG][allHighCapacityUsaHostnames] no cached servers, using already known...");
        if([self isPayingUser] == YES) {
            serversArr = @[ @"newjersey-ipsec-1.guardianapp.com",
                            @"newjersey-ipsec-2.guardianapp.com",
                            @"newjersey-ipsec-3.guardianapp.com",
                            @"newjersey-ipsec-4.guardianapp.com",
                            @"newjersey-ipsec-5.guardianapp.com",
                            @"newjersey-ipsec-6.guardianapp.com",
                            @"newjersey-ipsec-7.guardianapp.com",
                            @"newjersey-ipsec-8.guardianapp.com",
                            @"newjersey-ipsec-9.guardianapp.com",
                            @"newjersey-ipsec-10.guardianapp.com",
                            @"newjersey-ipsec-11.guardianapp.com",
                            @"newjersey-ipsec-12.guardianapp.com",
                            @"newjersey-ipsec-13.guardianapp.com",
                            @"newjersey-ipsec-14.guardianapp.com",
                            @"newjersey-ipsec-15.guardianapp.com",
                            @"newjersey-ipsec-16.guardianapp.com",
                            @"newjersey-ipsec-17.guardianapp.com",
                            @"newjersey-ipsec-18.guardianapp.com",
                            @"newjersey-ipsec-19.guardianapp.com",
                            @"newjersey-ipsec-20.guardianapp.com",
                            @"sanjose-ipsec-1.guardianapp.com",
                            @"sanjose-ipsec-2.guardianapp.com",
                            @"sanjose-ipsec-3.guardianapp.com",
                            @"sanjose-ipsec-4.guardianapp.com",
                            @"sanjose-ipsec-5.guardianapp.com",
                            @"sanjose-ipsec-6.guardianapp.com",
                            @"sanjose-ipsec-7.guardianapp.com",
                            @"sanjose-ipsec-8.guardianapp.com",
                            @"sanjose-ipsec-9.guardianapp.com",
                            @"sanjose-ipsec-10.guardianapp.com",
                            @"sanjose-ipsec-11.guardianapp.com",
                            @"sanjose-ipsec-12.guardianapp.com",
                            @"sanjose-ipsec-13.guardianapp.com",
                            @"sanjose-ipsec-14.guardianapp.com",
                            @"sanjose-ipsec-15.guardianapp.com",
                            @"sanjose-ipsec-16.guardianapp.com",
                            @"sanjose-ipsec-17.guardianapp.com",
                            @"sanjose-ipsec-18.guardianapp.com",
                            @"sanjose-ipsec-19.guardianapp.com",
                            @"sanjose-ipsec-20.guardianapp.com" ];
        } else {
            serversArr = @[ @"newjersey-ipsec-free-1.sudosecuritygroup.com",
                            @"newjersey-ipsec-free-2.sudosecuritygroup.com",
                            @"newjersey-ipsec-free-3.sudosecuritygroup.com",
                            @"newjersey-ipsec-free-4.sudosecuritygroup.com",
                            @"newjersey-ipsec-free-5.sudosecuritygroup.com",
                            @"newjersey-ipsec-free-6.sudosecuritygroup.com",
                            @"sanjose-ipsec-free-1.sudosecuritygroup.com",
                            @"sanjose-ipsec-free-2.sudosecuritygroup.com",
                            @"sanjose-ipsec-free-3.sudosecuritygroup.com",
                            @"sanjose-ipsec-free-4.sudosecuritygroup.com",
                            @"sanjose-ipsec-free-5.sudosecuritygroup.com",
                            @"sanjose-ipsec-free-6.sudosecuritygroup.com" ];
        }
    }
    
    return serversArr;
}

+ (NSArray *)swedenHostnames {
    NSArray *serversArr = nil;
    
    if([[GRDServerManager sharedManager] swedenHostnames] != nil) {
        NSLog(@"[DEBUG][sweden] cached swedenHostnames == %@", [[GRDServerManager sharedManager] swedenHostnames]);
        serversArr = [[GRDServerManager sharedManager] swedenHostnames];
        
        if([serversArr count] == 0) {
            NSLog(@"[DEBUG][sweden] no operational servers! returning all_eu array instead...");
            serversArr = [[GRDServerManager sharedManager] allEuropeHostnames];
        }
    } else {
        NSLog(@"[DEBUG][sweden] no cached servers, using already known...");
        serversArr = @[ @"sweden-ipsec-1.sudosecuritygroup.com" ];
    }
    
    return serversArr;
}

+ (NSArray *)polandHostnames {
    NSArray *serversArr = nil;
    
    if([[GRDServerManager sharedManager] polandHostnames] != nil) {
        NSLog(@"[DEBUG][poland] cached polandHostnames == %@", [[GRDServerManager sharedManager] polandHostnames]);
        serversArr = [[GRDServerManager sharedManager] polandHostnames];
        
        if([serversArr count] == 0) {
            NSLog(@"[DEBUG][poland] no operational servers! returning all_eu array instead...");
            serversArr = [[GRDServerManager sharedManager] allEuropeHostnames];
        }
    } else {
        NSLog(@"[DEBUG][poland] no cached servers, using already known...");
        serversArr = @[ @"poland-ipsec-1.sudosecuritygroup.com" ];
    }
    
    return serversArr;
}

+ (NSArray *)franceHostnames {
    NSArray *serversArr = nil;
    
    if([[GRDServerManager sharedManager] franceHostnames] != nil) {
        NSLog(@"[DEBUG][france] cached franceHostnames == %@", [[GRDServerManager sharedManager] franceHostnames]);
        serversArr = [[GRDServerManager sharedManager] franceHostnames];
        
        if([serversArr count] == 0) {
            NSLog(@"[DEBUG][france] no operational servers! returning all_eu array instead...");
            serversArr = [[GRDServerManager sharedManager] allEuropeHostnames];
        }
    } else {
        NSLog(@"[DEBUG][france] no cached servers, using already known...");
        serversArr = @[ kServer_France_1 ];
    }
    
    return serversArr;
}

+ (NSArray *)ukHostnames {
    NSArray *serversArr = nil;
    
    if([[GRDServerManager sharedManager] ukHostnames] != nil) {
        NSLog(@"[DEBUG][uk] cached ukHostnames == %@", [[GRDServerManager sharedManager] ukHostnames]);
        serversArr = [[GRDServerManager sharedManager] ukHostnames];
        
        if([serversArr count] == 0) {
            NSLog(@"[DEBUG][uk] no operational servers! returning all_eu array instead...");
            serversArr = [[GRDServerManager sharedManager] allEuropeHostnames];
        }
    } else {
        NSLog(@"[DEBUG][uk] no cached servers, using already known...");
        serversArr = @[ @"london-ipsec-1.sudosecuritygroup.com",
                        @"london-ipsec-2.sudosecuritygroup.com",
                        @"london-ipsec-3.sudosecuritygroup.com",
                        @"london-ipsec-4.sudosecuritygroup.com" ];
    }
    
    return serversArr;
}

+ (NSArray *)finlandHostnames {
    NSArray *serversArr = nil;
    
    if([[GRDServerManager sharedManager] finlandHostnames] != nil) {
        NSLog(@"[DEBUG][finland] cached finlandHostnames == %@", [[GRDServerManager sharedManager] finlandHostnames]);
        serversArr = [[GRDServerManager sharedManager] finlandHostnames];
        
        if([serversArr count] == 0) {
            NSLog(@"[DEBUG][finland] no operational servers! returning all_eu array instead...");
            serversArr = [[GRDServerManager sharedManager] allEuropeHostnames];
        }
    } else {
        NSLog(@"[DEBUG][finland] no cached servers, using already known...");
        serversArr = @[ @"helsinki-ipsec-1.sudosecuritygroup.com" ];
    }
    
    return serversArr;
}

+ (NSArray *)germanyHostnames {
    NSArray *serversArr = nil;
    
    if([[GRDServerManager sharedManager] germanyHostnames] != nil) {
        NSLog(@"[DEBUG][germany] cached germanyHostnames == %@", [[GRDServerManager sharedManager] germanyHostnames]);
        serversArr = [[GRDServerManager sharedManager] germanyHostnames];
        
        if([serversArr count] == 0) {
            NSLog(@"[DEBUG][germany] no operational servers! returning all_eu array instead...");
            serversArr = [[GRDServerManager sharedManager] allEuropeHostnames];
        }
    } else {
        NSLog(@"[DEBUG][germany] no cached servers, using already known...");
        serversArr = @[ kServerBeta_FRA_1, kServerBeta_FRA_2,
                        kServer_Germany_1, kServer_Germany_2 ];
    }
    
    return serversArr;
}

+ (NSArray *)amsterdamHostnames {
    NSArray *serversArr = nil;
    
    if([[GRDServerManager sharedManager] amsterdamHostnames] != nil) {
        NSLog(@"[DEBUG][amsterdam] cached amsterdamHostnames == %@", [[GRDServerManager sharedManager] amsterdamHostnames]);
        serversArr = [[GRDServerManager sharedManager] amsterdamHostnames];
        
        if([serversArr count] == 0) {
            NSLog(@"[DEBUG][amsterdam] no operational servers! returning all_eu array instead...");
            serversArr = [[GRDServerManager sharedManager] allEuropeHostnames];
        }
    } else {
        NSLog(@"[DEBUG][amsterdam] no cached servers, using already known...");
        serversArr = @[ @"amsterdam-ipsec-1.sudosecuritygroup.com",
                        @"amsterdam-ipsec-2.sudosecuritygroup.com",
                        @"amsterdam-ipsec-3.sudosecuritygroup.com",
                        @"amsterdam-ipsec-4.sudosecuritygroup.com",
                        @"amsterdam-ipsec-5.sudosecuritygroup.com",
                        @"amsterdam-ipsec-6.sudosecuritygroup.com" ];
    }
    
    return serversArr;
}

+ (NSArray *)australiaHostnames {
    NSArray *serversArr = nil;
    
    if([[GRDServerManager sharedManager] australiaHostnames] != nil) {
        NSLog(@"[DEBUG][australia] cached australiaHostnames == %@", [[GRDServerManager sharedManager] australiaHostnames]);
        serversArr = [[GRDServerManager sharedManager] australiaHostnames];
        
        if([serversArr count] == 0) {
            NSLog(@"[DEBUG][australia] no operational servers! returning all USA hostnames array instead...");
            serversArr = [[GRDServerManager sharedManager] allUsaHostnames];
        }
    } else {
        NSLog(@"[DEBUG][australia] no cached servers, using already known...");
        serversArr = @[ @"sydney-ipsec-1.guardianapp.com",
                        @"sydney-ipsec-1b.sudosecuritygroup.com" ];
    }
    
    return serversArr;
}

+ (NSArray *)southAmericaHostnames {
    NSArray *serversArr = nil;
    
    if([[GRDServerManager sharedManager] southAmericaHostnames] != nil) {
        NSLog(@"[DEBUG][south america] cached southAmericaHostnames == %@", [[GRDServerManager sharedManager] southAmericaHostnames]);
        serversArr = [[GRDServerManager sharedManager] southAmericaHostnames];
        
        if([serversArr count] == 0) {
            NSLog(@"[DEBUG][south america] no operational servers! returning all USA hostnames array instead...");
            serversArr = [[GRDServerManager sharedManager] allUsaHostnames];
        }
    } else {
        NSLog(@"[DEBUG][south america] no cached servers, using already known...");
        serversArr = @[ @"latam-cw-ipsec-1.sudosecuritygroup.com" ];
    }
    
    return serversArr;
}

+ (NSArray *)indiaHostnames {
    NSArray *serversArr = nil;
    
    if([[GRDServerManager sharedManager] indiaHostnames] != nil) {
        NSLog(@"[DEBUG][india] cached indiaHostnames == %@", [[GRDServerManager sharedManager] indiaHostnames]);
        serversArr = [[GRDServerManager sharedManager] indiaHostnames];
        
        if([serversArr count] == 0) {
            NSLog(@"[DEBUG][india] no operational servers! returning all_asia array instead...");
            serversArr = [[GRDServerManager sharedManager] allAsiaHostnames];
        }
    } else {
        NSLog(@"[DEBUG][india] no cached servers, using already known...");
        serversArr = @[ kServer_India_1, kServer_India_2, kServer_India_3, kServer_India_4 ];
    }
    
    return serversArr;
}

+ (NSArray *)taiwanHostnames {
    NSArray *serversArr = nil;
    
    if([[GRDServerManager sharedManager] taiwanHostnames] != nil) {
        NSLog(@"[DEBUG][taiwan] cached taiwanHostnames == %@", [[GRDServerManager sharedManager] taiwanHostnames]);
        serversArr = [[GRDServerManager sharedManager] taiwanHostnames];
        
        if([serversArr count] == 0) {
            NSLog(@"[DEBUG][taiwan] no operational servers! returning all_asia array instead...");
            serversArr = [[GRDServerManager sharedManager] allAsiaHostnames];
        }
    } else {
        NSLog(@"[DEBUG][taiwan] no cached servers, using already known...");
        serversArr = @[ @"taiwan-ipsec-1.sudosecuritygroup.com" ];
    }
    
    return serversArr;
}

+ (NSArray *)japanHostnames {
    NSArray *serversArr = nil;
    
    if([[GRDServerManager sharedManager] japanHostnames] != nil) {
        NSLog(@"[DEBUG][japan] cached japanHostnames == %@", [[GRDServerManager sharedManager] japanHostnames]);
        serversArr = [[GRDServerManager sharedManager] japanHostnames];
        
        if([serversArr count] == 0) {
            NSLog(@"[DEBUG][japan] no operational servers! returning all_asia array instead...");
            serversArr = [[GRDServerManager sharedManager] allAsiaHostnames];
        }
    } else {
        NSLog(@"[DEBUG][japan] no cached servers, using already known...");
        serversArr = @[ @"japan-ipsec-free-1.sudosecuritygroup.com" ];
    }
    
    return serversArr;
}

+ (NSArray *)singaporeHostnames {
    NSArray *serversArr = nil;
    
    if([[GRDServerManager sharedManager] singaporeHostnames] != nil) {
        NSLog(@"[DEBUG][singapore] cached singaporeHostnames == %@", [[GRDServerManager sharedManager] singaporeHostnames]);
        serversArr = [[GRDServerManager sharedManager] singaporeHostnames];
        
        if([serversArr count] == 0) {
            NSLog(@"[DEBUG][singapore] no operational servers! returning all_asia array instead...");
            serversArr = [[GRDServerManager sharedManager] allAsiaHostnames];
        }
    } else {
        NSLog(@"[DEBUG][singapore] no cached servers, using already known...");
        serversArr = @[ @"singapore-ipsec-1.sudosecuritygroup.com" ];
    }
    
    return serversArr;
}

+ (NSArray *)hongkongHostnames {
    NSArray *serversArr = nil;
    
    if([[GRDServerManager sharedManager] hongkongHostnames] != nil) {
        NSLog(@"[DEBUG][hongkong] cached hongkongHostnames == %@", [[GRDServerManager sharedManager] hongkongHostnames]);
        serversArr = [[GRDServerManager sharedManager] hongkongHostnames];
        
        if([serversArr count] == 0) {
            NSLog(@"[DEBUG][hongkong] no operational servers! returning all_asia array instead...");
            serversArr = [[GRDServerManager sharedManager] allAsiaHostnames];
        }
    } else {
        NSLog(@"[DEBUG][hongkong] no cached servers, using already known...");
        serversArr = @[ kServerBeta_HKG_1 ];
    }
    
    return serversArr;
}

+ (NEVPNProtocolIKEv2 *)prepareIKEv2ParametersForServer:(NSString *)server
                                            eapUsername:(NSString *)user
                                         eapPasswordRef:(NSData *)passRef
                                    withCertificateType:(NEVPNIKEv2CertificateType)certType {
    NEVPNProtocolIKEv2 *protocolConfig = [[NEVPNProtocolIKEv2 alloc] init];
    protocolConfig.serverAddress = server;
    protocolConfig.serverCertificateCommonName = server;
    protocolConfig.remoteIdentifier = server;
    protocolConfig.enablePFS = YES;
    protocolConfig.disableMOBIKE = NO;
    protocolConfig.disconnectOnSleep = NO;
    protocolConfig.authenticationMethod = NEVPNIKEAuthenticationMethodCertificate; // to validate the server-side cert issued by LetsEncrypt
    protocolConfig.certificateType = certType;
    protocolConfig.useExtendedAuthentication = YES;
    protocolConfig.username = user;
    protocolConfig.passwordReference = passRef;
    protocolConfig.deadPeerDetectionRate = NEVPNIKEv2DeadPeerDetectionRateLow; /* increase DPD tolerance from default 10min to 30min */
    
    
    
    // TO DO - find out if this all works fine with Always On VPN (allegedly uses two open tunnels at once, for wifi/cellular interfaces)
    // - may require settings "uniqueids" in VPN-side of config to "never" otherwise same EAP creds on both tunnels may cause an issue
    
    /*
     Params for VPN: AES-256, SHA-384, ECDH over the curve P-384 (DH Group 20)
     TLS for PKI: TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
     */
    [[protocolConfig IKESecurityAssociationParameters] setEncryptionAlgorithm:NEVPNIKEv2EncryptionAlgorithmAES256];
    [[protocolConfig IKESecurityAssociationParameters] setIntegrityAlgorithm:NEVPNIKEv2IntegrityAlgorithmSHA384];
    [[protocolConfig IKESecurityAssociationParameters] setDiffieHellmanGroup:NEVPNIKEv2DiffieHellmanGroup20];
    [[protocolConfig IKESecurityAssociationParameters] setLifetimeMinutes:1440]; // 24 hours
    [[protocolConfig childSecurityAssociationParameters] setEncryptionAlgorithm:NEVPNIKEv2EncryptionAlgorithmAES256GCM];
    [[protocolConfig childSecurityAssociationParameters] setDiffieHellmanGroup:NEVPNIKEv2DiffieHellmanGroup20];
    [[protocolConfig childSecurityAssociationParameters] setLifetimeMinutes:480]; // 8 hours
    
    return protocolConfig;
}

+ (NSString *)selectRandomGoogleCloudHostname {
    NSUInteger r = arc4random_uniform(20);
    NSLog(@"[DEBUG][selectRandomGoogleCloudHostname] r=%u", (unsigned int)r);
    NSString *hostnameToUse = [[self googleCloudServerHostnames] objectAtIndex:r];
    NSLog(@"[DEBUG][selectRandomGoogleCloudHostname] random selected hostname = %@", hostnameToUse);
    
    return hostnameToUse;
}

+ (NSString *)selectRandomProximateHostname {
    // TODO: Remove after all servers are up
    
    NSArray *serversArr = nil;
    
    // TO DO - refactor this soon for readability. leaving it be for now.
    if ([[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Los_Angeles"]] ||
       [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Cancun"]] ||
       [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Anchorage"]] ||
       [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Tijuana"]] ||
       [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Pacific/Honolulu"]]) {
        NSLog(@"[DEBUG] timezone is near USA west coast, using west coast server array...");
        serversArr = [self usaWestCoastHostnames];
    } else if ([[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Phoenix"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Denver"]]) {
        NSLog(@"[DEBUG] timezone is near USA mountain time, using mountain time USA server array...");
        serversArr = [self usaMountainHostnames];
    } else if ([[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Chicago"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Mexico_City"]]) {
        NSLog(@"[DEBUG] timezone is near USA central, using central USA server array...");
        serversArr = [self usaCentralHostnames];
    } else if ([[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Montreal"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Vancouver"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Halifax"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Toronto"]] ||
			  [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Atikokan"]] ||
			  [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Blanc-Sablon"]] ||
			  [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Cambridge_Bay"]] ||
			  [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Creston"]] ||
			  [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Danmarkshavn"]] ||
			  [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Dawson"]] ||
			  [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Dawson_Creek"]] ||
			  [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Edmonton"]] ||
			  [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Fort_Nelson"]] ||
			  [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Glace_Bay"]] ||
			  [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Godthab"]] ||
			  [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Goose_Bay"]] ||
			  [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Inuvik"]] ||
			  [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Iqaluit"]] ||
			  [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Miquelon"]] ||
			  [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Moncton"]] ||
			  [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Nipigon"]] ||
			  [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Pangnirtung"]] ||
			  [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Rainy_River"]] ||
			  [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Rankin_Inlet"]] ||
			  [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Regina"]] ||
			  [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Resolute"]] ||
			  [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Scoresbysund"]] ||
			  [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/St_Johns"]] ||
			  [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Thule"]] ||
			  [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Thunder_Bay"]] ||
			  [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Whitehorse"]] ||
			  [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Winnipeg"]] ||
			  [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Yellowknife"]] ||
			  [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Atlantic/Canary"]]) {
        NSLog(@"[DEBUG] timezone is near canada, using canada server array...");
        serversArr = [self canadaHostnames];
    } else if ([[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Aruba"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Barbados"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Belize"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Atlantic/Bermuda"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Bogota"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Cayman"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Costa_Rica"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Havana"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Jamaica"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Nassau"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/New_York"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Panama"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Port-au-Prince"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Puerto_Rico"]]) {
        NSLog(@"[DEBUG] timezone is near USA east coast, using east coast USA server array...");
        serversArr = [self usaEastCoastHostnames];
    } else if ([[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Australia/Adelaide"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Australia/Brisbane"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Australia/Broken_Hill"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Australia/Currie"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Australia/Darwin"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Australia/Eucla"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Australia/Hobart"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Australia/Lindeman"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Australia/Lord_Howe"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Australia/Melbourne"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Australia/Perth"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Australia/Sydney"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Pacific/Auckland"]]) {
        NSLog(@"[DEBUG] timezone is pacific or australia, using australia server array...");
        serversArr = [self australiaHostnames];
    } else if ([[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Asia/Seoul"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Asia/Tokyo"]]) {
        NSLog(@"[DEBUG] timezone is asia, using japan server array...");
        serversArr = [self japanHostnames];
    } else if ([[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Asia/Singapore"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Asia/Kuala_Lumpur"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Africa/Johannesburg"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Africa/Djibouti"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Africa/Dar_es_Salaam"]]) {
        NSLog(@"[DEBUG] timezone is near singapore, using singapore server array...");
        serversArr = [self singaporeHostnames];
    } else if ([[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Asia/Hong_Kong"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Asia/Ho_Chi_Minh"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Asia/Bangkok"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Asia/Jakarta"]]) {
        NSLog(@"[DEBUG] timezone is near hongkong, using hongkong server array...");
        serversArr = [self hongkongHostnames];
    } else if ([[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Asia/Shanghai"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Asia/Macau"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Asia/Taipei"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Asia/Manila"]]) {
        NSLog(@"[DEBUG] timezone is near taiwan, using taiwan server array...");
        serversArr = [self taiwanHostnames];
    } else if ([[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Asia/Calcutta"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Asia/Baku"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Asia/Dhaka"]]) {
        NSLog(@"[DEBUG] timezone is proximate to india, using india server array...");
        serversArr = [self indiaHostnames];
    } else if ([[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Europe/London"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Asia/Qatar"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Asia/Riyadh"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Asia/Dubai"]]) {
        NSLog(@"[DEBUG] timezone is near UK, using UK server array...");
        serversArr = [self ukHostnames];
    } else if ([[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Amsterdam"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Athens"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Belgrade"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Bucharest"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Budapest"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Copenhagen"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Dublin"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Kiev"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Madrid"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Moscow"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Zagreb"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Rome"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Asia/Jerusalem"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Atlantic/Reykjavik"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Stockholm"]]) {
        NSLog(@"[DEBUG] timezone is near Amsterdam, using Amsterdam server array...");
        serversArr = [self amsterdamHostnames];
    } else if ([[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Helsinki"]]) {
        NSLog(@"[DEBUG] timezone is near Finland, using Finland server array...");
        serversArr = [self finlandHostnames];
    } else if([[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Berlin"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Brussels"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Istanbul"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Luxembourg"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Malta"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Oslo"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Prague"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Vienna"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Warsaw"]]) {
        NSLog(@"[DEBUG] timezone is near Germany, using Germany server array...");
        serversArr = [self germanyHostnames];
    } else if ([[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Monaco"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Lisbon"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Andorra"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Africa/Accra"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Africa/Algiers"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Africa/Cairo"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Africa/Tripoli"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Paris"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Zurich"]]) {
        NSLog(@"[DEBUG] timezone is near France, using France server array...");
        serversArr = [self franceHostnames];
    } else if ([[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/St_Kitts"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/St_Lucia"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/St_Thomas"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/St_Vincent"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Sao_Paulo"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Santo_Domingo"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Santiago"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Santa_Isabel"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Rio_Branco"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Resolute"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Port_of_Spain"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Port-au-Prince"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Panama"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Guyana"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Havana"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Guadeloupe"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Guatemala"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Guayaquil"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/El_Salvador"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Caracas"]] ||
              [[NSTimeZone localTimeZone] isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"America/Argentina/Buenos_Aires"]]) {
        NSLog(@"[DEBUG] timezone is near South America, using South America server array...");
        serversArr = [self southAmericaHostnames];
    } else {
        NSLog(@"[DEBUG] time zone not in current list, using all-high-capacity array...");
        serversArr = [self allHighCapacityUsaHostnames];
    }
    
    // TO DO - Use cellular MCC to get more specific result (not needed until we have more nodes to warrant this)
    
    NSUInteger arrCnt = [serversArr count];
    NSUInteger r = arc4random_uniform((unsigned int)arrCnt); // arc4random_uniform() will return an int between 0 and arrCnt-1
    NSLog(@"[DEBUG][selectRandomProximateHostname] possInt=%d r=%u", (unsigned int)arrCnt, (unsigned int)r);
    
    NSString *hostnameToUse = [serversArr objectAtIndex:r];
    NSLog(@"[DEBUG][selectRandomProximateHostname] random selected hostname = %@", hostnameToUse);
    
    return hostnameToUse;
}

+ (GRDVPNHelperStatusCode)doMigrationIfNeededForHostname:(NSString *)host {
#ifdef DEBUG
    if([host hasPrefix:@"sandbox-"] || [host hasPrefix:@"debug-"]) {
        NSLog(@"[DEBUG][doMigrationIfNeeded] this is a DEBUG build, allowing non-operational sandbox and debug hosts.");
        return GRDVPNHelperSuccess;
    }
#endif
    
#ifndef DEBUG
    NSArray *allOperationalHosts = [[GRDServerManager sharedManager] allHostnames];
    if(allOperationalHosts != nil && [[GRDServerManager sharedManager] didPopulateLists] == YES) {
        NSLog(@"[DEBUG][doMigrationIfNeeded] operational hosts cached, checking if ours is on list...");
        BOOL needsMigration = YES;
        
        for(NSString *operationalHostname in allOperationalHosts) {
            if([host isEqualToString:operationalHostname]) {
                NSLog(@"[DEBUG][doMigrationIfNeeded] input host (%@) matches an operational hostname", host);
                needsMigration = NO;
            }
        }
        
        if(needsMigration == YES) {
            NSLog(@"[DEBUG][doMigrationIfNeeded] input host (%@) does not match operational server, migrating...", host);
            [self migrateUserToRandomNewNodeWithCompletion:^(BOOL status){}];
            return GRDVPNHelperDoesNeedMigration;
        }
    }
#endif
    
    if([host isEqualToString:@"gateway.verify.ly"] ||
       [host isEqualToString:kOldServerOneHostname] ||
       [host isEqualToString:kOldServerTwoHostname] ||
       [host isEqualToString:kOldServerThreeHostname] ||
       [host isEqualToString:kOldServerFourHostname] ||
       [host isEqualToString:@"beta-migrated-us-west-1.sudosecuritygroup.com"] ||
       [host isEqualToString:@"beta-migrated-us-west-2.sudosecuritygroup.com"] ||
       [host isEqualToString:@"beta-migrated-us-east-1.sudosecuritygroup.com"] ||
       [host isEqualToString:@"beta-migrated-us-west-2.sudosecuritygroup.com"]) {
        NSLog(@"[DEBUG][doMigrationIfNeeded] user is still on old server! migrating...");
        [self migrateUserToRandomNewNodeWithCompletion:^(BOOL status){}];
        return GRDVPNHelperDoesNeedMigration;
    } else {
        return GRDVPNHelperSuccess;
    }
}

+ (void)reconnectVPN {
    if([GRDVPNHelper loadApiHostname] == nil ||
       [GRDVPNHelper loadEapPasswordRef] == nil) return; // FIXME - as per issue #215
    
    [[NEVPNManager sharedManager] loadFromPreferencesWithCompletionHandler:^(NSError *loadError) {
        NSLog(@"[DEBUG][reconnectVPN] loaded preferences");
        [[NEVPNManager sharedManager] setOnDemandEnabled:YES];
        [[NEVPNManager sharedManager] saveToPreferencesWithCompletionHandler:^(NSError *saveErr) {
            NSError *vpnErr;
            if(saveErr) {
                NSLog(@"[DEBUG][reconnectVPN] error saving update = %@", saveErr);
                [[[NEVPNManager sharedManager] connection] startVPNTunnelAndReturnError:&vpnErr];
            } else {
                [[[NEVPNManager sharedManager] connection] startVPNTunnelAndReturnError:&vpnErr];
            }
        }];
    }];
}

+ (void)disconnectVPN {
    [[NEVPNManager sharedManager] setOnDemandEnabled:NO];
    [[NEVPNManager sharedManager] saveToPreferencesWithCompletionHandler:^(NSError *saveErr) {
        if(saveErr) {
            NSLog(@"[DEBUG][disconnectVPN] error saving update for firewall config = %@", saveErr);
            [[[NEVPNManager sharedManager] connection] stopVPNTunnel];
        } else {
            [[[NEVPNManager sharedManager] connection] stopVPNTunnel];
        }
    }];
}

+ (void)migrateUserToNewNode:(NSString *)newNodeName
                 withApiHost:(NSString *)apiHostname
                  completion:(nullable void (^)(bool success))completion {
    [self saveGatewayHostname:newNodeName];
    [self saveApiHostname:apiHostname];
    [[GRDGatewayAPI sharedAPI] setApiHostname:apiHostname];
    
    [self createFreshUserWithCompletion:^(GRDVPNHelperStatusCode statusCode, NSString *errString) {
        if(statusCode == GRDVPNHelperDoesNeedMigration) {
            NSLog(@"[DEBUG][migrateUserToNewNode] migration failed! setting kAppNeedsSelfRepair");
            // TO DO - better way to do this, with similar retry count
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kAppNeedsSelfRepair];
            [[NSUserDefaults standardUserDefaults] synchronize];
            completion(NO);
            return;
        }
        
        NSLog(@"[DEBUG][migrateUserToNewNode] create fresh user done");
        if(errString != nil) {
            NSLog(@"[DEBUG][migrateUserToNewNode] create fresh user returned errString == %@", errString);
            // do something else with err msg???
            completion(NO);
        } else {
            NSLog(@"[DEBUG][migrateUserToNewNode] create fresh user returned no error");
            [[NSNotificationCenter defaultCenter] postNotificationName:kGRDServerUpdatedNotification object:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:kGRDLocationUpdatedNotification object:nil];
            completion(YES);
        }
    }];
}

// used for app re-install, or migration from legacy infrastructure
+ (void)migrateUserToRandomNewNodeWithCompletion:(nullable void (^)(bool success))completion {
    NSString *hostname = [self selectRandomProximateHostname];
    NSLog(@"[DEBUG][migrateUserToRandomNewNode] hostname = %@", hostname);
    
#if TARGET_OS_SIMULATOR
    NSLog(@"[DEBUG][migrateUserToRandomNewNode] running in Simulator, so just sending the NSNotifications instead");
    [[NSNotificationCenter defaultCenter] postNotificationName:kGRDServerUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:kGRDLocationUpdatedNotification object:nil];
#else
    [self migrateUserToNewNode:hostname withApiHost:hostname completion:^(BOOL status) {
        completion(status);
    }];
#endif
}

+ (void)createFreshUserWithCompletion:(void (^)(GRDVPNHelperStatusCode statusCode, NSString *errString))completion {
    // remove previous authentication details
    [GRDKeychain removeGuardianKeychainItems];
    
    // check server status before proceeding
    [[GRDGatewayAPI sharedAPI] getServerStatusWithCompletion:^(GRDGatewayAPIResponse *apiResponse) {
        
        // proceed only if server is operational
        if(apiResponse.responseStatus == GRDGatewayAPIServerOK) {
            NSLog(@"[DEBUG][createFreshUserWithCompletion] GRDGatewayAPIServerOK");
            
            NSString *username = [[NSUUID UUID] UUIDString];
            NSString *password = (__bridge NSString *)SecCreateSharedWebCredentialPassword();
            NSLog(@"[DEBUG][createFreshUserWithCompletion] generated API user = %@, pw = %@", username, password);
            [[GRDGatewayAPI sharedAPI] registerWithUsername:username password:password onCompletion:^(GRDGatewayAPIResponse *apiResponse) {
                // TO DO
                // check apiResponse value 'error' for network issues
                // check apiResponse value 'urlResponse' HTTP return code indicating other issue, if not in 'statusCode' already
                
                if(apiResponse.responseStatus == GRDGatewayAPIDeviceCheckError) {
                    NSLog(@"[DEBUG][createFreshUserWithCompletion] DeviceCheck error! This should not occur under normal circumstances...");
                    completion(GRDVPNHelperAPI_ProvisioningError, @"DeviceCheck error! Please select 'Get Technical Support' in the Settings tab for assistance.");
                    return;
                } else if(apiResponse.responseStatus == GRDGatewayAPIServerInternalError) {
                    NSLog(@"[DEBUG][createFreshUserWithCompletion] server error! Might be down or otherwise inoperable");
                    completion(GRDVPNHelperDoesNeedMigration, nil);
                    return;
                } else if(apiResponse.responseStatus == GRDGatewayAPIReceiptDataMissing) {
                    NSLog(@"[DEBUG][createFreshUserWithCompletion] server error! receipt data was not sent");
                    completion(GRDVPNHelperAPI_ProvisioningError, @"App receipt data missing or invalid");
                    return;
				} else if (apiResponse.responseStatus == GRDGatewayAPIReceiptExpired) {
					NSLog(@"[DEBUG][createFreshUserWithCompletion] Receipt expired");
					completion(GRDVPNHelperAPI_ProvisioningError, @"Subscription expired or receipt corrupted.");
                    return;
                } else if (apiResponse.responseStatus == GRDGatewayAPIStatusAPIRequestsDenied) {
                    NSLog(@"[DEBUG][createFreshUserWithCompletion] API basename is nil");
                    completion(GRDVPNHelperAPI_ProvisioningError, nil); //TODO: not sure if this should have a different error string
                    return;
                }
                
                NSLog(@"[DEBUG][createFreshUserWithCompletion][register] got back registration response json dict = %@", apiResponse.jsonData);
                NSString *authToken = apiResponse.apiAuthToken;
                
                // TODO: validate authentication token
                // right now, we just assume it is valid, as it always is (for now...)
                // edge case would be registration that returns auth token that server did not properly save
                
                if(authToken != nil) {
                    NSLog(@"[DEBUG][createFreshUserWithCompletion][register] authToken == %@", authToken);
                    OSStatus tokenStatus = [GRDVPNHelper saveApiAuthToken:authToken];
                    if ( tokenStatus != errSecSuccess){
                       NSLog(@"[DEBUG][createFreshUserWithCompletion] error storing authToken (%@): %ld", authToken, (long)tokenStatus);
                    }
                    [[GRDGatewayAPI sharedAPI] setAuthToken:authToken];
                    [[GRDGatewayAPI sharedAPI] provisionDeviceWithCompletion:^(GRDGatewayAPIResponse *apiResponse) {
                        if(apiResponse.responseStatus == GRDGatewayAPIDeviceCheckError) {
                            NSLog(@"[DEBUG][createFreshUserWithCompletion] DeviceCheck error! This should not occur under normal circumstances...");
                            completion(GRDVPNHelperAPI_ProvisioningError, @"DeviceCheck error! Please select 'Get Technical Support' in the Settings tab.");
                            return;
                        } else if(apiResponse.responseStatus == GRDGatewayAPIServerInternalError) {
                            NSLog(@"[DEBUG][createFreshUserWithCompletion] server error! Might be down or otherwise inoperable");
                            completion(GRDVPNHelperDoesNeedMigration, nil);
                            return;
                        }  else if(apiResponse.responseStatus == GRDGatewayAPITokenMissing) {
                            NSLog(@"[DEBUG][createFreshUserWithCompletion] server error! GRDGatewayAPITokenMissing");
                            completion(GRDVPNHelperDoesNeedMigration, nil);
                            return;
                        }
                        
                        if(apiResponse.apiDeviceIdentifier != nil) {
                            NSLog(@"[DEBUG][createFreshUserWithCompletion][provision] got apiDeviceIdentifier = %@", apiResponse.apiDeviceIdentifier);
                            
                            OSStatus deviceIdStatus = [GRDVPNHelper saveApiDeviceIdentifier:apiResponse.apiDeviceIdentifier];
                            if ( deviceIdStatus != errSecSuccess){
                                NSLog(@"[DEBUG][createFreshUserWithCompletion][provision] error storing apiDeviceIdentifier (%@): %ld", apiResponse.apiDeviceIdentifier, (long)deviceIdStatus);
                            }
                            
                            [[GRDGatewayAPI sharedAPI] setDeviceIdentifier:apiResponse.apiDeviceIdentifier];
                        } else {
                            NSLog(@"[DEBUG][createFreshUserWithCompletion][provision] apiDeviceIdentifier is nil !!!");
                        }
                        
                        if(apiResponse.eapUsername != nil) {
                            NSLog(@"[DEBUG][createFreshUserWithCompletion][provision] got eapUsername = %@", apiResponse.eapUsername);
                            
                            OSStatus usernameStatus = [GRDVPNHelper saveEapUsername:apiResponse.eapUsername];
                            if ( usernameStatus != errSecSuccess){
                                NSLog(@"[DEBUG][createFreshUserWithCompletion][provision] error storing eapUsername (%@): %ld", apiResponse.eapUsername, (long)usernameStatus);
                            }
                            
                        } else {
                            NSLog(@"[DEBUG][createFreshUserWithCompletion][provision] eapUsername is nil !!!");
                        }
                        
                        if(apiResponse.eapPassword != nil) {
                            NSLog(@"[DEBUG][createFreshUserWithCompletion][provision] got apiResponse.eapPassword = %@", apiResponse.eapPassword);
                            //[GRDKeychain storePassword:apiResponse.eapPassword forAccount:kKeychainStr_EapPassword];
                            OSStatus pwStatus = [GRDVPNHelper saveEapPassword:apiResponse.eapPassword];
                            if ( pwStatus != errSecSuccess){
                                NSLog(@"[DEBUG][createFreshUserWithCompletion][provision] error storing eapPassword (%@): %ld", apiResponse.eapPassword, (long)pwStatus);
                            }
                        } else {
                            NSLog(@"[DEBUG][createFreshUserWithCompletion][provision] eapPassword is nil !!!");
                        }
                        
                        // TO DO - some sort of check to ensure provisioning went ok
                        // task is currently blocked by no stable API for error codes / reporting. work in progress.
                        NSLog(@"[DEBUG][createFreshUserWithCompletion][provision] provision done");
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"GRDCurrentUserChanged" object:nil];
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"GRDShouldConfigureVPN" object:nil];
                        NSLog(@"[DEBUG][createFreshUserWithCompletion][provision] posted GRDCurrentUserChanged and GRDShouldConfigureVPN");
                        
                        completion(GRDVPNHelperSuccess, nil);
                    }];
                } else {
                    NSLog(@"[DEBUG][createFreshUserWithCompletion] something went wrong, authToken is nil, bailing...");
                    completion(GRDVPNHelperAPI_ProvisioningError, @"No authentication token returned by server");
                }
            }];
        } else if(apiResponse.responseStatus == GRDGatewayAPIUnknownError) {
            NSLog(@"[DEBUG][createFreshUserWithCompletion] GRDGatewayAPIUnknownError");
            NSLog(@"[DEBUG][createFreshUserWithCompletion] unknown error! checking standard network issues");
            if(apiResponse.error.code == NSURLErrorTimedOut) {
                NSLog(@"[DEBUG][createFreshUserWithCompletion] timeout error! attempting to migrate user...");
                completion(GRDVPNHelperDoesNeedMigration, nil);
            } else if(apiResponse.error.code == NSURLErrorServerCertificateHasBadDate) {
                NSLog(@"[DEBUG][createFreshUserWithCompletion] certificate expiration error! attempting to migrate user...");
                completion(GRDVPNHelperDoesNeedMigration, nil);
            } else if(apiResponse.error.code == NSURLErrorCannotFindHost) {
                NSLog(@"[DEBUG][createFreshUserWithCompletion] could not find host! attempting to migrate user...");
                completion(GRDVPNHelperDoesNeedMigration, nil);
            } else if(apiResponse.error.code == NSURLErrorNotConnectedToInternet) {
                NSLog(@"[DEBUG][createFreshUserWithCompletion] not connected to internet! ");
                completion(GRDVPNHelperAPI_ProvisioningError, @"Could not connect to the internet. Please check your connection and try again.");
            } else if(apiResponse.error.code == NSURLErrorNetworkConnectionLost) {
                NSLog(@"[DEBUG][createFreshUserWithCompletion] connection lost! ");
                completion(GRDVPNHelperAPI_ProvisioningError, @"Network connection lost. Please check your connection try again.");
            } else if(apiResponse.error.code == NSURLErrorInternationalRoamingOff) {
                NSLog(@"[DEBUG][createFreshUserWithCompletion] international roaming is off! ");
                completion(GRDVPNHelperAPI_ProvisioningError, @"Connection could not be completed because Roaming is turned off. Please go to Settings > Cellular to fix this, and try again.");
            } else if(apiResponse.error.code == NSURLErrorDataNotAllowed) {
                NSLog(@"[DEBUG][createFreshUserWithCompletion] data not allowed! ");
                completion(GRDVPNHelperAPI_ProvisioningError, @"Your cellular network did not allow this connection to complete.");
            } else if(apiResponse.error.code == NSURLErrorCallIsActive) {
                NSLog(@"[DEBUG][createFreshUserWithCompletion] phone call active! ");
                completion(GRDVPNHelperAPI_ProvisioningError, @"The connection could not be completed due to an active phone call. Please try again after completing your phone call.");
            } else if (apiResponse.responseStatus == GRDGatewayAPIStatusAPIRequestsDenied){
                NSLog(@"[DEBUG][basename is nil] returning provision error with nil string for pop up...");
                completion(GRDVPNHelperAPI_ProvisioningError, nil);
            } else {
                NSLog(@"[DEBUG][createFreshUserWithCompletion] unknown error! returning provision error with nil string for pop up...");
                completion(GRDVPNHelperAPI_ProvisioningError, nil);
            }
            return;
        } else if(apiResponse.responseStatus == GRDGatewayAPIServerInternalError) {
            NSLog(@"[DEBUG][createFreshUserWithCompletion] GRDGatewayAPIServerInternalError");
            completion(GRDVPNHelperDoesNeedMigration, nil);
            return;
        }
    }];
}

+ (nullable NSString *)serverLocationForHostname:(NSString *)hostname {
    if([hostname hasPrefix:@"sanjose-"]) {
        return @"San Jose, CA, USA";
    } else if([hostname hasPrefix:@"sanfrancisco-"]) {
        return @"San Francisco, CA, USA";
    } else if([hostname hasPrefix:@"newjersey-"]) {
        return @"Parsippany, NJ, USA";
    } else if([hostname hasPrefix:@"newyork-"]) {
        return @"New York, NY, USA";
    } else if([hostname hasPrefix:@"boston-"]) {
        return @"Boston, MA, USA";
    } else if([hostname hasPrefix:@"chicago-"]) {
        return @"Chicago, IL, USA";
    } else if([hostname hasPrefix:@"virginia-"]) {
        return @"Ashburn, VA, USA";
    } else if([hostname hasPrefix:@"losangeles-"]) {
        return @"Los Angeles, CA, USA";
    } else if([hostname hasPrefix:@"atlanta-"]) {
        return @"Atlanta, GA, USA";
    } else if([hostname hasPrefix:@"dallas-"]) {
        return @"Dallas, TX, USA";
    } else if([hostname hasPrefix:@"seattle-"]) {
        return @"Seattle, WA, USA";
    } else if([hostname hasPrefix:@"latam-cw-"]) {
        return @"Curaçao";
    } else if([hostname hasPrefix:@"amsterdam-"]) {
        return @"Amsterdam, Netherlands";
    } else if([hostname hasPrefix:@"frankfurt-"]) {
        return @"Frankfurt, Germany";
    } else if([hostname hasPrefix:@"france-"]) {
        return @"France";
    } else if([hostname hasPrefix:@"london-"]) {
        return @"London, UK";
    } else if([hostname hasPrefix:@"helsinki-"]) {
        return @"Helsinki, Finland";
    } else if([hostname hasPrefix:@"swiss-"]) {
        return @"Switzerland";
    } else if([hostname hasPrefix:@"stockholm-"]) {
        return @"Stockholm, Sweden";
    } else if([hostname hasPrefix:@"sydney-"]) {
        return @"Sydney, Australia";
    } else if([hostname hasPrefix:@"singapore-"]) {
        return @"Singapore";
    } else if([hostname hasPrefix:@"tokyo-"]) {
        return @"Tokyo, Japan";
    } else if([hostname hasPrefix:@"taipei-"]) {
        return @"Taipei, Taiwan";
    } else if([hostname hasPrefix:@"bangalore-"]) {
        return @"Bangalore, India";
    } else if([hostname hasPrefix:@"hongkong-"]) {
        return @"Hong Kong";
    } else if([hostname hasPrefix:@"dubai-"]) {
        return @"Dubai, UAE";
    } else if([hostname hasPrefix:@"jeddah-"]) {
        return @"Jeddah, Saudi Arabia";
    } else if([hostname hasPrefix:@"riyadh-"]) {
        return @"Riyadh, Saudi Arabia";
    } else if([hostname hasPrefix:@"toronto-"]) {
        return @"Toronto, Canada";
    } else if([hostname hasPrefix:@"beauharnois-"]) {
        return @"Beauharnois, QC, Canada";
    } else {
        return nil;
    }
}

@end
