//
//  GRDVPNHelper.h
//  Guardian
//
//  Created by will on 4/28/19.
//  Copyright © 2019 Sudo Security Group Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NetworkExtension/NetworkExtension.h>
#import "GRDGatewayAPIResponse.h"
#import "GRDGatewayAPI.h"
#import "GRDServerManager.h"
#import "GRDKeychain.h"

/* OLD - Digital Ocean servers, users are mainly migrated, will check and remove by shutdown on 1 July 2019 */
#define kOldServerOneHostname     @"us-east-1.sudosecuritygroup.com"
#define kOldServerTwoHostname     @"us-east-2.sudosecuritygroup.com"
#define kOldServerThreeHostname   @"us-west-1.sudosecuritygroup.com"
#define kOldServerFourHostname    @"us-west-2.sudosecuritygroup.com"

/* OLD - Google Cloud servers, users will be migrated off them ASAP */
#define kServerBetaIpsecOne       @"beta-ipsec-us-nova-1.sudosecuritygroup.com"
#define kServerBetaIpsecTwo       @"beta-ipsec-us-nova-2.sudosecuritygroup.com"
#define kServerBetaIpsecThree     @"beta-ipsec-us-nova-3.sudosecuritygroup.com"
#define kServerBetaIpsecFour      @"beta-ipsec-us-losangeles-1.sudosecuritygroup.com"
#define kServerBetaIpsecFive      @"beta-ipsec-us-losangeles-2.sudosecuritygroup.com"
#define kServerBetaIpsecSix       @"beta-ipsec-us-losangeles-3.sudosecuritygroup.com"
#define kServerBetaIpsecSeven     @"beta-ipsec-us-central-1.sudosecuritygroup.com"
#define kServerBetaIpsecEight     @"beta-ipsec-us-central-2.sudosecuritygroup.com"
#define kServerBetaIpsecNine      @"beta-ipsec-us-central-3.sudosecuritygroup.com"
#define kServerBetaIpsecTen       @"beta-ipsec-us-central-4.sudosecuritygroup.com"
#define kServerBetaIpsecEleven    @"beta-ipsec-us-sc-1.sudosecuritygroup.com"
#define kServerBetaIpsecTwelve    @"beta-ipsec-us-sc-2.sudosecuritygroup.com"
#define kServerBetaIpsecThirteen  @"beta-ipsec-us-sc-3.sudosecuritygroup.com"
#define kServerBetaIpsecFourteen  @"beta-ipsec-us-sc-4.sudosecuritygroup.com"
#define kServerBetaIpsecCentral5  @"beta-ipsec-us-central-5.sudosecuritygroup.com"
#define kServerBetaIpsecCentral6  @"beta-ipsec-us-central-6.sudosecuritygroup.com"
#define kServerBetaIpsecCentral7  @"beta-ipsec-us-central-7.sudosecuritygroup.com"
#define kServerBetaIpsecCentral8  @"beta-ipsec-us-central-8.sudosecuritygroup.com"
#define kServerBetaIpsecCentral9  @"beta-ipsec-us-central-9.sudosecuritygroup.com"
#define kServerBetaIpsecCentral10 @"beta-ipsec-us-central-10.sudosecuritygroup.com"

