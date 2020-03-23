//
//  GRDGatewayAPI.h
//  Guardian
//
//  Copyright © 2017 Sudo Security Group Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DeviceCheck/DeviceCheck.h>
#import "GRDKeychain.h"
// BRAVE TODO: No file provided
//#import "GRDBlacklistItem.h"
#import "GRDGatewayAPIResponse.h"

#define kSGAPI_ValidateReceipt_APIv1 @"/api/v1/verify-receipt"

#define kSGAPI_DefaultHostname @"us-west-1.sudosecuritygroup.com"
#define kSGAPI_Register @"/vpnsrv/api/register"
#define kSGAPI_SignIn @"/vpnsrv/api/signin"
#define kSGAPI_SignOut @"/vpnsrv/api/signout"
#define kSGAPI_ValidateReceipt @"/vpnsrv/api/verify-receipt"
#define kSGAPI_ServerStatus @"/vpnsrv/api/server-status"

#define kSGAPI_DeviceBase @"/vpnsrv/api/device"
#define kSGAPI_Device_Create @"/create"
#define kSGAPI_Device_SetPushToken @"/set-push-token"
#define kSGAPI_Device_GetAlerts @"/alerts"
#define kSGAPI_Device_EAP_GetCreds @"/eap-credentials"
#define kSGAPI_Device_EAP_RegenerateCreds @"/regenerate-eap-credentials"
#define kSGAPI_Device_GetPointOfAccess @"/get-point-of-access"
#define kGSAPI_Rule_AddDNS @"/rule/add-dns"
#define kGSAPI_Rule_AddIP @"/rule/add-ip"
#define kGSAPI_Rule_Delete @"/rule/delete"

typedef NS_ENUM(NSInteger, GRDNetworkHealthType) {
    GRDNetworkHealthUnknown = 0,
    GRDNetworkHealthBad,
    GRDNetworkHealthGood
};

@interface GRDGatewayAPI : NSObject

@property BOOL dummyDataForDebugging;

@property (strong, nonatomic) NSString *authToken;
@property (strong, nonatomic) NSString *deviceIdentifier;
@property (strong, nonatomic) NSString *apiHostname;
@property (strong, nonatomic) NSTimer *healthCheckTimer;

+ (instancetype)sharedAPI;
- (BOOL)isVPNConnected;
- (void)networkHealthCheck;
- (void)startHealthCheckTimer;
- (void)stopHealthCheckTimer;
- (void)networkProbeWithCompletion:(void (^)(BOOL status, NSError *error))completion ;
- (void)_loadCredentialsFromKeychain;
- (NSMutableURLRequest *)_requestWithEndpoint:(NSString *)apiEndpoint andPostRequestString:(NSString *)postRequestStr;
- (NSMutableURLRequest *)_requestWithEndpoint:(NSString *)apiEndpoint andPostRequestData:(NSData *)postRequestDat;


- (void)getServerStatusWithCompletion:(void (^)(GRDGatewayAPIResponse *apiResponse))completion;
- (void)registerWithUsername:(NSString *)user password:(NSString *)pass onCompletion:(void (^)(GRDGatewayAPIResponse *apiResponse))completion;
- (void)provisionDeviceWithCompletion:(void (^)(GRDGatewayAPIResponse *apiResponse))completion;
- (void)validateReceiptUsingSandbox:(BOOL)sb withCompletion:(void (^)(GRDGatewayAPIResponse *apiResponse))completion;

- (void)bindPushToken:(NSString *)pushTok notificationMode:(NSString *)notifMode;
- (void)getEvents:(void (^)(NSDictionary *response, BOOL success, NSError *error))completion;

// BRAVE TODO: No file provided
//- (void)addBlacklistItem:(GRDBlacklistItem *)item onCompletion:(void (^)(NSDictionary *completionResponse))completion;
//- (void)deleteBlacklistItem:(GRDBlacklistItem *)item onCompletion:(void (^)(NSDictionary *completionResponse))completion;

@end
