//
//  PIKPlakatTypeListViewController.m
//  Piratenkarte
//
//  Created by Dominik Wagner on 02.06.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import "PIKPlakatTypeListViewController.h"

@interface PIKPlakatTypeListViewController () <UITableViewDataSource, UITableViewDelegate>

@end

@implementation PIKPlakatTypeListViewController

+ (instancetype)listControllerWithSelectedType:(NSString *)aType {
    PIKPlakatTypeListViewController *result = [[PIKPlakatTypeListViewController alloc] initWithNibName:@"PIKPlakatTypeListViewController" bundle:nil];
    result.selectedPlakatType = aType;
    return result;
}

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
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSArray *)plakatTypes {
    return [PIKPlakat orderedPlakatTypes];
}

- (NSString *)plakatTypeForIndexPath:(NSIndexPath *)anIndexPath {
    return self.plakatTypes[anIndexPath.row];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.plakatTypes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    [tableView dequeueReusableCellWithIdentifier:@"typ"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"typ"];
    }
    
    NSString *typ = [self plakatTypeForIndexPath:indexPath];
    cell.imageView.image = [PIKPlakat annotationImageForPlakatType:typ];
    cell.detailTextLabel.text = typ;
    cell.textLabel.text = [PIKPlakat localizedDescriptionForPlakatType:typ];
    if ([typ isEqual:self.selectedPlakatType]) {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else {
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *typ = [self plakatTypeForIndexPath:indexPath];
    [self.delegate plakatTypeListViewController:self didChooseType:typ];
    [self cancelAction:self];
}

- (IBAction)cancelAction:(id)aSender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