/* Beta - Live - Ready for end user usage */
#define kServerBeta_SJC_1 @"beta-sjc-hs-1.guardianapp.com"
#define kServerBeta_SJC_2 @"beta-sjc-hs-2.guardianapp.com"
#define kServerBeta_SJC_3 @"beta-sjc-hs-3.guardianapp.com"
#define kServerBeta_SJC_4 @"beta-sjc-hs-4.guardianapp.com"
#define kServerBeta_SJC_5 @"beta-sjc-hs-5.guardianapp.com"
#define kServerBeta_SJC_6 @"beta-sjc-hs-6.guardianapp.com"
#define kServerBeta_SJC_7 @"beta-sjc-hs-7.guardianapp.com"
#define kServerBeta_SJC_8 @"beta-sjc-hs-8.guardianapp.com"
#define kServerBeta_SJC_9 @"beta-sjc-hs-9.guardianapp.com"
#define kServerBeta_SJC_10 @"beta-sjc-hs-10.guardianapp.com"
#define kServerBeta_SJC_11 @"beta-sjc-hs-11.guardianapp.com"
#define kServerBeta_SJC_12 @"beta-sjc-hs-12.guardianapp.com"
#define kServerBeta_EWR_1 @"beta-ewr-hs-1.guardianapp.com"
#define kServerBeta_EWR_2 @"beta-ewr-hs-2.guardianapp.com"
#define kServerBeta_EWR_3 @"beta-ewr-hs-3.guardianapp.com"
#define kServerBeta_EWR_4 @"beta-ewr-hs-4.guardianapp.com"
#define kServerBeta_EWR_5 @"beta-ewr-hs-5.guardianapp.com"
#define kServerBeta_EWR_6 @"beta-ewr-hs-6.guardianapp.com"
#define kServerBeta_EWR_7 @"beta-ewr-hs-7.guardianapp.com"
#define kServerBeta_EWR_8 @"beta-ewr-hs-8.guardianapp.com"
#define kServerBeta_EWR_9 @"beta-ewr-hs-9.guardianapp.com"
#define kServerBeta_EWR_10 @"beta-ewr-hs-10.guardianapp.com"
#define kServerBeta_EWR_11 @"beta-ewr-hs-11.guardianapp.com"
#define kServerBeta_EWR_12 @"beta-ewr-hs-12.guardianapp.com"
#define kServerBeta_IAD_1 @"beta-iad-10gbps.guardianapp.com"
#define kServerBeta_DFW_1 @"beta-dfw-10gbps.guardianapp.com"
#define kServerBeta_SEA_1 @"beta-sea-10gbps.guardianapp.com"
#define kServerBeta_AMS_1 @"beta-ams-hs-1.guardianapp.com"
#define kServerBeta_AMS_2 @"beta-ams-hs-2.guardianapp.com"
#define kServerBeta_AMS_3 @"beta-ams-hs-3.guardianapp.com"
#define kServerBeta_AMS_4 @"beta-ams-hs-4.guardianapp.com"
#define kServerBeta_AMS_5 @"beta-ams-hs-5.guardianapp.com"
#define kServerBeta_AMS_6 @"beta-ams-hs-6.guardianapp.com"
#define kServerBeta_FRA_1 @"beta-fra-10gbps.guardianapp.com"
#define kServerBeta_FRA_2 @"beta-fra-2-10gbps.guardianapp.com"
#define kServerBeta_FRA_3 @"beta-fra-3-10gbps.guardianapp.com"
#define kServerBeta_FRA_4 @"beta-fra-4-10gbps.guardianapp.com"
#define kServer_Germany_1 @"frankfurt-ipsec-1.guardianapp.com"
#define kServer_Germany_2 @"frankfurt-ipsec-2.guardianapp.com"
#define kServerBeta_SYD_1 @"beta-syd-10gbps.guardianapp.com"
#define kServerBeta_NRT_1 @"beta-nrt-hs-1.guardianapp.com"
#define kServerBeta_NRT_2 @"beta-nrt-hs-2.guardianapp.com"
#define kServer_Japan_3 @"nrt-firewall-3.guardianapp.com"
#define kServerBeta_ATL_1 @"beta-atl-10gbps.guardianapp.com"
#define kServerBeta_HKG_1 @"beta-hkg-10gbps.guardianapp.com"
#define kServerBeta_ORD_1 @"beta-ord-10gbps.guardianapp.com"
#define kServerBeta_YYZ_1 @"beta-yyz-10gbps.guardianapp.com"
#define kServer_Canada_1 @"toronto-ipsec-1.guardianapp.com"
#define kServer_Canada_2 @"toronto-ipsec-2.guardianapp.com"
#define kServer_UK_1 @"london-ipsec-1.guardianapp.com"
#define kServer_UK_2 @"london-ipsec-2.guardianapp.com"
#define kServerBeta_SIN_1 @"beta-sin-10gbps.guardianapp.com"
#define kServer_Singapore_1 @"singapore-ipsec-1.guardianapp.com"
#define kServer_Singapore_2 @"singapore-ipsec-2.guardianapp.com"
#define kServer_France_1 @"france-1-10gbps.guardianapp.com"
#define kServer_India_1 @"bangalore-ipsec-1.guardianapp.com"
#define kServer_India_2 @"bangalore-ipsec-2.guardianapp.com"
#define kServer_India_3 @"bangalore-ipsec-3.guardianapp.com"
#define kServer_India_4 @"bangalore-ipsec-4.guardianapp.com"

