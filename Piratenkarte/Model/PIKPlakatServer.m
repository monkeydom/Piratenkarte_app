//
//  PIKPlakatServer.m
//  Piratenkarte
//
//  Created by Dominik Wagner on 19.05.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import "PIKPlakatServer.h"
#import "Api.pb.h"
#import <CoreLocation/CoreLocation.h>
#import "PIKPlakatServerManager.h"
#import "SGKeychain.h"

NSString * const PIKPlakatServerDidReceiveDataNotification = @"PIKPlakatServerDidReceiveDataNotification";

typedef void(^PIKNetworkFailBlock)(NSError *error);
typedef void(^PIKNetworkSuccessBlock)();

@interface PIKPlakatServer ()
@property (nonatomic, strong) NSString *password;
@end

@implementation PIKPlakatServer

+ (NSArray *)parseFromJSONObject:(NSDictionary *)aJSONObject {
    NSMutableArray *result = [NSMutableArray new];
    NSString *defaultID = aJSONObject[@"Default"];
    NSArray *developmentIDs = aJSONObject[@"Development"];
    for (NSDictionary *serverDictionary in aJSONObject[@"ServerList"]) {
        PIKPlakatServer *server = [PIKPlakatServer serverWithJSONRepresentation:serverDictionary];
        if ([server.identifier isEqualToString:defaultID]) {
            server.isDefault = YES;
        }
        if ([developmentIDs containsObject:server.identifier]) {
            server.isDevelopment = YES;
        }
        if (server) [result addObject:server];
    }
    return result;
}

+ (instancetype)serverWithJSONRepresentation:(NSDictionary *)aServerJSONDictionary {
    PIKPlakatServer *result = [PIKPlakatServer new];
    result.identifier = aServerJSONDictionary[@"ID"];
    result.serverName = aServerJSONDictionary[@"Name"];
    result.serverBaseURL = aServerJSONDictionary[@"URL"];
    result.serverInfoText = aServerJSONDictionary[@"Info"];
    if (aServerJSONDictionary[@"Development"]) {
        result.isDevelopment = [aServerJSONDictionary[@"Development"] boolValue];
    }
    return result;
}

- (NSDictionary *)JSONDescription {
    NSMutableDictionary *result = [NSMutableDictionary new];
    result[@"ID"] = self.identifier;
    result[@"Name"] = self.serverName;
    result[@"URL"] = self.serverBaseURL;
    if (self.serverInfoText) result[@"Info"] = self.serverInfoText;
    result[@"Development"] = @(self.isDevelopment);
    return result;
}

- (void)updateWithServer:(PIKPlakatServer *)aServer {
    self.serverName = aServer.serverName;
    self.serverBaseURL = aServer.serverBaseURL;
    self.serverInfoText = aServer.serverInfoText;
    self.isDevelopment = aServer.isDevelopment;
}

+ (BoundingBox *)viewBoxForMKCoordinateRegion:(MKCoordinateRegion)aCoordinateRegion {
    if (aCoordinateRegion.span.latitudeDelta <= 0) return nil;
    BoundingBox_Builder *boxBuilder = [BoundingBox builder];
    boxBuilder.west = MKDCoordnateRegionGetMinLongitude(aCoordinateRegion);
    boxBuilder.east = MKDCoordnateRegionGetMaxLongitude(aCoordinateRegion);
    boxBuilder.south = MKDCoordnateRegionGetMinLatitude(aCoordinateRegion);
    boxBuilder.north = MKDCoordnateRegionGetMaxLatitude(aCoordinateRegion);
    BoundingBox *result = boxBuilder.build;
    return result;
}

- (MKDMutableLocationItemStorage *)locationItemStorage {
    if (!_locationItemStorage) {
        _locationItemStorage = [MKDMutableLocationItemStorage new];
    }
    return _locationItemStorage;
}

- (NSString *)usernameUserDefaultKey {
    return [@"PlakatServerUsername-" stringByAppendingString:self.identifier];
}

- (NSString *)username {
    NSString *result = [[NSUserDefaults standardUserDefaults] stringForKey:self.usernameUserDefaultKey];
    if (!result) result = @"";
    return result;
}

- (void)setUsername:(NSString *)aUsername {
    if (aUsername) {
        [[NSUserDefaults standardUserDefaults] setObject:aUsername forKey:self.usernameUserDefaultKey];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:self.usernameUserDefaultKey];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)hasValidPassword {
    BOOL result = (self.internalPasswordFetch != nil);
    return result;
}

