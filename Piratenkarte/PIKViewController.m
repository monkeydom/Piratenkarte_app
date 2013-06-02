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
#import "PIKPlakatServerButtonView.h"
#import "PIKServerListViewController.h"
#import "PIKNetworkErrorIndicationView.h"
#import <QuartzCore/QuartzCore.h>
#import "PIKPlakatDetailViewController.h"
#import "PIKPlakatPlaceView.h"
#import <AddressBookUI/AddressBookUI.h>

@interface PIKPlakat (AnnotationAdditions)
@end

@implementation PIKPlakat (AnnotationAdditions)

- (NSString *)title {
    NSString *result = [NSString stringWithFormat:@"%@ (%@ am %@)", [self localizedType],self.usernameOfLastChange,self.localizedLastModifiedDate];
    return result;
}

- (NSString *)subtitle {
    NSMutableArray *resultArray = [NSMutableArray array];
    if (self.comment.length > 0) [resultArray addObject:self.comment];
    if (self.imageURLString.length > 0) [resultArray addObject:self.imageURLString];
    [resultArray addObject:[@"#" stringByAppendingString:self.locationItemIdentifier]];
    [resultArray addObject:[NSString stringWithFormat:@"(fetched %@)",self.localizedLastServerFetchDate]];
    return [resultArray componentsJoinedByString:@" – "];
}

@end


@interface PIKViewController () <MKMapViewDelegate,PIKPlakatPlaceVieDelegate>
@property (nonatomic,strong) MKDMutableLocationItemStorage *locationItemStorage;
@property (nonatomic, strong) PIKPlakatServerButtonView *plakatServerButtonView;
@property (nonatomic) MKCoordinateRegion lastQueryRegion;
@property (nonatomic, strong) PIKPlakatDetailViewController *plakatDetailViewController;
@property (nonatomic, strong) NSMutableArray *plakatPlaceViews;
@property (nonatomic, strong) IBOutlet UILabel *plakatPlaceHelpLabel;
@end

static PIKViewController *S_sharedViewController = nil;

@implementation PIKViewController

