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

NSString * const PIKPlakatServerManagerSelectedServerDidChangeNotification = @"PIKPlakatServerManagerSelectedServerDidChangeNotification";
NSString * const PIKPlakatServerManagerDidEncounterNetworkError = @"PIKPlakatServerManagerDidEncounterNetworkError";


@interface PIKPlakatServerManager ()
@property (nonatomic, strong) NSMutableArray *serverArray;
@property (nonatomic, strong) NSString *selectedServerIdentifier;
@end

static NSInteger s_activityCount = 0;

@implementation PIKPlakatServerManager

+ (void)increaseNetworkActivityCount {
    s_activityCount++;
    if (s_activityCount == 1) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }
}

+ (void)decreaseNetworkActivityCount {
    s_activityCount--;
    if (s_activityCount <= 0) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }
}

+ (BOOL)hasNetworkActivity {
    return s_activityCount > 0;
}

+ (void)postNetworkErrorNotification {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:PIKPlakatServerManagerDidEncounterNetworkError object:nil] postingStyle:NSPostWhenIdle coalesceMask:NSNotificationCoalescingOnName forModes:@[NSRunLoopCommonModes]];
    }];
}

+ (CLGeocoder *)geoCoder {
    static CLGeocoder *s_geoCoder = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_geoCoder = [CLGeocoder new];
    });
    return s_geoCoder;
}

+ (instancetype)plakatServerManager {
    static PIKPlakatServerManager *s_sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_sharedInstance = [PIKPlakatServerManager new];
    });
    return s_sharedInstance;
}

- (NSArray *)serverList {
    return [self.serverArray copy];
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
        myTestServer.isDevelopment = YES;
        [_serverArray addObject:myTestServer];
//        self.selectedServerIdentifier = myTestServer.identifier;
        [self restoreServerListFromDefaults];
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
//    NSLog(@"%s %@",__FUNCTION__,self.serverArray);
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

- (void)selectPlakatServer:(PIKPlakatServer *)aPlakatServer {
    self.selectedServerIdentifier = aPlakatServer.identifier;
    [self selectedServerDidChange];
    [self.selectedPlakatServer requestAllPlakate];
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

- (void)restoreServerListFromDefaults {
    NSString *selectedIdentifier = [[NSUserDefaults standardUserDefaults] objectForKey:@"SelectedPlakatServerIdentifier"];
    if (selectedIdentifier) {
        self.selectedServerIdentifier = selectedIdentifier;
    }
    
    NSArray *serverList = [[NSUserDefaults standardUserDefaults] objectForKey:@"AvailablePlakatServers"];
    if (serverList) {
        for (NSDictionary *serverJSON in serverList) {
            PIKPlakatServer *plakatServer = [PIKPlakatServer serverWithJSONRepresentation:serverJSON];
            if (plakatServer) {
                [self updateListWithServer:plakatServer];
            }
        }
    }

}

- (void)storeServerListToDefaults {
    NSMutableArray *serverList = [NSMutableArray new];
    for (PIKPlakatServer *server in self.serverArray) {
        [serverList addObject:server.JSONDescription];
    }
    [[NSUserDefaults standardUserDefaults] setObject:serverList forKey:@"AvailablePlakatServers"];
}

- (void)selectedServerDidChange {
    PIKPlakatServer *selectedServer = self.selectedPlakatServer;
    [[NSUserDefaults standardUserDefaults] setObject:selectedServer.identifier forKey:@"SelectedPlakatServerIdentifier"];
    self.selectedServerIdentifier = selectedServer.identifier;
    [self storeServerListToDefaults];
    [[NSNotificationCenter defaultCenter] postNotificationName:PIKPlakatServerManagerSelectedServerDidChangeNotification object:self];
}

- (void)refreshServerList {
    [PIKPlakatServerManager increaseNetworkActivityCount];
    NSURL *serverURL = [NSURL URLWithString:@"http://piratemap.github.io/servers.json"];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:serverURL];
    [[AFJSONRequestOperation JSONRequestOperationWithRequest:urlRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
//        NSLog(@"%s success %@",__FUNCTION__,JSON);
        NSArray *serverList = [PIKPlakatServer parseFromJSONObject:JSON];
        if (serverList.count > 0) {
            [self updateListWithServerArray:serverList];
            [self selectedServerDidChange];
        } else {
            [self.class postNetworkErrorNotification];
        }
        [PIKPlakatServerManager decreaseNetworkActivityCount];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"%s failure %@",__FUNCTION__,JSON);
        [self.class postNetworkErrorNotification];
        [PIKPlakatServerManager decreaseNetworkActivityCount];
    }] start];
}

@end
