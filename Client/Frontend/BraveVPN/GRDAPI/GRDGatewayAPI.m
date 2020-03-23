//
//  GRDGatewayAPI.m
//  Guardian
//
//  Copyright © 2017 Sudo Security Group Inc. All rights reserved.
//

#import "GRDGatewayAPI.h"
#import <NetworkExtension/NetworkExtension.h>
//#import "NSURLSession+Guardian.h"
#import "VPNConstants.h"

@implementation GRDGatewayAPI
@synthesize authToken, deviceIdentifier;
@synthesize apiHostname, healthCheckTimer;

+ (instancetype)sharedAPI {
    static GRDGatewayAPI *sharedAPI = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedAPI = [[self alloc] init];
    });
    return sharedAPI;
}

- (BOOL)isVPNConnected {
    return ([[[NEVPNManager sharedManager] connection] status] == NEVPNStatusConnected);
}

- (void)stopHealthCheckTimer {
    
    if (self.healthCheckTimer != nil){
        [self.healthCheckTimer invalidate];
        self.healthCheckTimer = nil;
    }
}

- (void)startHealthCheckTimer {
    
    [self stopHealthCheckTimer];
    self.healthCheckTimer = [NSTimer scheduledTimerWithTimeInterval:10 repeats:true block:^(NSTimer * _Nonnull timer) {
        [self networkHealthCheck];
    }];

//    self.healthCheckTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(networkHealthCheck) userInfo:nil repeats:YES];
}

- (void)networkHealthCheck {
    
    [self networkProbeWithCompletion:^(BOOL status, NSError *error) {
        
        GRDNetworkHealthType health = GRDNetworkHealthUnknown;
        if ([error code] == NSURLErrorNotConnectedToInternet ||
            [error code] == NSURLErrorTimedOut ||
            [error code] == NSURLErrorInternationalRoamingOff ||
            [error code] == NSURLErrorDataNotAllowed) {
            health = GRDNetworkHealthBad;
        } else {
            health = GRDNetworkHealthGood;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kGuardianNetworkHealthStatusNotification object:[NSNumber numberWithInteger:health]];
        
    }];
    
}

- (void)_loadCredentialsFromKeychain {
    NSLog(@"[DEBUG][loadCredentials] start");
    
    authToken = [GRDKeychain getPasswordStringForAccount:kKeychainStr_AuthToken];
    deviceIdentifier = [GRDKeychain getPasswordStringForAccount:kKeychainStr_DeviceIdentifier];
    
    if(authToken != nil) {
        NSLog(@"[DEBUG][loadCredentials] we have authToken (%@)", authToken);
    } else {
        NSLog(@"[DEBUG][loadCredentials] no authToken !!!");
    }
    
    if(deviceIdentifier != nil) {
        NSLog(@"[DEBUG][loadCredentials] we have deviceIdentifier (%@)", deviceIdentifier);
    } else {
        NSLog(@"[DEBUG][loadCredentials] no deviceIdentifier !!!");
    }
}

- (NSString *)_baseHostname {
    if(apiHostname == nil) {
        NSLog(@"[DEBUG][GRDGatewayAPI][_baseHostname] apiHostname==nil, loading the APIHostname-Override");
        
        // this should be removed some time when we deem that it 100% will not break shit if we do
        // FYI - I am keeping this as the direct user defaults read, because this API object should never interact with VPN helper object
        if([[NSUserDefaults standardUserDefaults] objectForKey:@"APIHostname-Override"]) {
            apiHostname = [[NSUserDefaults standardUserDefaults] objectForKey:@"APIHostname-Override"];
            NSLog(@"[DEBUG][GRDGatewayAPI][_baseHostname] Override for API present, setting base hostname to: %@", apiHostname);
            return apiHostname;
        } else {
            return nil;
        }
    } else {
        return apiHostname;
    }
}

- (BOOL)_canMakeApiRequests {
    if([self _baseHostname] == nil) {
        return NO;
    } else {
        return YES;
    }
}

- (NSMutableURLRequest *)_requestWithEndpoint:(NSString *)apiEndpoint andPostRequestString:(NSString *)postRequestStr {
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@%@", [self _baseHostname], apiEndpoint]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[postRequestStr dataUsingEncoding:NSUTF8StringEncoding]];
    
    return request;
}

- (NSMutableURLRequest *)_requestWithEndpoint:(NSString *)apiEndpoint andPostRequestData:(NSData *)postRequestDat {
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@%@", [self _baseHostname], apiEndpoint]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
	
    // BRAVE TODO: Correct X-Guardian-Build header
//	[request setValue:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] forHTTPHeaderField:@"X-Guardian-Build"];
	//[request setValue:@"58" forHTTPHeaderField:@"X-Guardian-Build"];
    
    [request setValue:@"60" forHTTPHeaderField:@"GRD-Brave-Build"];
    
	NSString *receiptPathString = [[[NSBundle mainBundle] appStoreReceiptURL] path];
	if ([receiptPathString containsString:@"sandboxReceipt"] || [receiptPathString containsString:@"CoreSimulator"]) {
		NSLog(@"Either local device testing, Simulator testing or TestFlight. Setting Sandbox env");
		[request setValue:@"Sandbox" forHTTPHeaderField:@"X-Guardian-Environment"];
	}
	
	[request setHTTPMethod:@"POST"];
    [request setHTTPBody:postRequestDat];
    
    return request;
}

