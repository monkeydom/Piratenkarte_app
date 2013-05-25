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

NSString * const PIKPlakatServerDidReceiveDataNotification = @"PIKPlakatServerDidReceiveDataNotification";


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

- (void)requestPlakateWithBoundingBox:(BoundingBox *)aBoundingBox {
}


- (void)requestAllPlakate {
    [self requestPlakateInCoordinateRegion:MKCoordinateRegionMake(CLLocationCoordinate2DMake(0, 0), MKCoordinateSpanMake(0, 0))];
}

- (Request_Builder *)requestBuilderBase {
    Request_Builder *result = [Request builder];
    result.username = @"";
    result.password = @"";
    return result;
}

- (void)requestPlakateInCoordinateRegion:(MKCoordinateRegion)aCoordinateRegion {
    BoundingBox *aBoundingBox = [self.class viewBoxForMKCoordinateRegion:aCoordinateRegion];
    
    [PIKPlakatServerManager increaseNetworkActivityCount];
    
    Request_Builder *request = [self requestBuilderBase];
    [Request builder];
    
    ViewRequest_Builder *viewRequestBuilder = [ViewRequest builder];
    if (aBoundingBox) viewRequestBuilder.viewBox = aBoundingBox;
    request.viewRequest = [viewRequestBuilder build];
    Request *req = request.build;
    NSData *postData = req.data;
    
    //    [postData writeToFile:@"/tmp/karten.post" atomically:NO];
    
    NSDate *requestDate = [NSDate new];
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:self.serverAPIURL];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setHTTPBody:postData];
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
        }
        @finally {
        }
        //       NSLog(@"%s parsed response = %@",__FUNCTION__,response);
        //       [responseObject writeToFile:@"/tmp/plakate.protobuf" atomically:NO];
        //       [[response.description dataUsingEncoding:NSUTF8StringEncoding] writeToFile:@"/tmp/plakate.txt" atomically:NO];
        
        [PIKPlakatServerManager decreaseNetworkActivityCount];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%s failure: %@\n %@",__FUNCTION__,error, operation.response);
        [PIKPlakatServerManager decreaseNetworkActivityCount];
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
