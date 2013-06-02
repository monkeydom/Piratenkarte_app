//
//  PIKPlakatTypeListViewController.h
//  Piratenkarte
//
//  Created by Dominik Wagner on 02.06.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PIKPlakatTypeListViewController;
#import "PIKPlakat.h"

@protocol PIKPlakatTypeListViewControllerDelegate
- (void)plakatTypeListViewController:(PIKPlakatTypeListViewController *)aController didChooseType:(NSString *)aType;
@end

@interface PIKPlakatTypeListViewController : UIViewController
@property (nonatomic, strong) NSString *selectedPlakatType;
@property (nonatomic, strong) IBOutlet UITableView *o_tableView;
@property (nonatomic, weak) id <PIKPlakatTypeListViewControllerDelegate> delegate;
- (IBAction)cancelAction:(id)aSender;

+ (instancetype)listControllerWithSelectedType:(NSString *)aType;
@end
