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
    Request_Builder *request = [Request builder];
    request.username = @"monkeydom";
    request.password = @"XQtx9M6mZ";
    
    MKMapRect mapRect = self.o_mapView.visibleMapRect;
    CLLocationCoordinate2D northwest = MKCoordinateForMapPoint(MKMapPointMake(MKMapRectGetMinX(mapRect), MKMapRectGetMinY(mapRect)));
    CLLocationCoordinate2D southeast = MKCoordinateForMapPoint(MKMapPointMake(MKMapRectGetMaxX(mapRect), MKMapRectGetMaxY(mapRect)));
    
    CLLocationCoordinate2D plakat11324 = CLLocationCoordinate2DMake(52.327688774048, 9.204402809148901);
    
    BoundingBox_Builder *viewBoxBuilder = [BoundingBox builder];
    viewBoxBuilder.west =  plakat11324.longitude -0.1;
    viewBoxBuilder.south = plakat11324.latitude  -0.1;
    viewBoxBuilder.east =  plakat11324.longitude +0.1;
    viewBoxBuilder.north = plakat11324.latitude  +0.1;
    
    ViewRequest_Builder *viewRequestBuilder = [ViewRequest builder];
//    viewRequestBuilder.filterType = @"";
//    viewRequestBuilder.viewBox  = [viewBoxBuilder build];
    request.viewRequest = [viewRequestBuilder build];
    Request *req = request.build;
    
    NSLog(@"%s %@ | %@ | %@ ",__FUNCTION__,request, req, req.data);
    
    NSData *postData = req.data;
    
    [postData writeToFile:@"/tmp/karten.post" atomically:NO];
    
    Request *parsedReq = [Request parseFromData:postData];
    NSLog(@"%s parsed Request: %@ ",__FUNCTION__, parsedReq);
    
    NSString *testURLString = @"http://piraten.boombuler.de/testbtw/api.php";
    testURLString = @"https://plakate.piraten-nds.de/api.php";
    NSURL *testURL = [NSURL URLWithString:testURLString];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:testURL];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setHTTPBody:postData];
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSLog(@"%s success %@, %@",__FUNCTION__,operation.response, responseObject);
//        NSLog(@"%s all Headers %@",__FUNCTION__,[operation.response allHeaderFields]);
        Response *response = [Response parseFromData:responseObject];
        NSLog(@"%s parsed response = %@",__FUNCTION__,response);
        [responseObject writeToFile:@"/tmp/plakate.protobuf" atomically:NO];
        [[response.description dataUsingEncoding:NSUTF8StringEncoding] writeToFile:@"/tmp/plakate.txt" atomically:NO];
        
        [self.o_mapView addAnnotations:response.plakate];
        for (Plakat *plakat in response.plakate) {
            [self.locationItemStorage addLocationItem:plakat];
        }
        [self.o_mapView setCenterCoordinate:[response.plakate.lastObject coordinate] animated:YES];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%s failure: %@\n %@",__FUNCTION__,error, operation.response);
    }];
    
    [requestOperation start];
    
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
