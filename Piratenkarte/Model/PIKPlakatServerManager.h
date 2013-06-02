//
//  PIKPlakatServerManager.h
//  Piratenkarte
//
//  Created by Dominik Wagner on 19.05.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import <Foundation/Foundation.h>
@class PIKPlakatServerManager;
#import <CoreLocation/CoreLocation.h>
#import "PIKPlakatServer.h"

extern NSString * const PIKPlakatServerManagerSelectedServerDidChangeNotification;
extern NSString * const PIKPlakatServerManagerDidEncounterNetworkError;

@interface PIKPlakatServerManager : NSObject

+ (instancetype)plakatServerManager;
- (void)refreshServerList;
- (NSArray *)serverList;
+ (CLGeocoder *)geoCoder;

- (void)selectPlakatServer:(PIKPlakatServer *)aPlakatServer;

+ (void)increaseNetworkActivityCount;
+ (void)decreaseNetworkActivityCount;
+ (BOOL)hasNetworkActivity;
+ (void)postNetworkErrorNotification;

@property (nonatomic, readonly) PIKPlakatServer *selectedPlakatServer;


@end
