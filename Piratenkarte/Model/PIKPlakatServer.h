//
//  PIKPlakatServer.h
//  Piratenkarte
//
//  Created by Dominik Wagner on 19.05.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import <Foundation/Foundation.h>
@class PIKPlakatServer;

extern NSString * const PIKPlakatServerDidReceiveDataNotification;

#import "MKDMutableLocationItemStorage.h"
#import "PIKPlakat.h"
#import "AFHTTPRequestOperation.h"

@interface PIKPlakatServer : NSObject
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic) BOOL isDefault;
@property (nonatomic) BOOL isDevelopment;
@property (nonatomic, strong) NSString *serverInfoText;
@property (nonatomic, strong) NSString *serverName;
@property (nonatomic, strong) NSString *serverBaseURL;
@property (nonatomic, strong) NSURL *serverAPIURL;
@property (nonatomic, strong) MKDMutableLocationItemStorage *locationItemStorage;

+ (NSArray *)parseFromJSONObject:(NSDictionary *)aJSONObject;
- (NSDictionary *)JSONDescription;
+ (instancetype)serverWithJSONRepresentation:(NSDictionary *)aServerJSONDictionary;

- (void)updateWithServer:(PIKPlakatServer *)aServer;

- (void)requestAllPlakate;
- (void)requestPlakateInCoordinateRegion:(MKCoordinateRegion)aCoordinateRegion;

@end
