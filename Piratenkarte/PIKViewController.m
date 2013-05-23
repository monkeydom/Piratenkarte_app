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

@interface Plakat (AnnotationAdditions) <MKAnnotation,MKDLocationItem>
@end

@implementation Plakat (AnnotationAdditions)

- (NSString *)locationItemIdentifier {
    return [@(self.id) stringValue];
}

- (CLLocationCoordinate2D)coordinate {
    CLLocationCoordinate2D result = CLLocationCoordinate2DMake(self.lat, self.lon);
    return result;
}

- (NSString *)title {
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterMediumStyle];
    NSString *result = [NSString stringWithFormat:@"%@ | %@", self.type, [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:self.lastModifiedTime]]];
    return result;
}

- (NSString *)subtitle {
    NSMutableArray *resultArray = [NSMutableArray array];
    if (self.lastModifiedUser) [resultArray addObject:self.lastModifiedUser];
    if (self.comment) [resultArray addObject:self.comment];
    return [resultArray componentsJoinedByString:@" | "];
}

- (UIImage *)annotationImage {
    UIImage *result = [UIImage imageNamed:[NSString stringWithFormat:@"PIKAnnotation_%@",self.type]];
    return result;
}

@end


@interface PIKViewController () <MKMapViewDelegate>
@property (nonatomic,strong) MKDMutableLocationItemStorage *locationItemStorage;
@end

@implementation PIKViewController

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    MKAnnotationView *result;
    if ([annotation isKindOfClass:[Plakat class]]) {
        Plakat *plakat = (Plakat *)annotation;
        result = [mapView dequeueReusableAnnotationViewWithIdentifier:@"Pirate"];
        if (!result) {
            result = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"Pirate"];
        }
        result.annotation = annotation;
        result.canShowCallout = YES;
        UIImage *plakatImage = plakat.annotationImage;
        if (plakatImage) result.image = plakatImage;
    }
    return result;
}


- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.o_mapView.showsUserLocation = YES;
    self.o_mapView.userTrackingMode = MKUserTrackingModeFollow;
    self.locationItemStorage = [MKDMutableLocationItemStorage new];
}

- (void)requestDataForVisibleViewRect {
    [[[PIKPlakatServerManager plakatServerManager] selectedPlakatServer] requestAllPlakate];
}

- (IBAction)queryItemStorage {
    MKCoordinateRegion region = self.o_mapView.region;
    NSArray *items = [self.locationItemStorage locationItemsForCoordinateRegion:region];
    NSLog(@"%s %@",__FUNCTION__,items);
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