+ (GRDGatewayAPIResponse *)deniedResponse {
    GRDGatewayAPIResponse *response = [[GRDGatewayAPIResponse alloc] init];
    response.responseStatus = GRDGatewayAPIStatusAPIRequestsDenied;
    return response;
}

+ (GRDGatewayAPIResponse *)missingTokenResponse {
    GRDGatewayAPIResponse *response = [[GRDGatewayAPIResponse alloc] init];
    response.responseStatus = GRDGatewayAPITokenMissing;
    return response;
}

//need to handle new API failure completions from places that call this function

- (void)getServerStatusWithCompletion:(void (^)(GRDGatewayAPIResponse *apiResponse))completion {
    NSLog(@"[DEBUG][getServerStatus] get server status start !!!");
    
    if([self _canMakeApiRequests] == NO) {
        NSLog(@"[DEBUG][getServerStatus] cannot make API requests !!! won't continue");
        if (completion){
            completion([GRDGatewayAPI deniedResponse]);
        }
        return;
    }
    
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@%@", [self _baseHostname], kSGAPI_ServerStatus]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request setTimeoutInterval:10.0f];
    [request setHTTPMethod:@"GET"];
    //[request setValue:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] forHTTPHeaderField:@"X-Guardian-Build"];
    
    [request setValue:@"60" forHTTPHeaderField:@"GRD-Brave-Build"];
    
    NSLog(@"[DEBUG][getServerStatus] URL == %@", URL);
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        GRDGatewayAPIResponse *respObj = [[GRDGatewayAPIResponse alloc] init];
        respObj.urlResponse = response;
        
        if (error) {
            NSLog(@"[DEBUG][getServerStatus] request error = %@", error);
            respObj.error = error;
            respObj.responseStatus = GRDGatewayAPIUnknownError;
            completion(respObj);
        } else {
            if([(NSHTTPURLResponse *)response statusCode] == 200) {
                NSLog(@"[DEBUG][getServerStatus] server is OK!");
                respObj.responseStatus = GRDGatewayAPIServerOK;
            } else if([(NSHTTPURLResponse *)response statusCode] == 500) {
                NSLog(@"[DEBUG][getServerStatus] Server error! Need to use different server");
                respObj.responseStatus = GRDGatewayAPIServerInternalError;
            } else if([(NSHTTPURLResponse *)response statusCode] == 404) {
                NSLog(@"[DEBUG][getServerStatus] Endpoint not found on this server!");
                respObj.responseStatus = GRDGatewayAPIEndpointNotFound;
            } else {
                NSLog(@"[DEBUG][getServerStatus] unknown error!");
                respObj.responseStatus = GRDGatewayAPIUnknownError;
            }
            
            if(data != nil) {
                NSLog(@"[DEBUG][getServerStatus] data != nil");
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                respObj.jsonData = json;
                NSLog(@"[DEBUG][getServerStatus] json response data = %@",json);
                
                // TO DO - data possibilities
                // {"available_capacity": "normal"}
                // {"available_capacity": "none"}
            }
            
            completion(respObj);
        }
    }];
    
    [task resume];
}

