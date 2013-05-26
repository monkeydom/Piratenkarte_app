//
//  PIKViewController.h
//  Piratenkarte
//
//  Created by Dominik Wagner on 12.05.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "Api.pb.h"

@interface PIKViewController : UIViewController
@property (nonatomic, strong) IBOutlet MKMapView *o_mapView;
@property (nonatomic, strong) IBOutlet UIToolbar *o_toolbar;

+ (instancetype)sharedViewController;

- (void)ensureValidCredentialsWithContinuation:(dispatch_block_t)aContinuation;

- (IBAction)toggleShowUserLocation;
- (IBAction)queryItemStorage;
- (IBAction)addAction;

@end
