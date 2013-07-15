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

typedef void(^PIKNetworkRequestCompletionHandler)(BOOL success, NSError *error);

#import "MKDMutableLocationItemStorage.h"
#import "PIKPlakat.h"
#import "AFHTTPRequestOperation.h"

@interface PIKPlakatServer : NSObject
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic) BOOL isDefault;
@property (nonatomic) BOOL isDevelopment;
@property (nonatomic, readonly) BOOL isNoServer;
@property (nonatomic) BOOL isCurrent; // we remember all servers, but only current servers are allowed for users
@property (nonatomic, strong) NSString *serverInfoText;
@property (nonatomic, strong) NSString *serverName;
@property (nonatomic, strong) NSString *serverBaseURL;
@property (nonatomic, strong) NSURL *serverAPIURL;
@property (nonatomic, strong) MKDMutableLocationItemStorage *locationItemStorage;
@property (nonatomic, readonly) BOOL hasValidPassword;
- (void)removePassword;

+ (NSArray *)parseFromJSONObject:(NSDictionary *)aJSONObject;
- (NSDictionary *)JSONDescription;
+ (instancetype)serverWithJSONRepresentation:(NSDictionary *)aServerJSONDictionary;
// updates base values with from other server
- (void)updateWithServer:(PIKPlakatServer *)aServer;

/** dummy object that doesn't do networking or anyhting important */
+ (instancetype)noServer;


@property (nonatomic, readonly, strong) NSString *username;

- (void)validateUsername:(NSString *)aUsername password:(NSString *)aPassword completion:(PIKNetworkRequestCompletionHandler)aCompletion;
- (void)removePlakatFromServer:(PIKPlakat *)aPlakat completion:(PIKNetworkRequestCompletionHandler)aCompletion;
- (void)updateComment:(NSString *)aComment onPlakat:(PIKPlakat *)aPlakat completion:(PIKNetworkRequestCompletionHandler)aCompletion;
- (void)updateType:(NSString *)aType onPlakat:(PIKPlakat *)aPlakat completion:(PIKNetworkRequestCompletionHandler)aCompletion;
- (void)addPlakat:(PIKPlakat *)aPlakat completion:(PIKNetworkRequestCompletionHandler)aCompletion;

- (void)requestAllPlakate;
- (void)requestPlakateInCoordinateRegion:(MKCoordinateRegion)aCoordinateRegion;

@end