// input: "username" and "password"
// output: "auth-token"
- (void)registerWithUsername:(NSString *)user password:(NSString *)pass onCompletion:(void (^)(GRDGatewayAPIResponse *apiResponse))completion {
    NSLog(@"[DEBUG] register start !!!");
    
    if([self _canMakeApiRequests] == NO) {
        NSLog(@"[DEBUG][registerWithUsername] cannot make API requests !!! won't continue");
        if (completion){
                completion([GRDGatewayAPI deniedResponse]);
            }
        return;
    }
    
    NSString *receiptDataStr = nil;
    NSData *receiptData = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]];
    if(receiptData != nil) {
        NSLog(@"[DEBUG][register] receiptData is present! getting base64 str to use...");
        receiptDataStr = [receiptData base64EncodedStringWithOptions:0];
        NSLog(@"[DEBUG][register] got receiptDatStr base64");
    } else {
        receiptDataStr = @"";
    }
    
        
    NSDictionary *dict = @{@"username":user, @"password":pass, @"receipt-data":receiptDataStr};
    NSData *postData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
    NSMutableURLRequest *request = [self _requestWithEndpoint:kSGAPI_Register andPostRequestData:postData];
    
    NSString *receiptPathString = [[[NSBundle mainBundle] appStoreReceiptURL] path];
    if([receiptPathString containsString:@"sandboxReceipt"] || [receiptPathString containsString:@"CoreSimulator"]) {
        [request setValue:@"Sandbox" forHTTPHeaderField:@"X-Guardian-IAP-Environment"];
    }
    [request setValue:@"60" forHTTPHeaderField:@"GRD-Brave-Build"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        GRDGatewayAPIResponse *respObj = [[GRDGatewayAPIResponse alloc] init];
        respObj.urlResponse = response;
        
        if (error) {
            NSLog(@"[DEBUG][register] request error = %@", error);
            respObj.error = error;
            respObj.responseStatus = GRDGatewayAPIUnknownError;
            if(completion) completion(respObj);
        } else {
            if(data == nil) {
                NSLog(@"[DEBUG][register] data == nil");
                respObj.responseStatus = GRDGatewayAPINoData;
                if(completion) completion(respObj);
                return;
            }
            
            NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
            if(statusCode == 403) {
                NSLog(@"[DEBUG][register] DeviceCheck validation failed!");
                respObj.responseStatus = GRDGatewayAPIDeviceCheckError;
                completion(respObj);
                return;
            } else if (statusCode == 406) {
                respObj.responseStatus = GRDGatewayAPIReceiptExpired;
                completion(respObj);
                return;
            } else if(statusCode == 500) {
                NSLog(@"[DEBUG][register] Server error! Need to use different server");
                respObj.responseStatus = GRDGatewayAPIServerInternalError;
                completion(respObj); // will cause GRDVPNHelper to return GRDVPNHelperDoesNeedMigration
                return;
            }
            
            // Explicit check for 200 OK
            if (statusCode == 200) {
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                NSLog(@"[DEBUG][register] json response data = %@",json);
                respObj.jsonData = json;
                
                if([json[@"status"] isEqualToString:@"error"]) {
                    if([json[@"error"] isEqualToString:@"missing-param"] ||
                       [json[@"error-type"] isEqualToString:@"receipt-data"]) {
                        respObj.responseStatus = GRDGatewayAPIReceiptDataMissing;
                    }
                } else {
                    // all should be OK
                    respObj.responseStatus = GRDGatewayAPISuccess;
                    respObj.apiAuthToken = json[@"auth-token"];
                }
                
                completion(respObj);
            } else {
                // Who knows what happened
                respObj.responseStatus = GRDGatewayAPIUnknownError;
                completion(respObj);
            }
        }
    }];
    [task resume];
}


// full (prototype) endpoint: "/vpnsrv/api/device/create"
// input: "auth-token" and "push-token" (POST format)
// output: "device-token" and "eap-username" and "eap-password"
- (void)provisionDeviceWithCompletion:(void (^)(GRDGatewayAPIResponse *apiResponse))completion {
    NSLog(@"[DEBUG] device provision start !!!");
    
    if([self _canMakeApiRequests] == NO) {
        NSLog(@"[DEBUG][provisionDeviceWithCompletion] cannot make API requests !!! won't continue");
        if (completion){
            completion([GRDGatewayAPI deniedResponse]);
        }
        return;
    }
    
    if(authToken == nil ) {
        NSLog(@"[DEBUG][provision] no auth token! cannot provision device.");
        if (completion){
            completion([GRDGatewayAPI missingTokenResponse]);
        }
        return;
    }
    
    NSString *receiptDataStr = nil;
    NSData *receiptData = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]];
    if(receiptData != nil) {
        NSLog(@"[DEBUG][provision] receiptData != nil");
        receiptDataStr = [receiptData base64EncodedStringWithOptions:0];
        //NSLog(@"[DEBUG][provision] receiptDatStr base64 == %@", receiptDataStr);
    } else {
        receiptDataStr = @"";
    }
     
    NSString *endpointStr = [NSString stringWithFormat:@"%@%@", kSGAPI_DeviceBase, kSGAPI_Device_Create];
    NSDictionary *dict = @{@"receipt-data":receiptDataStr};
    NSData *postData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
    NSMutableURLRequest *request = [self _requestWithEndpoint:endpointStr andPostRequestData:postData];
    [request setValue:self.authToken forHTTPHeaderField:@"X-Guardian-Auth"];
    [request setValue:@"60" forHTTPHeaderField:@"GRD-Brave-Build"];
    
    NSString *receiptPathString = [[[NSBundle mainBundle] appStoreReceiptURL] path];
    if([receiptPathString containsString:@"sandboxReceipt"] || [receiptPathString containsString:@"CoreSimulator"]) {
        [request setValue:@"Sandbox" forHTTPHeaderField:@"X-Guardian-IAP-Environment"];
    }
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        GRDGatewayAPIResponse *respObj = [[GRDGatewayAPIResponse alloc] init];
        respObj.urlResponse = response;
        
        if (error) {
            NSLog(@"[DEBUG][provision] request error = %@", error);
            respObj.error = error;
            respObj.responseStatus = GRDGatewayAPIUnknownError;
            if(completion) completion(respObj);
        } else {
            if(data == nil) {
                NSLog(@"[DEBUG][provision] data == nil");
                respObj.responseStatus = GRDGatewayAPINoData;
                if(completion) completion(respObj);
                return;
            }
            
            if([(NSHTTPURLResponse *)response statusCode] == 403) {
                NSLog(@"[DEBUG][provision] DeviceCheck validation failed!");
                respObj.responseStatus = GRDGatewayAPIDeviceCheckError;
                completion(respObj);
                return;
            } else if([(NSHTTPURLResponse *)response statusCode] == 500) {
                NSLog(@"[DEBUG][provision] Server error! Need to use different server");
                respObj.responseStatus = GRDGatewayAPIServerInternalError;
                completion(respObj); // will cause GRDVPNHelper to return GRDVPNHelperDoesNeedMigration
                return;
            }
            
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSLog(@"[DEBUG][provision] json response data = %@",json);
            
            respObj.jsonData = json;
            respObj.error = error;
            
            // FIXME: Not all errors are catched here,
            if(json[@"error"] != nil) {
                if([json[@"error"] isEqualToString:@"auth-error"] && [json[@"error-type"] isEqualToString:@"invalid-password"]) {
                    respObj.responseStatus = GRDGatewayAPIAuthenticationError;
                } else {
                    respObj.responseStatus = GRDGatewayAPIUnknownError;
                }
                respObj.errorString = json[@"error-type"];
            } else {
                respObj.responseStatus = GRDGatewayAPISuccess;
                respObj.apiDeviceIdentifier = json[@"device-token"];
                respObj.eapUsername = json[@"eap-username"];
                respObj.eapPassword = json[@"eap-password"];
            }
            
            completion(respObj);
        }
    }];
    
    [task resume];
}

