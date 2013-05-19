//
//  PIKViewController.m
//  Piratenkarte
//
//  Created by Dominik Wagner on 12.05.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//


#import "PIKViewController.h"
#import "AFNetworking.h"

@interface PIKViewController ()

@end

@implementation PIKViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.o_mapView.showsUserLocation = YES;
    self.o_mapView.userTrackingMode = MKUserTrackingModeFollow;
}

- (void)requestDataForVisibleViewRect {
    Request_Builder *request = [Request builder];
    request.username = @"";
    request.password = @"";
    
    MKMapRect mapRect = self.o_mapView.visibleMapRect;
    CLLocationCoordinate2D northwest = MKCoordinateForMapPoint(MKMapPointMake(MKMapRectGetMinX(mapRect), MKMapRectGetMinY(mapRect)));
    CLLocationCoordinate2D southeast = MKCoordinateForMapPoint(MKMapPointMake(MKMapRectGetMaxX(mapRect), MKMapRectGetMaxY(mapRect)));
    
    BoundingBox_Builder *viewBoxBuilder = [BoundingBox builder];
    viewBoxBuilder.west =  northwest.longitude -2;
    viewBoxBuilder.south = southeast.latitude  -2;
    viewBoxBuilder.east =  southeast.longitude +2;
    viewBoxBuilder.north = northwest.latitude  +2;
    
    ViewRequest_Builder *viewRequestBuilder = [ViewRequest builder];
    viewRequestBuilder.viewBox  = [viewBoxBuilder build];
    request.viewRequest = [viewRequestBuilder build];
    Request *req = request.build;
    
    NSLog(@"%s %@ | %@ | %@ ",__FUNCTION__,request, req, req.data);
    
    NSData *postData = req.data;
    
    [postData writeToFile:@"/tmp/karten.post" atomically:NO];
    
    Request *parsedReq = [Request parseFromData:postData];
    NSLog(@"%s parsed Request: %@ ",__FUNCTION__, parsedReq);
    
    NSString *testURLString = @"http://piraten.boombuler.de/testbtw/api.php";
//    testURLString = @"http://piraten.boombuler.de/testbtw/api.php";
    NSURL *testURL = [NSURL URLWithString:testURLString];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:testURL];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setHTTPBody:postData];
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%s success %@, %@",__FUNCTION__,operation.response, responseObject);
        NSLog(@"%s all Headers %@",__FUNCTION__,[operation.response allHeaderFields]);
        Response *response = [Response parseFromData:responseObject];
        NSLog(@"%s parsed response = %@",__FUNCTION__,response);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%s failure: %@\n %@",__FUNCTION__,error, operation.response);
    }];
    
    [requestOperation start];
    
}

- (IBAction)toggleShowUserLocation {
    BOOL setting = !self.o_mapView.showsUserLocation;
    self.o_mapView.showsUserLocation = setting;
    self.o_mapView.userTrackingMode = setting ? MKUserTrackingModeFollow : MKUserTrackingModeNone;
    [self requestDataForVisibleViewRect];
}

// iOS 6 only
- (NSUInteger)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskAllButUpsideDown;
}

//iOS 5 only
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)aToInterfaceOrientation {
	return UIInterfaceOrientationIsLandscape(aToInterfaceOrientation) || UIInterfaceOrientationPortrait == aToInterfaceOrientation;
}


@end
