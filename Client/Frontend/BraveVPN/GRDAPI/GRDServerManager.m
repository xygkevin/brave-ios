//
//  GRDServerManager.m
//  Guardian
//
//  Created by will on 6/21/19.
//  Copyright © 2019 Sudo Security Group Inc. All rights reserved.
//

#import "GRDServerManager.h"
#import "VPNConstants.h"

@interface GRDServerManager() {
    NSInteger _retryCount;
    BOOL _retryWaiting; //whether or not a retry is waiting for a healthy connection
    GRDNetworkHealthType _networkHealth;
}
@end

@implementation GRDServerManager
@synthesize didPopulateLists, areServersAtCapacity;
@synthesize allHostnames, allUsaHostnames, allEuropeHostnames, allAsiaHostnames;
@synthesize usaWestCoastHostnames, usaMountainHostnames, usaCentralHostnames, usaEastCoastHostnames;
@synthesize amsterdamHostnames, ukHostnames, polandHostnames, swedenHostnames, finlandHostnames, franceHostnames, germanyHostnames;
@synthesize japanHostnames, indiaHostnames, singaporeHostnames, hongkongHostnames, taiwanHostnames;
@synthesize australiaHostnames, southAmericaHostnames, canadaHostnames;

+ (instancetype)sharedManager {
    static id sharedManager = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (instancetype)init {
    if(self = [super init]) {
        didPopulateLists = NO;
        areServersAtCapacity = NO;
        allHostnames = nil;
        allUsaHostnames = nil;
        allEuropeHostnames = nil;
        allAsiaHostnames = nil;
        usaEastCoastHostnames = nil;
        usaCentralHostnames = nil;
        usaMountainHostnames = nil;
        usaWestCoastHostnames = nil;
        southAmericaHostnames = nil;
        ukHostnames = nil;
        amsterdamHostnames = nil;
        polandHostnames = nil;
        finlandHostnames = nil;
        franceHostnames = nil;
        germanyHostnames = nil;
        japanHostnames = nil;
        indiaHostnames = nil;
        singaporeHostnames = nil;
        hongkongHostnames = nil;
        taiwanHostnames = nil;
        australiaHostnames = nil;
        canadaHostnames = nil;
        _retryCount = 0;
        _retryWaiting = false;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkHealthChanged:) name:kGuardianNetworkHealthStatusNotification object:nil];
    }
    
    return self;
}

- (void)flushCachedServers {
    didPopulateLists = NO;
    areServersAtCapacity = NO;
    allHostnames = nil;
    allUsaHostnames = nil;
    allEuropeHostnames = nil;
    allAsiaHostnames = nil;
    usaEastCoastHostnames = nil;
    usaCentralHostnames = nil;
    usaMountainHostnames = nil;
    usaWestCoastHostnames = nil;
    southAmericaHostnames = nil;
    ukHostnames = nil;
    amsterdamHostnames = nil;
    polandHostnames = nil;
    franceHostnames = nil;
    swedenHostnames = nil;
    finlandHostnames = nil;
    germanyHostnames = nil;
    japanHostnames = nil;
    indiaHostnames = nil;
    singaporeHostnames = nil;
    hongkongHostnames = nil;
    taiwanHostnames = nil;
    australiaHostnames = nil;
    canadaHostnames = nil;
}


- (void)networkHealthChanged:(NSNotification *)n {
    _networkHealth = [n.object integerValue];
    if (_retryWaiting == true && _networkHealth == GRDNetworkHealthGood){
        NSLog(@"[DEBUG] was waiting for a retry");
        _retryWaiting = false;
        [self handleRetry];
    }
    
}