// full (prototype) endpoint: "/vpnsrv/api/validate-receipt"
// input: "auth-token" and "receipt" (POST format)
// output: ???
- (void)validateReceiptUsingSandbox:(BOOL)sb withCompletion:(void (^)(GRDGatewayAPIResponse *apiResponse))completion {
    NSLog(@"[DEBUG] validate receipt start !!!");
    NSError *err = nil;
    NSData *receiptData = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]];
    if(receiptData == nil) {
        NSLog(@"[DEBUG][validate receipt] receiptData == nil");
        if (completion){
            GRDGatewayAPIResponse *response = [GRDGatewayAPIResponse new];
            response.responseStatus = GRDGatewayAPIReceiptJsonDataEmpty;
            completion(response);
        }
        return;
    }
    
    NSData *postDat = [NSJSONSerialization dataWithJSONObject:@{@"receipt-data":[receiptData base64EncodedStringWithOptions:0]} options:0 error:&err];
    
    NSLog(@"[DEBUG][validate receipt] err = %@", err);
    NSLog(@"[DEBUG][validate receipt] receipt URL = %@", [[NSBundle mainBundle] appStoreReceiptURL]);
    
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@%@",
        @"housekeeping.sudosecuritygroup.com", kSGAPI_ValidateReceipt_APIv1]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];;
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:postDat];
    
    if(sb == YES) {
        [request setValue:@"Sandbox" forHTTPHeaderField:@"X-Guardian-IAP-Environment"];
    }
    
    [request setValue:@"60" forHTTPHeaderField:@"GRD-Brave-Build"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        GRDGatewayAPIResponse *respObj = [[GRDGatewayAPIResponse alloc] init];
        if (error) {
            NSLog(@"[DEBUG][validate receipt] request error = %@", error);
            respObj.error = error;
            respObj.urlResponse = response;
            respObj.responseStatus = GRDGatewayAPIUnknownError;
            if(completion) completion(respObj);
            return;
        } else {
            if (data == nil) {
                NSLog(@"[DEBUG][validate receipt] data == nil");
                respObj.urlResponse = response;
                respObj.responseStatus = GRDGatewayAPINoData;
                if (completion) completion(respObj);
                return;
            }
            
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            
            respObj.jsonData = json;
            respObj.error = error;
            respObj.urlResponse = response;
            
            // Creating a NSMutableArray to hold all the items from
            // latest_receipt_info & in_app
            NSMutableArray *latestReceiptArr = [[NSMutableArray alloc] init];
            
            if (json[@"error"] != nil) {
                NSLog(@"[DEBUG][validate receipt] error != nil!");
                if ([json[@"error"] isEqualToString:@"auth-error"] && [json[@"error-type"] isEqualToString:@"invalid-password"]) {
                    respObj.responseStatus = GRDGatewayAPIAuthenticationError;
                } else {
                    respObj.responseStatus = GRDGatewayAPIUnknownError;
                }
                respObj.errorString = json[@"error-type"];
            } else if (json[@"status"] != nil) {
                NSLog(@"[DEBUG][validate receipt] status != nil!");
                
                // Checking for IAP Sandbox env
                if ([json[@"status"] integerValue] == 21007) {
                    respObj.responseStatus = GRDGatewayAPIReceiptNeedsSandboxEnv;
                    NSLog(@"[DEBUG][validate receipt] ERROR: status==21007, needs Sandbox env!");
                } else {
                    // Adding the items from in_app to latestReceiptArr
                    NSDictionary *receiptDict = json[@"receipt"];
                    if (receiptDict != nil && receiptDict[@"in_app"] != nil) {
                        NSLog(@"[DEBUG][validate receipt] in_app != nil!");
                        [latestReceiptArr addObjectsFromArray:receiptDict[@"in_app"]];
                        respObj.responseStatus = GRDGatewayAPISuccess;
                    }
                    
                    if (json[@"latest_receipt_info"] != nil) {
                        NSLog(@"[DEBUG][validate receipt] latest_receipt_info != nil!");
                        [latestReceiptArr addObjectsFromArray:json[@"latest_receipt_info"]];
                        respObj.responseStatus = GRDGatewayAPISuccess;
                    }
                    
                    // If the arrays exist, but no data is actually present (yes, this happened before)
                    // simply return with no data
                    if ([latestReceiptArr count] < 1) {
                        respObj.responseStatus = GRDGatewayAPINoReceiptData;
                    }
                }
            } else {
                respObj.responseStatus = GRDGatewayAPIUnknownError;
                NSLog(@"[DEBUG][validate receipt] ERROR: unknown error, no 'status' or 'error' in response JSON!!");
                if (completion) completion(respObj);
                return;
            }
            
            if ([latestReceiptArr count] > 0) {
                NSLog(@"[DEBUG][validate receipt] [latestReceiptArr count] == %lu", [latestReceiptArr count]);
                
                // Time intervals in seconds for reference
                // 12*60*60 =  43200 - 12 hours
                // 24*60*60 =  86400 - 24 hours
                // 36*60*60 = 129600 - 36 hours
                
                // Getting a UNIX Timestamp of right now
                NSInteger today = (int)[[NSDate date] timeIntervalSince1970];
                NSLog(@"[DEBUG][validate receipt] [NSDate date] == %li", today);
                
                // Looping through all the items in latestReceiptArr
                for (NSDictionary *receiptDict in latestReceiptArr) {
                    NSLog(@"[DEBUG][validate receipt] receiptDict = %@", receiptDict);
                    
                    // Getting the name of the current subscription or pass (eg. grd_monthly, grd_day_pass_alt)
                    NSString *productID = receiptDict[@"product_id"];
                    
                    // Checking if the current item is a day pass (not a subscription but consumable item,
                    // which means the dictionary will have no expires_date)
                    if ([productID isEqualToString:@"grd_day_pass"] || [productID isEqualToString:@"grd_day_pass_alt"]) {
                        NSLog(@"[DEBUG][validate receipt] receipt for Day Pass found");
                        
                        // Getting the purchase_date_ms, which is in milliseconds, not seconds so we
                        // have to shave the milliseconds off
                        NSString *purchaseDateRawStr    = receiptDict[@"purchase_date_ms"];
                        NSInteger purchaseDate          = [purchaseDateRawStr integerValue] / 1000;
                        NSLog(@"[DEBUG][validate receipt] purchaseDate + 24 hours == %li", purchaseDate);
                        
                        // Adding 36 hours to the purchase_date to allow for a day worth of usage + a 12 hour grace period
                        // during which the service should still accept the receipt
                        NSInteger purchaseDatePlus24h = purchaseDate + 86400;
                        NSLog(@"[DEBUG][validate receipt] purchaseDate + 24 hours == %li", purchaseDatePlus24h);
                        
                        // If purchase_date + grace period is bigger than the timestamp of right now the pass is still valid
                        if (purchaseDatePlus24h >= today) {
                            NSLog(@"[DEBUG][validate receipt] purchase date + 24 hours has NOT passed for receiptDict==%@", receiptDict);
                            NSLog(@"[DEBUG][validate receipt] purchaseDate : %@", receiptDict[@"purchase_date"]);
                            respObj.receiptHasActiveSubscription    = YES;
                            respObj.receiptExpirationDate           = [[NSDate alloc] initWithTimeIntervalSince1970:purchaseDatePlus24h];
                            respObj.receiptProductID                = productID;
                        } else {
                            NSLog(@"[DEBUG][validate receipt] purchase date + 24 hours has passed!");
                        }
                    
                    // The current pass is a auto-renewing subscription and will have a expiration date set
                    } else {
                        // Getting the expiration date in ms and shaving off the milliseconds
                        NSString *expireDateRawStr = receiptDict[@"expires_date_ms"];
                        NSInteger expiresDate = [expireDateRawStr integerValue] / 1000;
                        NSLog(@"[DEBUG][validate receipt] expire date == %li", expiresDate);
                        
                        // Adding 24 hour grace period
                        NSInteger expiresDatePlusGracePeriod = expiresDate + 86400;
                        NSLog(@"[DEBUG][validate receipt] expire date + 24 hours == %li", expiresDatePlusGracePeriod);
                        
                        // If expiration date + grace period of auto renewing subscription
                        // is bigger than right now the subscription is still valid
                        if (expiresDate >= today) {
                            NSLog(@"[DEBUG][validate receipt] expiration date has NOT passed for receiptDict==%@", receiptDict);
                            NSLog(@"[DEBUG][validate receipt] expirationDate: %@", receiptDict[@"expires_date"]);
                            respObj.receiptHasActiveSubscription    = YES;
                            respObj.receiptExpirationDate           = [[NSDate alloc] initWithTimeIntervalSince1970:expiresDate];
                            respObj.receiptProductID                = productID;
                        } else {
                            NSLog(@"[DEBUG][validate receipt] expiration date has passed!");
                        }
                    }
                    
                    // Checking for trial period
                    if ([receiptDict[@"is_trial_period"] isEqualToString:@"true"]) {
                        NSLog(@"[DEBUG][validate receipt] is_trial_period == true");
                        respObj.receiptIndicatesFreeTrialUsed = YES;
                    } else if ([receiptDict[@"is_trial_period"] isEqualToString:@"false"]) {
                        NSLog(@"[DEBUG][validate receipt] is_trial_period == false");
                        respObj.receiptIndicatesFreeTrialUsed = NO;
                    } else {
                        NSLog(@"[DEBUG][validate receipt] is_trial_period returned unkonwn value");
                    }
                }
            }
            if (completion) completion(respObj);
        }
    }];
    
    [task resume];
}

