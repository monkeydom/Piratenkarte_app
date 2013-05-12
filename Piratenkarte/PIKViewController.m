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

- (IBAction)toggleShowUserLocation {
    BOOL setting = !self.o_mapView.showsUserLocation;
    self.o_mapView.showsUserLocation = setting;
    self.o_mapView.userTrackingMode = setting ? MKUserTrackingModeFollow : MKUserTrackingModeNone;
    
    Request_Builder *request = [Request builder];
    request.username = @"guest";
    request.password = @"pass";
    Request *req = request.build;
    NSLog(@"%s %@ | %@ | %@",__FUNCTION__,request, req, req.data);
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