- (void)populateListsWithServerDictionary:(NSDictionary *)jsonResponse {
    NSMutableArray *allHostsArray = [NSMutableArray array];
    
    if (jsonResponse[@"europe"] != nil) {
        NSDictionary *euDict = jsonResponse[@"europe"];
        
        if (euDict[@"united-kingdom"] != nil) {
            NSArray *ukArray = euDict[@"united-kingdom"];
            self->ukHostnames = ukArray;
            [allHostsArray addObjectsFromArray:ukArray];
        }
        
        if (euDict[@"germany"] != nil) {
            NSArray *germanyArray = euDict[@"germany"];
            self->germanyHostnames = germanyArray;
            [allHostsArray addObjectsFromArray:germanyArray];
        }
        
        if (euDict[@"netherlands"] != nil) {
            NSArray *netherlandsArr = euDict[@"netherlands"];
            self->amsterdamHostnames = netherlandsArr;
            [allHostsArray addObjectsFromArray:netherlandsArr];
        }
        
        if (euDict[@"poland"] != nil) {
            NSArray *polandArr = euDict[@"poland"];
            self->polandHostnames = polandArr;
            [allHostsArray addObjectsFromArray:polandArr];
        }
        
        if (euDict[@"sweden"] != nil) {
            NSArray *swedenArr = euDict[@"sweden"];
            self->swedenHostnames = swedenArr;
            [allHostsArray addObjectsFromArray:swedenArr];
        }
        
        if (euDict[@"finland"] != nil) {
            NSArray *finArr = euDict[@"finland"];
            self->finlandHostnames = finArr;
            [allHostsArray addObjectsFromArray:finArr];
        }
        
        if (euDict[@"france"] != nil) {
            NSArray *franceArray = euDict[@"france"];
            self->franceHostnames = franceArray;
            [allHostsArray addObjectsFromArray:franceArray];
        }
        
        if (euDict[@"all_eu"] != nil) {
            NSArray *allEuArray = euDict[@"all_eu"];
            self->allEuropeHostnames = allEuArray;
            [allHostsArray addObjectsFromArray:allEuArray];
        }
    } else {
        NSLog(@"[DEBUG] no 'europe' dict in response.");
    }
    
    if (jsonResponse[@"north_america"] != nil) {
        NSDictionary *americaDict = jsonResponse[@"north_america"];
        
        if (americaDict[@"us-east"] != nil) {
            NSArray *usEastArray = americaDict[@"us-east"];
            self->usaEastCoastHostnames = usEastArray;
            [allHostsArray addObjectsFromArray:usEastArray];
        }
        
        if (americaDict[@"us-mountain"] != nil) {
            NSArray *usMountainArray = americaDict[@"us-mountain"];
            self->usaMountainHostnames = usMountainArray;
            [allHostsArray addObjectsFromArray:usMountainArray];
        }
        
        if (americaDict[@"us-central"] != nil) {
            NSArray *usCentralArray = americaDict[@"us-central"];
            self->usaCentralHostnames = usCentralArray;
            [allHostsArray addObjectsFromArray:usCentralArray];
        }
        
        if (americaDict[@"us-west"] != nil) {
            NSArray *usWestArray = americaDict[@"us-west"];
            self->usaWestCoastHostnames = usWestArray;
            [allHostsArray addObjectsFromArray:usWestArray];
        }
        
        if (americaDict[@"ca-east"] != nil) {
            NSArray *canadaEastArray = americaDict[@"ca-east"];
            self->canadaHostnames = canadaEastArray;
            [allHostsArray addObjectsFromArray:canadaEastArray];
        }
        
        if (americaDict[@"all_usa"] != nil) {
            NSArray *allUsaArray = americaDict[@"all_usa"];
            self->allUsaHostnames = allUsaArray;
            [allHostsArray addObjectsFromArray:allUsaArray];
        }
    } else {
        NSLog(@"[DEBUG] no 'north_america' dict in response.");
    }
    
    if (jsonResponse[@"asia"] != nil) {
        NSDictionary *asiaDict = jsonResponse[@"asia"];
        
        if (asiaDict[@"india"] != nil) {
            NSArray *indiaArray = asiaDict[@"india"];
            self->indiaHostnames = indiaArray;
            [allHostsArray addObjectsFromArray:indiaArray];
        }
        
        if (asiaDict[@"japan"] != nil) {
            NSArray *japanArray = asiaDict[@"japan"];
            self->japanHostnames = japanArray;
            [allHostsArray addObjectsFromArray:japanArray];
        }
        
        if (asiaDict[@"taiwan"] != nil) {
            NSArray *taiwanArray = asiaDict[@"taiwan"];
            self->taiwanHostnames = taiwanArray;
            [allHostsArray addObjectsFromArray:taiwanArray];
        }
        
        if (asiaDict[@"singapore"] != nil) {
            NSArray *singaporeArray = asiaDict[@"singapore"];
            self->singaporeHostnames = singaporeArray;
            [allHostsArray addObjectsFromArray:singaporeArray];
        }
        
        if (asiaDict[@"hong_kong"] != nil) {
            NSArray *hongKongArray = asiaDict[@"hong_kong"];
            self->hongkongHostnames = hongKongArray;
            [allHostsArray addObjectsFromArray:hongKongArray];
        }
        
        if (asiaDict[@"all_asia"] != nil) {
            NSArray *allAsiaArray = asiaDict[@"all_asia"];
            self->allAsiaHostnames = allAsiaArray;
            [allHostsArray addObjectsFromArray:allAsiaArray];
        }
    } else {
        NSLog(@"[DEBUG] no 'asia' dict in response.");
    }
    
    if (jsonResponse[@"australia"] != nil) {
        NSArray *australiaArray = jsonResponse[@"australia"];
        self->australiaHostnames = australiaArray;
        [allHostsArray addObjectsFromArray:australiaArray];
    } else {
        NSLog(@"[DEBUG] no 'australia' dict in response.");
    }
    
    if (jsonResponse[@"south_america"] != nil) {
        NSArray *southAmericaArray = jsonResponse[@"south_america"];
        self->southAmericaHostnames = southAmericaArray;
        [allHostsArray addObjectsFromArray:southAmericaArray];
    } else {
        NSLog(@"[DEBUG] no 'south_america' dict in response.");
    }
    
    if (jsonResponse[@"at-capacity"] != nil) {
        NSString *capacityStatus = jsonResponse[@"at-capacity"];
        if([capacityStatus isEqualToString:@"yes"] || [capacityStatus isEqualToString:@"true"]) {
            areServersAtCapacity = YES;
        }
    }
    
    self->allHostnames = [NSArray arrayWithArray:allHostsArray];
    
    if ([allHostsArray count] > 0) {
        self->didPopulateLists = YES;
    } else {
        self->didPopulateLists = NO;
    }
}