//unused

// full (prototype) endpoint: "/vpnsrv/api/device/<device_token>/set-push-token"
// input: "auth-token" and "push-token" (POST format)
- (void)bindPushToken:(NSString *)pushTok notificationMode:(NSString *)notifMode {
    if([self _canMakeApiRequests] == NO) {
        NSLog(@"[DEBUG][bindPushToken] cannot make API requests !!! won't continue");
        return;
    }
    
    if(authToken == nil ) {
        NSLog(@"[DEBUG][bindAPNs] no auth token! cannot bind push token.");
        return;
    } else if(deviceIdentifier == nil) {
        NSLog(@"[DEBUG][bindAPNs] no device id! cannot bind push token.");
        return;
    }
    
    NSLog(@"[DEBUG][bindAPNs] bind push start! (a=%@,d=%@,p=%@)", authToken, deviceIdentifier, pushTok);
    
    NSString *notifModeValue = nil;
    if([notifMode isEqualToString:@"instant"]) {
        NSLog(@"[DEBUG][bindAPNs] notification mode is instant");
        notifModeValue = @"1";
    } else if([notifMode isEqualToString:@"daily"]) {
        NSLog(@"[DEBUG][bindAPNs] notification mode is daily");
        notifModeValue = @"2";
    } else {
        NSLog(@"[DEBUG][bindAPNs] notification mode not recognized (%@), defaulting to daily...", notifMode);
        notifModeValue = @"2";
    }
    
    NSString *endpointStr = [NSString stringWithFormat:@"%@/%@%@", kSGAPI_DeviceBase, deviceIdentifier, kSGAPI_Device_SetPushToken];
    NSString *postDataStr = [NSString stringWithFormat:@"auth-token=%@&push-token=%@&notification-mode=%@", authToken, pushTok, notifModeValue];
    NSURLRequest *request = [self _requestWithEndpoint:endpointStr andPostRequestString:postDataStr];
    
    NSLog(@"[DEBUG][bindAPNs] postDataStr = %@", postDataStr);
    
    // TO DO
    // replace response data with GRDGatewayAPIResponse object
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"[DEBUG][bindAPNs] request error = %@", error);
            //completion(nil);
        } else {
            if(data == nil) {
                NSLog(@"[DEBUG][bindAPNs] data == nil");
                return; // FIXME
            }
            
            NSDictionary *json  = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSLog(@"[DEBUG][bindAPNs] json response data = %@",json);
            //completion(json);
        }
    }];
    
    [task resume];
}