- (NSString *)internalPasswordFetch {
    NSError *fetchPasswordError;
    NSString *password = [SGKeychain passwordForUsername:self.username serviceName:self.serverBaseURL error:&fetchPasswordError];
    if (fetchPasswordError) {
        NSLog(@"Error fetching password = %@", fetchPasswordError);
    }
    return password;
}

- (NSString *)password {
    // Fetch the password
    NSString *result = self.internalPasswordFetch;
    if (!result) result = @"";
    return result;
}

- (void)setPassword:(NSString *)aPassword {
    // Store a password
    NSError *storePasswordError = nil;
    BOOL passwordSuccessfullyCreated = [SGKeychain setPassword:aPassword username:self.username serviceName:self.serverBaseURL updateExisting:YES error:&storePasswordError];
    
    if (!passwordSuccessfullyCreated == YES) {
        NSLog(@"Password failed to be created with error: %@", storePasswordError);
    }
}

- (void)removePassword {
    NSError *deletePasswordError = nil;
    BOOL passwordSuccessfullyDeleted = [SGKeychain deletePasswordForUsername:self.username serviceName:self.serverBaseURL error:&deletePasswordError];
    if (!passwordSuccessfullyDeleted) {
        NSLog(@"%s failed to remove password %@",__FUNCTION__,deletePasswordError);
    }
}

- (void)handleViewRequestResponse:(Response *)aResponse requestDate:(NSDate *)requestDate requestCoordinateRegion:(MKCoordinateRegion)aCoordinateRegion {
    MKDMutableLocationItemStorage *itemStorage = self.locationItemStorage;
    BOOL first = YES;
    CLLocationCoordinate2D minCoord, maxCoord;
    
    // TODO: delete the points first before asking for more
    // TODO: change to MKMapRect and MKMapPoint for a more sane api
    
    for (Plakat *plakat in aResponse.plakate) {
        PIKPlakat *myPlakat = [[PIKPlakat alloc] initWithPlakat:plakat serverFetchDate:requestDate];
        [itemStorage addLocationItem:myPlakat];
        if (first) {
            minCoord = myPlakat.coordinate;
            maxCoord = minCoord;
            first = NO;
        } else {
            minCoord.latitude  = MIN(minCoord.latitude ,plakat.lat);
            minCoord.longitude = MIN(minCoord.longitude,plakat.lon);
            maxCoord.latitude  = MAX(maxCoord.latitude ,plakat.lat);
            maxCoord.longitude = MAX(maxCoord.longitude,plakat.lon);
        }
    }
    
    if (!first) {
       NSLog(@"%s did fetch %d plakate in this area: %@ %@",__FUNCTION__,aResponse.plakate.count, [[CLLocation alloc] initWithLatitude:minCoord.latitude longitude:minCoord.longitude], [[CLLocation alloc] initWithLatitude:maxCoord.latitude longitude:maxCoord.longitude]);
        [[NSNotificationCenter defaultCenter] postNotificationName:PIKPlakatServerDidReceiveDataNotification object:self userInfo:@{@"coordinate":[NSValue valueWithMKCoordinate:aCoordinateRegion.center], @"coordinateSpan":[NSValue valueWithMKCoordinateSpan:aCoordinateRegion.span]}];
    }
    
}


- (void)requestAllPlakate {
    [self requestPlakateInCoordinateRegion:MKCoordinateRegionMake(CLLocationCoordinate2DMake(0, 0), MKCoordinateSpanMake(0, 0))];
}

- (Request_Builder *)requestBuilderBase {
    Request_Builder *result = [Request builder];
    result.username = self.username;
    result.password = self.password;
    return result;
}

- (NSMutableURLRequest *)baseURLRequestWithPostData:(NSData *)aPostData {
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:self.serverAPIURL];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setHTTPBody:aPostData];
    return urlRequest;
}