- (void)downloadLatestHosts_v1 {
    NSURL *legacyUrl = [NSURL URLWithString:@"https://guardianapp.com/guardian_servers.json"];
    NSMutableURLRequest *legacyRequest = [NSMutableURLRequest requestWithURL:legacyUrl];
    [legacyRequest setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [legacyRequest setHTTPMethod:@"GET"];
    
    NSURLSession *legacySession = [NSURLSession sharedSession];
    NSURLSessionDataTask *legacyTask = [legacySession dataTaskWithRequest:legacyRequest completionHandler:^(NSData *retData, NSURLResponse *response, NSError *error) {
		if ([(NSHTTPURLResponse *)response statusCode] == 200) {
			if (retData != nil) {
				NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:retData options:0 error:nil];
				[self populateListsWithServerDictionary:jsonDict];
			} else {
				return;
			}
		} else if ([(NSHTTPURLResponse *)response statusCode] == 404) {
			return;
		}
    }];
    
    [legacyTask resume];
}

- (void)handleRetry {
    NSLog(@"[DEBUG] handleRetry");
    if (_networkHealth == GRDNetworkHealthBad){
        NSLog(@"[DEBUG] unhealthy connection! wait until it has improved to retry!");
        _retryWaiting = true;
        return;
    }
    if (_retryCount < 3){
        NSLog(@"[DEBUG] retry count %lu is < 3 trying again in 3 seconds", _retryCount);
        _retryCount++;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSLog(@"[DEBUG][downloadLatestHosts] retry");
            [self downloadLatestHosts];
        });
    } else {
        NSLog(@"[DEBUG] retry count is >= 3 reset to 0 and stop trying for now.");
        _retryCount = 0;
    }
}

- (void)downloadLatestHosts {
    NSURL *URL = nil;
    
    if ([GRDVPNHelper isPayingUser] == YES) {
        URL = [NSURL URLWithString:@"https://guardianapp.com/guardian_servers_v2_paid.json"];
    } else {
        URL = [NSURL URLWithString:@"https://guardianapp.com/guardian_servers_v2.json"];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setHTTPMethod:@"GET"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *retData, NSURLResponse *response, NSError *error) {
        
        if (error){
            NSLog(@"[DEBUG][downloadLatesthosts] error occured: %@", error);
            [self handleRetry];
            return ;
        }
        
		if ([(NSHTTPURLResponse *)response statusCode] == 200) {
			if (retData != nil) {
                self->_retryCount = 0; //reset
				NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:retData options:0 error:nil];
				[self populateListsWithServerDictionary:jsonDict];
			} else {
                NSLog(@"[DEBUG][downloadLatesthosts] is missing data, trying again!");
                [self handleRetry];
				return;
			}
		} else if([(NSHTTPURLResponse *)response statusCode] == 404) {
			[self downloadLatestHosts_v1];
		} else {
            NSLog(@"[DEBUG][downloadLatesthosts] unhandled status code: %lu, try again!",[(NSHTTPURLResponse *)response statusCode] );
            [self handleRetry];
            
        }
    }];
    
    [task resume];
}

- (void)startMonitoringNetworkHealth {
    NSLog(@"[DEBUG][startMonitoringNetworkHealth] nothing here yet");
}

- (void)stopMonitoringNetworkHealth {
    NSLog(@"[DEBUG][stopMonitoringNetworkHealth] nothing here yet");
}

@end