- (NSArray *)_fakeAlertsArray {
    NSString *curDateStr = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
    NSMutableArray *fakeAlerts = [NSMutableArray array];
   
    NSInteger i = 0;
    for (i = 0; i < 20000; i++){
        [fakeAlerts addObject:@{@"action":@"drop",
                                @"category":@"privacy-tracker-app",
                                @"host":@"analytics.localytics.com",
                                @"message":@"Prevented 'Localytics' from obtaining unknown data from device. Prevented 'Localytics' from obtaining unknown data from device Prevented 'Localytics' from obtaining unknown data from device Prevented 'Localytics' from obtaining unknown",
                                @"timestamp":curDateStr,
                                @"title":@"Blocked Data Tracker",
                                @"uuid":[[NSUUID UUID] UUIDString] }];
        
        [fakeAlerts addObject:@{@"action":@"drop",
                                @"category":@"privacy-tracker-app-location",
                                @"host":@"api.beaconsinspace.com",
                                @"message":@"Prevented 'Beacons In Space' from obtaining unknown data from device",
                                @"timestamp":curDateStr,
                                @"title":@"Blocked Location Tracker",
                                @"uuid":[[NSUUID UUID] UUIDString] }];
        
        [fakeAlerts addObject:@{@"action":@"drop",
                                @"category":@"security-phishing",
                                @"host":@"api.phishy-mcphishface-thisisanexampleofalonghostname.com",
                                @"message":@"Prevented 'Phishy McPhishface' from obtaining unknown data from device",
                                @"timestamp":curDateStr,
                                @"title":@"Blocked Phishing Attempt",
                                @"uuid":[[NSUUID UUID] UUIDString] }];
        
        [fakeAlerts addObject:@{@"action":@"drop",
                                @"category":@"encryption-allows-invalid-https",
                                @"host":@"facebook.com",
                                @"message":@"Prevented 'Facebook', you're welcome",
                                @"timestamp":curDateStr,
                                @"title":@"Blocked MITM",
                                @"uuid":[[NSUUID UUID] UUIDString] }];
        
        [fakeAlerts addObject:@{@"action":@"drop",
                                @"category":@"ads/aggressive",
                                @"host":@"google.com",
                                @"message":@"Prevented Google from forcing shit you don't need down your throat",
                                @"timestamp":curDateStr,
                                @"title":@"Blocked Ad Tracker",
                                @"uuid":[[NSUUID UUID] UUIDString] }];
    }
    
    
    
    return [NSArray arrayWithArray:fakeAlerts];
}