- (void)requestPlakateInCoordinateRegion:(MKCoordinateRegion)aCoordinateRegion {

    [PIKPlakatServerManager increaseNetworkActivityCount];
    
    Request_Builder *request = [self requestBuilderBase];
    [Request builder];
    
    request.viewRequest = [self viewRequestWithCoordinateRegion:aCoordinateRegion];
    Request *req = request.build;
    NSData *postData = req.data;
    
    //    [postData writeToFile:@"/tmp/karten.post" atomically:NO];
    
    NSDate *requestDate = [NSDate new];
    
    NSMutableURLRequest *urlRequest = [self baseURLRequestWithPostData:postData];
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        //        NSLog(@"%s success %@, %@",__FUNCTION__,operation.response, responseObject);
        //        NSLog(@"%s all Headers %@",__FUNCTION__,[operation.response allHeaderFields]);
        @try {
            Response *response = [Response parseFromData:responseObject];
            [self handleViewRequestResponse:response requestDate:requestDate requestCoordinateRegion:aCoordinateRegion];
        }
        @catch (NSException *exception) {
            NSLog(@"%s %@",__FUNCTION__,exception);
            [PIKPlakatServerManager postNetworkErrorNotification];
        }
        @finally {
        }
        //       NSLog(@"%s parsed response = %@",__FUNCTION__,response);
        //       [responseObject writeToFile:@"/tmp/plakate.protobuf" atomically:NO];
        //       [[response.description dataUsingEncoding:NSUTF8StringEncoding] writeToFile:@"/tmp/plakate.txt" atomically:NO];
        
        [PIKPlakatServerManager decreaseNetworkActivityCount];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%s failure: %@\n %@",__FUNCTION__,error, operation.response);
        [PIKPlakatServerManager postNetworkErrorNotification];
        [PIKPlakatServerManager decreaseNetworkActivityCount];
    }];
    [requestOperation start];
}

- (MKCoordinateRegion)narrowRegionAroundCoordinate:(CLLocationCoordinate2D)aCoordinate {
    MKCoordinateRegion result = MKCoordinateRegionMake(aCoordinate, MKCoordinateSpanMake(0.00001, 0.00001));
    return result;
}

- (ViewRequest *)viewRequestWithCoordinateRegion:(MKCoordinateRegion)aCoordinateRegion {
    ViewRequest_Builder *viewRequestBuilder = [ViewRequest builder];
    BoundingBox *viewBox = [self.class viewBoxForMKCoordinateRegion:aCoordinateRegion];
    if (viewBox) viewRequestBuilder.viewBox = viewBox;
    ViewRequest *result = viewRequestBuilder.build;
    return result;
}

- (PIKNetworkFailBlock)failBlockWithCompletion:(PIKNetworkRequestCompletionHandler)aCompletion {
    void(^failure)(NSError *anError) = ^(NSError *anError) {
        [PIKPlakatServerManager postNetworkErrorNotification];
        [PIKPlakatServerManager decreaseNetworkActivityCount];
        if (aCompletion) {
            aCompletion(NO,anError);
        }
    };
    return failure;
}

- (PIKNetworkSuccessBlock)successBlockWithCompletion:(PIKNetworkRequestCompletionHandler)aCompletion {
    void (^success)() = ^{
        [PIKPlakatServerManager decreaseNetworkActivityCount];
        if (aCompletion) {
            aCompletion(YES,nil);
        }
    };
    return success;
}

