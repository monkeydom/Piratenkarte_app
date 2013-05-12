//
//  PIKViewController.m
//  Piratenkarte
//
//  Created by Dominik Wagner on 12.05.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import "PIKViewController.h"

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
    request.username = @"guest";
    request.password = @"pass";
    
    MKMapRect mapRect = self.o_mapView.visibleMapRect;
    CLLocationCoordinate2D southwest = MKCoordinateForMapPoint(MKMapPointMake(MKMapRectGetMinX(mapRect), MKMapRectGetMinY(mapRect)));
    CLLocationCoordinate2D northeast = MKCoordinateForMapPoint(MKMapPointMake(MKMapRectGetMaxX(mapRect), MKMapRectGetMaxY(mapRect)));
    
    BoundingBox_Builder *viewBoxBuilder = [BoundingBox builder];
    viewBoxBuilder.west =  southwest.longitude;
    viewBoxBuilder.south = southwest.latitude;
    viewBoxBuilder.east =  northeast.longitude;
    viewBoxBuilder.north = northeast.latitude;
    
    ViewRequest_Builder *viewRequestBuilder = [ViewRequest builder];
    viewRequestBuilder.viewBox  = [viewBoxBuilder build];
    request.viewRequest = [viewRequestBuilder build];
    Request *req = request.build;
    
    NSLog(@"%s %@ | %@ | %@ ",__FUNCTION__,request, req, req.data);
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