/**
 full (prototype) endpoint: "/vpnsrv/api/device/<device_token>/alerts" (kSGAPI_Device_GetAlerts)
 return data fields: action, category, host, message, title, timestamp, uuid
 
 @param completion De-Serialized JSON from the server containing all alerts
 */
- (void)getEvents:(void (^)(NSDictionary *response, BOOL success, NSError *error))completion {
    if (self.dummyDataForDebugging == NO) {
        if ([self _canMakeApiRequests] == NO) {
            NSLog(@"[DEBUG][getEvents] cannot make API requests !!! won't continue");
            completion(nil, NO, [NSError errorWithDomain:NSURLErrorDomain code:2020 userInfo:@{@"desc": @"cant make API requests"}]);
            return;
        }
        
        if (authToken == nil) {
            NSLog(@"[DEBUG][getEvents] no auth token! cannot get events.");
            NSError *responseError = [NSError errorWithDomain:@"GRDAPIErrorDomain" code:9
                                                     userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"no auth token", nil)}];
            completion(nil, NO, responseError);
        } else if (deviceIdentifier == nil) {
            NSLog(@"[DEBUG][getEvents] no device id! cannot get events.");
            completion(nil, NO, [NSError errorWithDomain:NSURLErrorDomain code:2021 userInfo:@{@"desc": @"[DEBUG][getEvents] no device id! cannot get events."}]);
            return;
        } else {
            NSString *endpointStr = [NSString stringWithFormat:@"%@/%@%@", kSGAPI_DeviceBase, deviceIdentifier, kSGAPI_Device_GetAlerts];
            NSString *postDataStr = [NSString stringWithFormat:@"auth-token=%@&max=500", authToken];
            NSURLRequest *request = [self _requestWithEndpoint:endpointStr andPostRequestString:postDataStr];
            
            // TO DO
            // replace response data with GRDGatewayAPIResponse object
            NSURLSession *session = [NSURLSession sharedSession];
            NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                if (error) {
                    NSLog(@"[DEBUG][getEvents] request error = %@", error);
                    completion(nil, NO, error);
                } else {
                    if (data == nil) {
                        NSLog(@"[DEBUG][getEvents] data == nil");
                        completion(nil, NO, nil);
                        return; // FIXME
                    }
                    
                    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                    
                    /* FIXME - this is here as a hack, should be elsewhere */
                    if (json[@"error-type"] != nil) {
                        if ([json[@"error-type"] isEqualToString:@"auth_failure"] || [json[@"error-type"] isEqualToString:@"user-or-device-auth-failure"]) {
                            NSLog(@"[DEBUG][getEvents] error, auth failure, needs self repair...");
                            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kAppNeedsSelfRepair];
                        }
                    }
					
                    /* FIXME - this is here as a hack, should be elsewhere */
                    if ([[json objectForKey:@"alerts"] count] == 0) {
                        NSError *processedJSONError = [NSError errorWithDomain:@"GRDAPIErrorDomain" code:10
                                                                      userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"JSON response from Server is empty", nil)}];
                        completion(nil, NO, processedJSONError);
                    } else {
                        completion(json, YES, nil);
                    }
                }
            }];
            
            [task resume];
        }
    } else {
        // Returning dummy data so that we can debug easily in the simulator
        completion([NSDictionary dictionaryWithObject:[self _fakeAlertsArray] forKey:@"alerts"], YES, nil);
    }
}

