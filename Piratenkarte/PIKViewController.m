//
//  PIKViewController.m
//  Piratenkarte
//
//  Created by Dominik Wagner on 12.05.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//


#import "PIKViewController.h"
#import "AFNetworking.h"
#import <CoreLocation/CoreLocation.h>
#import "MKDMutableLocationItemStorage.h"
#import "PIKPlakatServerManager.h"
#import "PIKPlakat.h"

@interface PIKPlakat (AnnotationAdditions)
@end

@implementation PIKPlakat (AnnotationAdditions)

+ (NSDateFormatter *)dateFormatter {
    static NSDateFormatter *formatter;
    if (!formatter) {
        formatter = [NSDateFormatter new];
        [formatter setDateStyle:NSDateFormatterShortStyle];
        [formatter setTimeStyle:NSDateFormatterShortStyle];
    }
    return formatter;
}

- (NSString *)title {
    NSDateFormatter *formatter = [self.class dateFormatter];
    NSString *result = [NSString stringWithFormat:@"%@ (%@ am %@)", [self localizedType],self.usernameOfLastChange,[formatter stringFromDate:self.lastModifiedDate]];
    return result;
}

- (NSString *)subtitle {
    NSDateFormatter *formatter = [self.class dateFormatter];
    NSMutableArray *resultArray = [NSMutableArray array];
    if (self.comment.length > 0) [resultArray addObject:self.comment];
    if (self.imageURLString.length > 0) [resultArray addObject:self.imageURLString];
    [resultArray addObject:[NSString stringWithFormat:@"(fetched %@)",[formatter stringFromDate:self.lastServerFetchDate]]];
    return [resultArray componentsJoinedByString:@" – "];
}

@end


@interface PIKViewController () <MKMapViewDelegate>
@property (nonatomic,strong) MKDMutableLocationItemStorage *locationItemStorage;
@end

@implementation PIKViewController

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    MKAnnotationView *result;
    if ([annotation isKindOfClass:[PIKPlakat class]]) {
        PIKPlakat *plakat = (PIKPlakat *)annotation;
        UIImage *pinImage = plakat.pinImage;

        NSString *identifier = pinImage ? @"Pirate" : @"PiratePin";
        result = [mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (!result) {
            result = [[(pinImage ? [MKAnnotationView class] : [MKPinAnnotationView class]) alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
        }
        result.annotation = annotation;
        result.canShowCallout = YES;
        
        
        UIImage *plakatImage = plakat.annotationImage;
        if (plakatImage) {
            UIImageView *detailView = [[UIImageView alloc] initWithImage:plakatImage];
            result.leftCalloutAccessoryView = detailView;
        }
        if (pinImage) {
            result.image = pinImage;
            result.centerOffset = plakat.pinImageCenterOffset;
            result.calloutOffset = CGPointMake(-plakat.pinImageCenterOffset.x,2);
        }
    }
    return result;
}

- (void)mapView:(MKMapView *)aMapView regionDidChangeAnimated:(BOOL)animated {
    // NSLog(@"%s %@",__FUNCTION__,aMapView);
    [self queryItemStorage];
}

#define CURRENTPOSITIONBASEKEY @"CurrentMapRect"

- (void)restoreLocationFromDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults doubleForKey:CURRENTPOSITIONBASEKEY@"Lon"]) {
        MKCoordinateRegion region;
        region.center.longitude = [defaults doubleForKey:CURRENTPOSITIONBASEKEY@"Lon"];
        region.center.latitude = [defaults doubleForKey:CURRENTPOSITIONBASEKEY@"Lat"];
        region.span.longitudeDelta = [defaults doubleForKey:CURRENTPOSITIONBASEKEY@"LonD"];
        region.span.latitudeDelta = [defaults doubleForKey:CURRENTPOSITIONBASEKEY@"LatD"];
        self.o_mapView.region = region;
    }
}

- (void)storeLocationToDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    MKCoordinateRegion region = self.o_mapView.region;
    [defaults setDouble:region.center.longitude forKey:CURRENTPOSITIONBASEKEY@"Lon"];
    [defaults setDouble:region.center.latitude  forKey:CURRENTPOSITIONBASEKEY@"Lat"];
    [defaults setDouble:region.span.longitudeDelta forKey:CURRENTPOSITIONBASEKEY@"LonD"];
    [defaults setDouble:region.span.latitudeDelta forKey:CURRENTPOSITIONBASEKEY@"LatD"];
    [defaults synchronize];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.o_mapView.showsUserLocation = YES;

//    self.o_mapView.userTrackingMode = MKUserTrackingModeFollow;

    MKUserTrackingBarButtonItem *buttonItem = [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.o_mapView];
    NSArray *items = [@[buttonItem] arrayByAddingObjectsFromArray:self.o_toolbar.items];
    self.o_toolbar.items = items;
    [self restoreLocationFromDefaults];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(plakatServerDidReceiveData:) name:PIKPlakatServerDidReceiveDataNotification object:nil];
}

- (void)plakatServerDidReceiveData:(NSNotification *)aNotification {
    [self queryItemStorage];
}

- (void)requestDataForVisibleViewRect {
    MKCoordinateRegion region = self.o_mapView.region;
    region.span.latitudeDelta *= 2.0;
    region.span.longitudeDelta *= 2.0;
    
    [[[PIKPlakatServerManager plakatServerManager] selectedPlakatServer] requestPlakateInCoordinateRegion:region];
}

- (IBAction)queryItemStorage {
    [self storeLocationToDefaults];
    MKCoordinateRegion region = self.o_mapView.region;
    NSArray *items = [[[[PIKPlakatServerManager plakatServerManager] selectedPlakatServer] locationItemStorage]locationItemsForCoordinateRegion:region];
    if (items) {
        [self.o_mapView removeAnnotations:self.o_mapView.annotations];
        [self.o_mapView addAnnotations:items];
    }
}

- (IBAction)toggleShowUserLocation {
    self.o_mapView.userTrackingMode = self.o_mapView.userTrackingMode == MKUserTrackingModeNone ? MKUserTrackingModeFollow : MKUserTrackingModeNone;
}

- (IBAction)queryServer {
    [self storeLocationToDefaults];
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
