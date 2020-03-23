//
//  GRDServerManager.h
//  Guardian
//
//  Created by will on 6/21/19.
//  Copyright © 2019 Sudo Security Group Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GRDVPNHelper.h"

NS_ASSUME_NONNULL_BEGIN

@interface GRDServerManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic) BOOL didPopulateLists;
@property (nonatomic, retain) NSArray *allHostnames;
@property (nonatomic, retain) NSArray *allUsaHostnames;
@property (nonatomic, retain) NSArray *allEuropeHostnames;
@property (nonatomic, retain) NSArray *allAsiaHostnames;
@property (nonatomic, retain) NSArray *usaEastCoastHostnames;
@property (nonatomic, retain) NSArray *usaMountainHostnames;
@property (nonatomic, retain) NSArray *usaCentralHostnames;
@property (nonatomic, retain) NSArray *usaWestCoastHostnames;
@property (nonatomic, retain) NSArray *indiaHostnames;
@property (nonatomic, retain) NSArray *ukHostnames;
@property (nonatomic, retain) NSArray *polandHostnames;
@property (nonatomic, retain) NSArray *swedenHostnames;
@property (nonatomic, retain) NSArray *finlandHostnames;
@property (nonatomic, retain) NSArray *franceHostnames;
@property (nonatomic, retain) NSArray *germanyHostnames;
@property (nonatomic, retain) NSArray *amsterdamHostnames;
@property (nonatomic, retain) NSArray *australiaHostnames;
@property (nonatomic, retain) NSArray *southAmericaHostnames;
@property (nonatomic, retain) NSArray *japanHostnames;
@property (nonatomic, retain) NSArray *taiwanHostnames;
@property (nonatomic, retain) NSArray *canadaHostnames;
@property (nonatomic, retain) NSArray *singaporeHostnames;
@property (nonatomic, retain) NSArray *hongkongHostnames;
@property (nonatomic) BOOL areServersAtCapacity;

- (void)downloadLatestHosts;

- (void)startMonitoringNetworkHealth;
- (void)stopMonitoringNetworkHealth;

@end

NS_ASSUME_NONNULL_END