- (void)removePlakatFromServer:(PIKPlakat *)aPlakat completion:(PIKNetworkRequestCompletionHandler)aCompletion {
    [PIKPlakatServerManager increaseNetworkActivityCount];
    PIKNetworkSuccessBlock success = [self successBlockWithCompletion:aCompletion];
    PIKNetworkFailBlock failure = [self failBlockWithCompletion:aCompletion];
    
    Request_Builder *requestBuilder = [self requestBuilderBase];
    requestBuilder.viewRequest = [self viewRequestWithCoordinateRegion:[self narrowRegionAroundCoordinate:aPlakat.coordinate]];
    
    DeleteRequest_Builder *deleteBuilder = [DeleteRequest builder];
    deleteBuilder.id = aPlakat.plakatID;
    [requestBuilder addDelete:[deleteBuilder build]];
    
    Request *request = [requestBuilder build];
    NSLog(@"%s %@",__FUNCTION__,request);
    NSData *postData = request.data;
    NSMutableURLRequest *urlRequest = [self baseURLRequestWithPostData:postData];
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        @try {
            Response *response = [Response parseFromData:responseObject];
            NSLog(@"%s parsed response = %@",__FUNCTION__,response);
            if (response.deletedCount == 1) {
                NSLog(@"%s successfully deleted",__FUNCTION__);
                [self.locationItemStorage removeLocationItem:aPlakat];
                success();
            } else {
                NSLog(@"%s failed to remove a plakat",__FUNCTION__);
                failure(nil);
            }
        }
        @catch (NSException *exception) {
            NSLog(@"%s %@",__FUNCTION__,exception);
            failure(nil);
        }
        @finally {
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
    [requestOperation start];
}

- (void)validateUsername:(NSString *)aUsername password:(NSString *)aPassword completion:(PIKNetworkRequestCompletionHandler)aCompletion {

    [PIKPlakatServerManager increaseNetworkActivityCount];
    PIKNetworkSuccessBlock success = [self successBlockWithCompletion:aCompletion];
    PIKNetworkFailBlock failure = [self failBlockWithCompletion:aCompletion];
    
    Request_Builder *addRequestBuilder = [Request builder];
    addRequestBuilder.username = aUsername;
    addRequestBuilder.password = aPassword;
    
    if (self.username.length == 0 && !self.hasValidPassword) {
        self.username = aUsername;
    }
    
    AddRequest_Builder *addRequest = [AddRequest builder];

    MKCoordinateRegion helgoregion = [self narrowRegionAroundCoordinate:CLLocationCoordinate2DMake(54.134082, 7.894707)];
    double oneMeter = MKMapPointsPerMeterAtLatitude(helgoregion.center.latitude);
    MKMapPoint point = MKMapPointForCoordinate(helgoregion.center);
    // displace it a little so they stay identifyable
    point.x += oneMeter * (500 - ((int)arc4random_uniform(1000)));
    point.y += oneMeter * (500 - ((int)arc4random_uniform(1000)));
    helgoregion.center = MKCoordinateForMapPoint(point);
    
    
    NSString *comment = [NSString stringWithFormat:@"Credential Check für %@ - %@",aUsername,[[NSUUID new] UUIDString]];
    
    // 54.134082,7.894707 - kurz vor helgoland
    addRequest.lon = helgoregion.center.longitude;
    addRequest.lat = helgoregion.center.latitude;
    addRequest.type = PIKPlakatTypeNicePlace;
    addRequest.comment = comment;

    [addRequestBuilder addAdd:[addRequest build]];

    // dann doch auch noch einen view request bauen - damit wir nicht alle daten bekommen
    addRequestBuilder.viewRequest = [self viewRequestWithCoordinateRegion:helgoregion];

    
    Request *request = [addRequestBuilder build];
//    NSLog(@"%s %@",__FUNCTION__,request);
    NSData *postData = request.data;
    NSMutableURLRequest *urlRequest = [self baseURLRequestWithPostData:postData];
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        @try {
//            [responseObject writeToFile:@"/tmp/mistresult.proto" options:0 error:NULL];
            Response *response = [Response parseFromData:responseObject];
            NSLog(@"%s parsed response = %@",__FUNCTION__,response);
            if (response.addedCount == 1) {
                NSLog(@"%s successfully added",__FUNCTION__);
                // be happy and delete the bugger again
                for (Plakat *plakat in response.plakate) {
                    if ([plakat.comment isEqualToString:comment]) {
                        NSLog(@"%s Found the plakat we just added - jippie! %@",__FUNCTION__,plakat);
                        self.username = aUsername;
                        self.password = aPassword;
                        PIKPlakat *pikPlakat = [[PIKPlakat alloc] initWithPlakat:plakat serverFetchDate:[NSDate new]];
                        [self removePlakatFromServer:pikPlakat completion:^(BOOL success, NSError *error) {
                            NSLog(@"removing the credential plakat again was %@",success ? @"successful" : @"failurous");
                        }];
                    }
                }
                success();
            } else {
                failure(nil);
            }
        }
        @catch (NSException *exception) {
            NSLog(@"%s %@",__FUNCTION__,exception);
            failure(nil);
        }
        @finally {
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
    [requestOperation start];
}



- (void)setServerBaseURL:(NSString *)aServerBaseURLString {
    _serverBaseURL = aServerBaseURLString;
    NSURL *serverAPIURL = [NSURL URLWithString:[aServerBaseURLString stringByAppendingPathComponent:@"api.php"]];
    self.serverAPIURL = serverAPIURL;
}

- (NSString *)description {
    NSArray *elements = @[self.serverName, self.serverBaseURL, self.identifier, self.serverInfoText, self.serverAPIURL];
    NSString *result = [NSString stringWithFormat:@"<%@ %p: %@>",NSStringFromClass(self.class), self, [elements componentsJoinedByString:@" | "]];
    return result;
}

@end
