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
#import "PIKEditableCommentsCell.h"

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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self
						   selector:@selector(keyboardWillShow:)
							   name:UIKeyboardWillShowNotification object:nil];
	
	[notificationCenter addObserver:self
						   selector:@selector(keyboardWillHide:)
							   name:UIKeyboardWillHideNotification object:nil];

}

- (void)viewDidDisappear:(BOOL)animated {
    self.o_containerView.transform = CGAffineTransformIdentity;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)keyboardWillShow:(NSNotification *)aNotification {
    NSLog(@"%s %@",__FUNCTION__,aNotification.userInfo);
    UITableViewCell *cell = [self.o_editingTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    CGRect tableCellRect = [cell.superview convertRect:cell.frame toView:self.view];
    CGRect keyboardEndRect = [aNotification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat keyboardPosition = CGRectGetHeight(keyboardEndRect) + 10;
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        keyboardPosition = CGRectGetWidth(keyboardEndRect);
    }
    CGFloat delta = (CGRectGetMaxY(self.view.bounds) - keyboardPosition) - CGRectGetMaxY(tableCellRect);
    if (delta < 0) {
        [UIView animateWithDuration:[aNotification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue] animations:^{
            self.o_containerView.transform = CGAffineTransformMakeTranslation(0, delta);
        }];
    }
}

- (void)keyboardWillHide:(NSNotification *)aNotification {
    [UIView animateWithDuration:[aNotification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue] animations:^{
        self.o_containerView.transform = CGAffineTransformIdentity;
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (IBAction)dismissAction:(id)aSender {
    PIKEditableCommentsCell *cell = (PIKEditableCommentsCell *)[self.o_editingTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    if ([cell.textView isFirstResponder]) {
        [cell.textView resignFirstResponder];
        cell.textView.text = self.plakat.comment;
    } else {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}

- (void)reportGenericNetworkFailure {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Netzwerkfehler" message:@"Leider konnte die Änderung nicht durchgeführt werden." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alertView show];
}

- (IBAction)saveAction:(id)aSender {
    PIKEditableCommentsCell *cell = (PIKEditableCommentsCell *)[self.o_editingTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    NSString *comment = cell.textView.text;
    BOOL cellIsFirstResponder = cell.textView.isFirstResponder;
    if (self.plakatIsNew) {
        if (cellIsFirstResponder) {
            self.plakat.comment = comment;
        }
        [[[PIKPlakatServerManager plakatServerManager] selectedPlakatServer] addPlakat:self.plakat completion:^(BOOL success, NSError *error) {
            if (success) {
                if (cellIsFirstResponder) {
                    [cell.textView resignFirstResponder];
                }
                [self dismissAction:aSender];
            } else {
                [self reportGenericNetworkFailure];
            }
        }];
    } else if ([cell.textView isFirstResponder]) {
        [[[PIKPlakatServerManager plakatServerManager] selectedPlakatServer] updateComment:comment onPlakat:self.plakat completion:^(BOOL success, NSError *error) {
            if (success) {
                [cell.textView resignFirstResponder];
                self.plakat.comment = comment;
                cell.textView.text = comment;
            } else {
                [self reportGenericNetworkFailure];
            }
        }];
    } else {
        [self dismissAction:aSender];
    }
}

- (MKMapRect)detailMapRectForPlakat:(PIKPlakat *)aPlakat {
    CLLocationDistance oneMapPointInMeters = MKMetersPerMapPointAtLatitude(aPlakat.coordinate.latitude);
    MKMapRect result = MKMapRectMake(0, 0, 0, 0);
    result.origin = MKMapPointForCoordinate(aPlakat.coordinate);
    result = MKMapRectInset(result, -150.0 / oneMapPointInMeters, -25.0 / oneMapPointInMeters);
    result.origin.y -= 20.0 / oneMapPointInMeters;
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
        } else {
            result.layer.shadowOpacity = 0.0;
        }
        result.selected = YES;
    }
    return result;
}

- (void)adjustToPlakat {
    [self.o_mapView removeAnnotations:self.o_mapView.annotations];
    [self.o_mapView setVisibleMapRect:[self detailMapRectForPlakat:self.plakat] animated:YES];
    
    MKCoordinateRegion region = self.o_mapView.region;
    NSArray *items = [[[[PIKPlakatServerManager plakatServerManager] selectedPlakatServer] locationItemStorage]locationItemsForCoordinateRegion:region];
    if (items) {
        [self.o_mapView addAnnotations:items];
    }

    [self.o_mapView addAnnotation:self.plakat];
    self.O_topNavigationBar.topItem.title = self.plakat.localizedType;
    
    [self.o_editingTableView reloadData];
    
    self.o_deleteButton.enabled = (self.plakat.lastServerFetchDate != nil);
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

- (BOOL)plakatIsNew {
    BOOL result = (self.plakat.lastServerFetchDate == nil);
    return result;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section != 0) return nil;
    NSString *result;
    PIKPlakat *plakat = self.plakat;
    if (self.plakatIsNew) {
        result = @"Neues Plakat.";
    } else {
        result = [NSString stringWithFormat:@"Geändert von %@\n am %@. Vom Server bekommen am %@.\n#%d",plakat.usernameOfLastChange, plakat.localizedLastModifiedDate ,plakat.localizedLastServerFetchDate,plakat.plakatID];
    }
    return result;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    PIKEditableCommentsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"label"];
    if (!cell) {
        cell = [[PIKEditableCommentsCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"label"];
        cell.detailTextLabel.numberOfLines = 0;
        cell.textLabel.minimumFontSize = 6.0;
        cell.textLabel.adjustsLetterSpacingToFitWidth = YES;
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
    }
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"Kommentar";
            cell.detailTextLabel.text = self.plakat.comment;
            cell.textView.text = self.plakat.comment;
            break;
    }
    return cell;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    if (view.annotation != self.plakat) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self.plakat = (PIKPlakat *)view.annotation;
        }];
    }
}

@end
