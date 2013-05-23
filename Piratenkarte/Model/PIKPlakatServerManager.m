//
//  PIKPlakatServerManager.m
//  Piratenkarte
//
//  Created by Dominik Wagner on 19.05.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import "PIKPlakatServerManager.h"
#import "PIKPlakatServer.h"
#import "AFNetworking.h"

@interface PIKPlakatServerManager ()
@property (nonatomic, strong) NSMutableArray *serverArray;
@property (nonatomic, strong) NSString *selectedServerIdentifier;
@end

@implementation PIKPlakatServerManager

+ (instancetype)plakatServerManager {
    static PIKPlakatServerManager *s_sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_sharedInstance = [PIKPlakatServerManager new];
    });
    return s_sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        // TODO: save and read from defaults
        _serverArray = [NSMutableArray new];
        
        PIKPlakatServer *myTestServer = [PIKPlakatServer new];
        myTestServer.identifier = @"B5C90E69-AF1C-4BD4-ADA8-DA89BF4C829B"; 
        myTestServer.serverName = @"BTW Testserver";
        myTestServer.serverInfoText = @"Testserver für die Bundestagswahl";
        myTestServer.serverBaseURL = @"http://piraten.boombuler.de/testbtw/";
        [_serverArray addObject:myTestServer];
//        self.selectedServerIdentifier = myTestServer.identifier;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self refreshServerList];
        }];
    }
    return self;
}

- (void)updateListWithServer:(PIKPlakatServer *)aPlakatServer {
    BOOL didFindServer = NO;
    for (PIKPlakatServer *server in self.serverArray) {
        if ([server.identifier isEqual:aPlakatServer.identifier]) {
            didFindServer = YES;
            [server updateWithServer:aPlakatServer];
            break;
        }
    }
    if (!didFindServer) {
        [self.serverArray addObject:aPlakatServer];
    }
    NSLog(@"%s %@",__FUNCTION__,self.serverArray);
}

- (void)updateListWithServerArray:(NSArray *)aServerArray {
    for (PIKPlakatServer *server in aServerArray) {
        [self updateListWithServer:server];
    }
    [self.selectedPlakatServer requestAllPlakate];
}

- (PIKPlakatServer *)serverForIdentifier:(NSString *)anIdentifier {
    for (PIKPlakatServer *server in self.serverArray) {
        if ([server.identifier isEqualToString:anIdentifier]) {
            return server;
        }
    }
    return nil;
}

- (PIKPlakatServer *)selectedPlakatServer {
    PIKPlakatServer *result;
    if (self.selectedServerIdentifier) {
        result = [self serverForIdentifier:self.selectedServerIdentifier];
    }
    if (!result) {
        for (PIKPlakatServer *server in self.serverArray) {
            if (server.isDefault) {
                result = server;
                break;
            }
        }
    }
    if (!result && self.serverArray.count > 0) {
        result = [self.serverArray objectAtIndex:0];
    }
    return result;
}

- (void)refreshServerList {
    NSURL *serverURL = [NSURL URLWithString:@"http://piratemap.github.io/servers.json"];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:serverURL];
    [[AFJSONRequestOperation JSONRequestOperationWithRequest:urlRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
//        NSLog(@"%s success %@",__FUNCTION__,JSON);
        NSArray *serverList = [PIKPlakatServer parseFromJSONObject:JSON];
        [self updateListWithServerArray:serverList];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%s failure %@",__FUNCTION__,JSON);
    }] start];
}

@end
