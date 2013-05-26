//
//  PIKPlakatDetailViewController.m
//  Piratenkarte
//
//  Created by Dominik Wagner on 26.05.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import "PIKPlakatDetailViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "PIKPlakat.h"
#import "PIKPlakatServer.h"
#import "PIKViewController.h"

@interface PIKPlakatDetailViewController () <UITableViewDataSource, UITableViewDelegate, MKMapViewDelegate>

@end

@implementation PIKPlakatDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
//    [self.o_mapView setScrollEnabled:NO];
//    [self.o_mapView setZoomEnabled:NO];
    
    UIImage *normal = [[UIImage imageNamed:@"PIKDeleteButtonNormal"] resizableImageWithCapInsets:UIEdgeInsetsMake(23, 6, 20, 6)];
    UIImage *pressed = [[UIImage imageNamed:@"PIKDeleteButtonPressed"] resizableImageWithCapInsets:UIEdgeInsetsMake(23, 6, 20, 6)];
    
    [self.o_deleteButton setBackgroundImage:normal forState:UIControlStateNormal];
    [self.o_deleteButton setBackgroundImage:pressed forState:UIControlStateHighlighted];
        
    [self adjustToPlakat];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)dismissAction:(id)aSender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)saveAction:(id)aSender {
    // TODO: save something
    [self dismissAction:aSender];
}

- (MKMapRect)detailMapRectForPlakat:(PIKPlakat *)aPlakat {
    CLLocationDistance oneMapPointInMeters = MKMetersPerMapPointAtLatitude(aPlakat.coordinate.latitude);
    MKMapRect result = MKMapRectMake(0, 0, 0, 0);
    result.origin = MKMapPointForCoordinate(aPlakat.coordinate);
    result = MKMapRectInset(result, -150.0 / oneMapPointInMeters, -25.0 / oneMapPointInMeters);
    result.origin.y -= 30.0 / oneMapPointInMeters;
    return result;
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
            result.canShowCallout = NO;
            if (pinImage) {
                result.image = pinImage;
                result.centerOffset = plakat.pinImageCenterOffset;
                result.calloutOffset = CGPointMake(-plakat.pinImageCenterOffset.x,2);
            }
        }
        result.annotation = annotation;
        if (plakat == self.plakat) {
            CALayer *layer = result.layer;
            layer.shadowColor = [[UIColor colorWithRed:0.673 green:0.430 blue:0.096 alpha:1.000] CGColor];
            layer.shadowOpacity = 1.0;
            layer.shadowRadius = 5.0;
            layer.shadowOffset = CGSizeZero;
        }
        result.selected = YES;
    }
    return result;
}

- (void)adjustToPlakat {
    [self.o_mapView removeAnnotations:self.o_mapView.annotations];
    [self.o_mapView setVisibleMapRect:[self detailMapRectForPlakat:self.plakat]];
    
    MKCoordinateRegion region = self.o_mapView.region;
    NSArray *items = [[[[PIKPlakatServerManager plakatServerManager] selectedPlakatServer] locationItemStorage]locationItemsForCoordinateRegion:region];
    if (items) {
        [self.o_mapView addAnnotations:items];
    }

    [self.o_mapView addAnnotation:self.plakat];
    self.O_topNavigationBar.topItem.title = self.plakat.localizedType;
    
    [self.o_editingTableView reloadData];
}

- (void)setPlakat:(PIKPlakat *)aPlakat {
    _plakat = aPlakat;
    [self adjustToPlakat];
}

- (void)changeTypeAction:(id)aSender {
    // TODO:
}

- (void)deletePlakatAction:(id)aSender {
    [[PIKViewController sharedViewController] ensureValidCredentialsWithContinuation:^{
        UIAlertView *deleteAlert =[[UIAlertView alloc] initWithTitle:@"Plakatstelle Löschen" message:@"Diese Plakatstelle wirklich Löschen?" completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
            if (buttonIndex != alertView.cancelButtonIndex) {
                [[[PIKPlakatServerManager plakatServerManager] selectedPlakatServer] removePlakatFromServer:self.plakat completion:^(BOOL success, NSError *error) {
                    if (success) {
                        [[PIKViewController sharedViewController] queryItemStorage];
                        [self dismissAction:self];
                    } else {
                        UIAlertView *informationAlert = [[UIAlertView alloc] initWithTitle:@"Fehlgeschlagen" message:@"Die Plakatstelle konnte nicht gelöscht werden." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                        [informationAlert show];
                    }
                }];
            }
        } cancelButtonTitle:nil otherButtonTitles:@"Löschen",@"Abbrechen", nil];
        deleteAlert.cancelButtonIndex = 1;
        [deleteAlert show];
    }];
}

#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 1;
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section != 0) return nil;
    PIKPlakat *plakat = self.plakat;
    NSString *result = [NSString stringWithFormat:@"Zuletzt geändert von %@ am %@. Zuletzt vom Server bekommen am %@.",plakat.usernameOfLastChange, plakat.localizedLastModifiedDate ,plakat.localizedLastServerFetchDate];
    return result;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"label"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"label"];
        cell.detailTextLabel.numberOfLines = 0;
    }
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"Kommentar";
            cell.detailTextLabel.text = self.plakat.comment;
            break;
    }
    return cell;
}

@end
