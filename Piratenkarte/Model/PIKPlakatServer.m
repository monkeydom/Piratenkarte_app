//
//  PIKPlakatServer.m
//  Piratenkarte
//
//  Created by Dominik Wagner on 19.05.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import "PIKPlakatServer.h"

@implementation PIKPlakatServer

+ (NSArray *)parseFromJSONObject:(NSDictionary *)aJSONObject {
    NSMutableArray *result = [NSMutableArray new];
    NSString *defaultID = aJSONObject[@"Default"];
    NSString *developmentID = aJSONObject[@"Development"];
    for (NSDictionary *serverDictionary in aJSONObject[@"ServerList"]) {
        PIKPlakatServer *server = [PIKPlakatServer serverWithJSONRepresentation:serverDictionary];
        if ([server.identifier isEqualToString:defaultID]) {
            server.isDefault = YES;
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
    return result;
}

- (void)updateWithServer:(PIKPlakatServer *)aServer {
    self.serverName = aServer.serverName;
    self.serverBaseURL = aServer.serverBaseURL;
    self.serverInfoText = aServer.serverInfoText;
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