+ (instancetype)sharedViewController {
    return S_sharedViewController;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        S_sharedViewController = self;
        self.plakatPlaceViews = [NSMutableArray new];
    }
    return self;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    PIKPlakatDetailViewController *detailController = self.plakatDetailViewController;
    PIKPlakat *plakat = (PIKPlakat *)view.annotation;
    detailController.plakat = plakat;
    [self presentViewController:detailController animated:YES completion:NULL];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    MKAnnotationView *result;
    if ([annotation isKindOfClass:[PIKPlakat class]]) {
        PIKPlakat *plakat = (PIKPlakat *)annotation;
        UIImage *pinImage = plakat.pinImage;

        NSString *identifier = plakat.plakatType;
        result = [mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (!result) {
            result = [[(pinImage ? [MKAnnotationView class] : [MKPinAnnotationView class]) alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
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
            UIButton* rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            result.rightCalloutAccessoryView = rightButton;

        }
        result.annotation = annotation;
        
        
    }
    return result;
}

- (void)mapView:(MKMapView *)aMapView regionDidChangeAnimated:(BOOL)animated {
    // NSLog(@"%s %@",__FUNCTION__,aMapView);
    if ([self regionWarrantsQuery:self.o_mapView.region]) {
        [self queryItemStorage];
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    CALayer *layer = view.layer;
    layer.shadowOpacity = 0.0;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    CALayer *layer = view.layer;
    layer.shadowColor = [[UIColor colorWithRed:0.170 green:0.639 blue:1.000 alpha:1.000] CGColor];
    layer.shadowOpacity = 1.0;
    layer.shadowRadius = 3.0;
    layer.shadowOffset = CGSizeZero;
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

- (PIKPlakatDetailViewController *)plakatDetailViewController {
    if (!_plakatDetailViewController) {
        _plakatDetailViewController = [[PIKPlakatDetailViewController alloc] initWithNibName:@"PIKPlakatDetailViewController" bundle:nil];
    }
    return _plakatDetailViewController;
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
    [self queryItemStorage];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(plakatServerDidReceiveData:) name:PIKPlakatServerDidReceiveDataNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedPlakatServerDidChange:) name:PIKPlakatServerManagerSelectedServerDidChangeNotification object:nil];
    
    self.plakatServerButtonView = [[PIKPlakatServerButtonView alloc] initWithFrame:CGRectZero];
    self.plakatServerButtonView.center = CGPointMake(10,10);
    [self.view addSubview:self.plakatServerButtonView];
    [self.plakatServerButtonView setPlakatServer:[[PIKPlakatServerManager plakatServerManager] selectedPlakatServer]];
    [self.plakatServerButtonView addTarget:self action:@selector(changePlakatServer:) forControlEvents:UIControlEventTouchUpInside];
    
    PIKNetworkErrorIndicationView *errorView  =[PIKNetworkErrorIndicationView networkErrorIndicationView];
    errorView.layer.position = CGPointMake(CGRectGetMaxX(self.view.bounds) - 2,CGRectGetMinY(self.view.bounds));
    [self.view addSubview:errorView];
}

- (void)changePlakatServer:(id)aSender {
//    NSLog(@"%s",__FUNCTION__);
    PIKPlakatServerManager *plakatServerManager = [PIKPlakatServerManager plakatServerManager];
    PIKServerListViewController *serverListViewController = [PIKServerListViewController serverListViewControllerWithServerList:plakatServerManager.serverList selectedServer:plakatServerManager.selectedPlakatServer];
    [self presentViewController:serverListViewController animated:YES completion:NULL];
}

- (void)plakatServerDidReceiveData:(NSNotification *)aNotification {
    [self queryItemStorage];
}

- (void)updatePlakatServerButtonView {
    [self.plakatServerButtonView setPlakatServer:[[PIKPlakatServerManager plakatServerManager] selectedPlakatServer]];
}

- (void)selectedPlakatServerDidChange:(NSNotification *)aNotification {
    [self hideAddUI];
    [self updatePlakatServerButtonView];
    [self queryItemStorage];
}

- (void)requestDataForVisibleViewRect {
    MKCoordinateRegion region = self.o_mapView.region;
    region.span.latitudeDelta *= 2.0;
    region.span.longitudeDelta *= 2.0;
    
    [[[PIKPlakatServerManager plakatServerManager] selectedPlakatServer] requestPlakateInCoordinateRegion:region];
}

- (BOOL)regionWarrantsQuery:(MKCoordinateRegion)aCoordinateRegion {
    if (!MKDCoordinateRegionContainsRegion(self.lastQueryRegion, aCoordinateRegion)) {
        return YES;
    } else if (aCoordinateRegion.span.latitudeDelta < self.lastQueryRegion.span.latitudeDelta / 5.0) {
        return YES;
    }
//    NSLog(@"%s saved a query",__FUNCTION__);
    return NO;
}

- (void)removeAnnotations:(NSArray *)anAnnotationArray {
    NSMutableArray *array;
    for (id<MKAnnotation> annotation in anAnnotationArray) {
        if ([annotation isKindOfClass:[MKUserLocation class]]) {
            if (!array) array = [anAnnotationArray mutableCopy];
            [array removeObject:annotation];
        }
    }
    [self.o_mapView removeAnnotations:array ? array : anAnnotationArray];
}

- (IBAction)queryItemStorage {
    [self storeLocationToDefaults];
    MKCoordinateRegion region = self.o_mapView.region;
    // increase region
    region.span.latitudeDelta *= 2.0;
    region.span.longitudeDelta *= 2.0;
    self.lastQueryRegion = region;
    NSArray *items = [[[[PIKPlakatServerManager plakatServerManager] selectedPlakatServer] locationItemStorage]locationItemsForCoordinateRegion:region];
    if (items) {
        [self removeAnnotations:self.o_mapView.annotations];
        [self.o_mapView addAnnotations:items];
        
        if (items.count <= 0 || ([[[items lastObject] lastServerFetchDate] timeIntervalSinceNow] < -60. * 15.)) {
            [self queryServer];
        }
    }
}

- (IBAction)toggleShowUserLocation {
    self.o_mapView.userTrackingMode = self.o_mapView.userTrackingMode == MKUserTrackingModeNone ? MKUserTrackingModeFollow : MKUserTrackingModeNone;
}

- (void)ensureValidCredentialsWithContinuation:(dispatch_block_t)aContinuation {
    PIKPlakatServer *selectedServer = [PIKPlakatServerManager plakatServerManager].selectedPlakatServer;
    if (selectedServer.hasValidPassword) {
        aContinuation();
    } else {
        UIAlertView *passwordAlert = [[UIAlertView alloc] initWithTitle:@"Server Login / Passwort" message:@"" completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
#if DEBUG
            NSLog(@"%s %@ %@",__FUNCTION__,[alertView textFieldAtIndex:0], [alertView textFieldAtIndex:1]);
#endif
            if (buttonIndex != 0) {
                NSString *username = [alertView textFieldAtIndex:0].text;
                NSString *password = [alertView textFieldAtIndex:1].text;
                [selectedServer validateUsername:username password:password completion:^(BOOL success, NSError *error) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        [self updatePlakatServerButtonView];
                        if (!success) {
                            NSString *title = @"Fehlgeschlagen";
                            NSString *message = [NSString stringWithFormat:@"Das Passwort für den Benutzer '%@' konnte leider nicht bestätigt werden.", username];
                            UIAlertView *confirmAlertView = [[UIAlertView alloc] initWithTitle:title message:message completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
                            } cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                            [confirmAlertView show];
                        } else {
                            if (aContinuation) aContinuation();
                        }
                    }];
                }];

            }
            
        } cancelButtonTitle:@"Abbrechen" otherButtonTitles:@"OK",nil];
        passwordAlert.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
        [[passwordAlert textFieldAtIndex:0] setText:selectedServer.username];
        [passwordAlert show];
        
    }
}

