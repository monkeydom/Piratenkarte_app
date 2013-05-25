//
//  PIKServerListViewController.h
//  Piratenkarte
//
//  Created by Dominik Wagner on 25.05.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PIKServerListViewController;
#import "PIKPlakatServerManager.h"
#import "PIKPlakatServer.h"

@interface PIKServerListViewController : UIViewController
+ (instancetype)serverListViewControllerWithServerList:(NSArray *)aServerList selectedServer:(PIKPlakatServer *)aSelectedServer;

- (IBAction)cancelAction;
- (IBAction)doneAction;

@end