- (void)networkProbeWithCompletion:(void (^)(BOOL status, NSError *error))completion {
    //https://guardianapp.com/network-probe.txt
    //easier than the usual setup, and doing it in the bg so it will be fine.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSURL *URL = [NSURL URLWithString:@"https://guardianapp.com/network-probe.txt"];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:5.0];
        
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
			if (error) {
				NSLog(@"[DEBUG][networkProbeWithCompletion] error!! %@", error);
                completion(false,error);
			} else {
				//TODO: do we actually care about the contents of the file?
				completion(true, error);
			}
		}];
        [task resume];
    });
}

// BRAVE TODO: No blacklist files

/*
// TO DO
// replace response data with GRDGatewayAPIResponse object

//currently unused in deployment - will get refactored as part of the blacklist fork in the very near future

- (void)addBlacklistItem:(GRDBlacklistItem *)item onCompletion:(void (^)(NSDictionary *))completion {
    if([self _canMakeApiRequests] == NO) {
        NSLog(@"[DEBUG][addBlacklistItem] cannot make API requests !!! won't continue");
        completion(nil);
        return;
    }
    
    if(authToken == nil ) {
        NSLog(@"[DEBUG][registerBlacklistItem] no auth token! cannot add new rule.");
        completion(nil);
        return;
    } else if(deviceIdentifier == nil) {
        NSLog(@"[DEBUG][registerBlacklistItem] no device id! cannot add new rule.");
        completion(nil);
        return;
    } else if (item == nil) {
        NSLog(@"[DEBUG][registerBlacklistItem] no blacklist item! cannot add new rule.");
        completion(nil);
        return;
    }
    
    NSLog(@"[DEBUG][registerBlacklistItem] add blacklist start! (%@, %@, %@)", item.label, NSStringFromGRDBlacklistType(item.type), item.value);
    
    NSString *endpointStr = [NSString stringWithFormat:@"%@%@%@", kSGAPI_DeviceBase, deviceIdentifier,
                             item.type == GRDBlacklistTypeIP ? kGSAPI_Rule_AddIP : kGSAPI_Rule_AddDNS];
    NSString *postDataStr = [NSString stringWithFormat:@"auth-token=%@&value=%@&policy=block", authToken, item.value];
    NSURLRequest *request = [self _requestWithEndpoint:endpointStr andPostRequestString:postDataStr];
    
    NSLog(@"[DEBUG][registerBlacklistItem] postDataStr = %@", postDataStr);
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                if (error) {
                                                    NSLog(@"[DEBUG][registerBlacklistItem] request error = %@", error);
                                                    completion(nil);
                                                } else {
                                                    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                                                    NSLog(@"[DEBUG][registerBlacklistItem] json response data = %@",json);
                                                    completion(json);
                                                }
                                            }];
    
    [task resume];
}

//currently unused in deployment - will get refactored as part of the blacklist fork in the very near future

// TO DO
// replace response data with GRDGatewayAPIResponse object
- (void)deleteBlacklistItem:(GRDBlacklistItem *)item onCompletion:(void (^)(NSDictionary *))completion {
    if([self _canMakeApiRequests] == NO) {
        NSLog(@"[DEBUG][deleteBlacklistItem] cannot make API requests !!! won't continue");
         completion(nil);
        return;
    }
    
    if(authToken == nil ) {
        NSLog(@"[DEBUG][deleteBlacklistItem] no auth token! cannot get events.");
        completion(nil);
        return;
    } else if(deviceIdentifier == nil) {
        NSLog(@"[DEBUG][deleteBlacklistItem] no device id! cannot get events.");
        completion(nil);
        return;
    } else if (item == nil) {
        NSLog(@"[DEBUG][deleteBlacklistItem] no blacklist item! cannot add new rule.");
        completion(nil);
        return;
    }
    
    NSLog(@"[DEBUG][deleteBlacklistItem] removeBlacklistItem blacklist start! (%@)", item.identifier);
    
    NSString *endpointStr = [NSString stringWithFormat:@"%@%@%@", kSGAPI_DeviceBase, deviceIdentifier, kGSAPI_Rule_Delete];
    NSString *postDataStr = [NSString stringWithFormat:@"auth-token=%@&rule-uuid=%@", authToken, item.identifier];
    NSURLRequest *request = [self _requestWithEndpoint:endpointStr andPostRequestString:postDataStr];
    
    NSLog(@"[DEBUG][deleteBlacklistItem] postDataStr = %@", postDataStr);
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                if (error) {
                                                    NSLog(@"[DEBUG][deleteBlacklistItem] request error = %@", error);
                                                    completion(nil);
                                                } else {
                                                    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                                                    NSLog(@"[DEBUG][deleteBlacklistItem] json response data = %@",json);
                                                    completion(json);
                                                }
                                            }];
    
    [task resume];
}

// TODO
// add other bits such as host/IP blocking, locale, etc
// need to wait for new infrastructure deployment so other endpoints can actually be tested though
*/
@end
