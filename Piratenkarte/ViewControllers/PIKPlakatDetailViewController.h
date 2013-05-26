//
//  PIKPlakatDetailViewController.h
//  Piratenkarte
//
//  Created by Dominik Wagner on 26.05.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PIKPlakatDetailViewController;
#import "PIKPlakatServerManager.h"
#import "PIKPlakat.h"

@interface PIKPlakatDetailViewController : UIViewController

@property (nonatomic, strong) IBOutlet MKMapView *o_mapView;
@property (nonatomic, strong) IBOutlet UITableView *o_editingTableView;
@property (nonatomic, strong) IBOutlet UIView *o_tableViewFooterView;
@property (nonatomic, strong) IBOutlet UIButton *o_deleteButton;
@property (nonatomic, strong) IBOutlet UINavigationBar *O_topNavigationBar;

@property (nonatomic, strong) PIKPlakat *plakat;

- (IBAction)deletePlakatAction:(id)aSender;
- (IBAction)changeTypeAction:(id)aSender;
- (IBAction)dismissAction:(id)aSender;
- (IBAction)saveAction:(id)aSender;

@end