NS_ASSUME_NONNULL_BEGIN

@interface GRDVPNHelper : NSObject

typedef NS_ENUM(NSInteger, GRDVPNHelperStatusCode) {
    GRDVPNHelperSuccess,
    GRDVPNHelperDoesNeedMigration,
    GRDVPNHelperNetworkConnectionError, // add other network errors
    GRDVPNHelperCoudNotReachAPIError,
    GRDVPNHelperApp_VpnPrefsLoadError,
    GRDVPNHelperApp_VpnPrefsSaveError,
    GRDVPNHelperAPI_AuthenticationError,
    GRDVPNHelperAPI_ProvisioningError
};

+ (OSStatus)saveEapUsername:(NSString *)usernameStr;
+ (OSStatus)saveEapPassword:(NSString *)passwordStr;
+ (OSStatus)saveApiAuthToken:(NSString *)apiAuthToken;
+ (OSStatus)saveApiDeviceIdentifier:(NSString *)apiDeviceIdentifier;
+ (void)saveAllInOneBoxHostname:(NSString *)host;
+ (void)saveApiHostname:(NSString *)host;
+ (void)saveGatewayHostname:(NSString *)host;

+ (NSString *)loadApiHostname;
+ (NSString *)loadGatewayHostname;
+ (NSString *)loadEapUsername;
+ (NSData *)loadEapPasswordRef;
+ (NSString *)loadApiAuthToken;
+ (NSString *)loadApiDeviceIdentifier;
+ (BOOL)isPayingUser;
+ (void)setIsPayingUser:(BOOL)isPaying;

+ (void)clearVpnConfiguration;

+ (NSString *)defaultBoxHostname;
+ (NSArray *)vpnOnDemandRules;
+ (NSArray *)vpnOnDemandRulesFree;
+ (NSArray *)googleCloudServerHostnames;
+ (NSArray *)usaEastCoastHostnames;
+ (NSArray *)usaMountainHostnames;
+ (NSArray *)usaCentralHostnames;
+ (NSArray *)usaWestCoastHostnames;
+ (NSArray *)indiaHostnames;
+ (NSArray *)allHighCapacityUsaHostnames;
+ (NSArray *)ukHostnames;
+ (NSArray *)polandHostnames;
+ (NSArray *)swedenHostnames;
+ (NSArray *)franceHostnames;
+ (NSArray *)germanyHostnames;
+ (NSArray *)amsterdamHostnames;
+ (NSArray *)australiaHostnames;
+ (NSArray *)japanHostnames;
+ (NSArray *)canadaHostnames;
+ (NSArray *)singaporeHostnames;
+ (NSArray *)hongkongHostnames;

+ (NEVPNProtocolIKEv2 *)prepareIKEv2ParametersForServer:(NSString *)server
                                            eapUsername:(NSString *)user
                                         eapPasswordRef:(NSData *)passRef
                                    withCertificateType:(NEVPNIKEv2CertificateType)certType;

+ (NSString *)selectRandomGoogleCloudHostname;
+ (NSString *)selectRandomProximateHostname;
+ (GRDVPNHelperStatusCode)doMigrationIfNeededForHostname:(NSString *)host;

+ (void)reconnectVPN;
+ (void)disconnectVPN;
+ (void)migrateUserToNewNode:(NSString *)newNodeName withApiHost:(NSString *)apiHostname;
+ (void)migrateUserToRandomNewNodeWithCompletion:(nullable void (^)(bool success))completion;
+ (void)createFreshUserWithCompletion:(void (^)(GRDVPNHelperStatusCode statusCode, NSString *errString))completion;
+ (nullable NSString *)serverLocationForHostname:(NSString *)hostname;

@end

NS_ASSUME_NONNULL_END