- (BOOL)isAddUIShown {
    if (self.plakatPlaceHelpLabel && self.plakatPlaceHelpLabel.alpha > 0.0) {
        return YES;
    }
    return NO;
}

- (void)toggleAddUI {
    BOOL isShown = [self isAddUIShown];
    if (!isShown) {
        [self showAddUI];
    } else {
        [self hideAddUI];
    }
}

- (void)hideAddUI {
    [UIView animateWithDuration:0.2 animations:^{
        self.plakatPlaceHelpLabel.alpha = 0.0;
    }];
    for (PIKPlakatPlaceView *placeView in self.plakatPlaceViews) {
        [placeView ploppViewOutCompletion:NULL];
    }
}

- (void)showAddUI {
    NSMutableArray *plakatAddViews = self.plakatPlaceViews;
    if (plakatAddViews.count <= 0) {
        for (NSString *plakatType in [PIKPlakat orderedPlakatTypes]) {
            PIKPlakatPlaceView *placeView = [[PIKPlakatPlaceView alloc] initWithPlakatType:plakatType];
            placeView.delegate = self;
            [plakatAddViews addObject:placeView];
        }
    }
    
    CGRect placementRect = self.o_mapView.frame;
    CGFloat frameHeight = CGRectGetHeight([plakatAddViews[0] bounds]) + 10.0;
    placementRect.origin.y = CGRectGetMinY(self.plakatPlaceHelpLabel.frame) - frameHeight;
    placementRect.size.height = frameHeight;
    CGFloat xpointdiff = CGRectGetWidth([plakatAddViews[0] bounds]);
    CGPoint placementCenter = CGPointMake(CGRectGetMaxX(placementRect) - ceilf(xpointdiff / 2.0), ceilf(CGRectGetMidY(placementRect)));
    
    for (PIKPlakatPlaceView *placeView in plakatAddViews) {
        placeView.alpha = 0.0;
        placeView.center = placementCenter;
        [self.view addSubview:placeView];
        placementCenter.x -= xpointdiff;
    }

    NSTimeInterval delay = 0.0;
    for (PIKPlakatPlaceView *placeView in plakatAddViews) {
        [placeView ploppViewInWithDelay:delay completion:NULL];
        delay += 0.025;
    }
    [UIView animateWithDuration:0.2 animations:^{
        self.plakatPlaceHelpLabel.alpha = 1.0;
    }];
}

- (IBAction)addAction {
    [self ensureValidCredentialsWithContinuation:^{
        // do the actual adding UI here
        [self toggleAddUI];
    }];
}

- (void)plakatPlaceViewDidStartDrag:(PIKPlakatPlaceView *)aPlakatPlaceView {
    // ignore currently
}

#define PLACEMENTYTHRESHOLD 30
#define PLACEMENTXTHRESHOLD 30

- (BOOL)plakatPlaceViewDidEndDragShouldSnapBack:(PIKPlakatPlaceView *)aPlakatPlaceView {
    CGPoint pointInMapViewCoords = [aPlakatPlaceView convertPoint:[aPlakatPlaceView targetPointInBoundsCoordinates] toView:self.o_mapView];
    CLLocationCoordinate2D coordinate = [self.o_mapView convertPoint:pointInMapViewCoords toCoordinateFromView:self.o_mapView];
    [[PIKPlakatServerManager geoCoder] reverseGeocodeLocation:[[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude] completionHandler:^(NSArray *placemarks, NSError *error) {
        if (placemarks.count > 0) {
            CLPlacemark *placemark = placemarks[0];
            NSString *addressString = ABCreateStringWithAddressDictionary(placemark.addressDictionary, NO);
#if DEBUG
            NSLog(@"%s %@",__FUNCTION__,addressString);
#endif
        }
    }];

    if (ABS(aPlakatPlaceView.transform.tx) < PLACEMENTXTHRESHOLD &&
        aPlakatPlaceView.transform.ty > -PLACEMENTYTHRESHOLD) {
        return YES;
    } else {
        PIKPlakat *plakat = [[PIKPlakat alloc] initWithCoordinate:coordinate plakatType:aPlakatPlaceView.plakatType];
        
        PIKPlakatDetailViewController *detailController = self.plakatDetailViewController;
        detailController.plakat = plakat;
        [self presentViewController:detailController animated:YES completion:^{
            [self hideAddUI];
        }];
        
        return NO;
    }
    
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
