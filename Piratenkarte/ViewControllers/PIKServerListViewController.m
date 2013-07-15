//
//  PIKServerListViewController.m
//  Piratenkarte
//
//  Created by Dominik Wagner on 25.05.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import "PIKServerListViewController.h"
#import "PIKLongDescriptionTableViewCell.h"

@interface PIKServerListViewController () <UITableViewDataSource,UITableViewDelegate>
@property (nonatomic, strong) NSArray *liveServerArray;
@property (nonatomic, strong) NSArray *developmentServerArray;
@property (nonatomic, strong) PIKPlakatServer *selectedServer;
@property (nonatomic, strong) PIKPlakatServer *initialSelectedServer;
@property (nonatomic, strong) UILabel *measurementLabel;
@end

@implementation PIKServerListViewController

+ (instancetype)serverListViewControllerWithServerList:(NSArray *)aServerList selectedServer:(PIKPlakatServer *)aSelectedServer {
    PIKServerListViewController *result = [[PIKServerListViewController alloc] initWithNibName:@"PIKServerListViewController" bundle:nil];
    result.selectedServer = aSelectedServer;
    result.initialSelectedServer = aSelectedServer;
    NSMutableArray *liveServers = [NSMutableArray new];
    NSMutableArray *devServers = [NSMutableArray new];
    for (PIKPlakatServer *server in aServerList) {
		if (server.isDevelopment) {
			[devServers addObject:server];
		} else {
			if (server.isCurrent) {
				[liveServers addObject:server];
			}
		}
    }
    result.liveServerArray = liveServers;
    result.developmentServerArray = devServers;
    return result;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        PIKLongDescriptionTableViewCell *cell = [[PIKLongDescriptionTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"unused"];
        cell.frame = CGRectMake(0, 0, 320, 200);
        cell.textLabel.text = @"testtext";
        cell.detailTextLabel.text = @"testtext";
        [cell layoutSubviews];
        self.measurementLabel = cell.detailTextLabel;
        self.measurementLabel.numberOfLines = 0;
        self.measurementLabel.frame = CGRectMake(0,0,280,640);
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	if ([[self serverArrayForSection:0] count] == 0) {
		// try reloading the json
		[[PIKPlakatServerManager plakatServerManager] refreshServerList];
	}
}

- (NSArray *)serverArrayForSection:(NSInteger)section {
    if (section == 0) return self.liveServerArray;
    if (section == 1) return self.developmentServerArray;
    return nil;
}

- (PIKPlakatServer *)plakatServerAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *serverList = [self serverArrayForSection:indexPath.section];
    PIKPlakatServer *server;
    if (serverList.count > indexPath.row) {
        server = serverList[indexPath.row];
    }
    return server;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#if DEBUG
    return 2;
#endif
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self serverArrayForSection:section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Live";
    } else {
        return @"Development";
    }
}

- (NSString *)detailForPlakatServer:(PIKPlakatServer *)aPlakatServer {
    NSString *firstLine = aPlakatServer.serverBaseURL;
    if (aPlakatServer.username.length > 0) {
        firstLine = [NSString stringWithFormat:@"%@ Login:%@ %@",firstLine,aPlakatServer.username, [aPlakatServer hasValidPassword] ? @"(Passwort validiert)" : @"(Passwort fehlt)"];
    }
    NSMutableString *serverInfoText = [aPlakatServer.serverInfoText mutableCopy];
    [serverInfoText replaceOccurrencesOfString:@"<br/>" withString:@"\n" options:0 range:NSMakeRange(0,serverInfoText.length)];
    [serverInfoText replaceOccurrencesOfString:@"<br />" withString:@"\n" options:0 range:NSMakeRange(0,serverInfoText.length)];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<[^>]*>" options:0 error:nil];
    [regex replaceMatchesInString:serverInfoText options:0 range:NSMakeRange(0,serverInfoText.length) withTemplate:@""];
    NSString *result = [@[firstLine, serverInfoText] componentsJoinedByString:@"\n"];
    return result;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PIKPlakatServer *server = [self plakatServerAtIndexPath:indexPath];
    UITableViewCell *cell;
    cell = [tableView dequeueReusableCellWithIdentifier:@"Server"];
    if (!cell) {
        cell = [[PIKLongDescriptionTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Server"];
    }
    cell.textLabel.text = server.serverName;
    cell.detailTextLabel.text = [self detailForPlakatServer:server];

    
    if ([server isEqual:self.selectedServer]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        PIKPlakatServer *server = [self plakatServerAtIndexPath:indexPath];
        [server removePassword];
        [tableView cellForRowAtIndexPath:indexPath].detailTextLabel.text = [self detailForPlakatServer:[self plakatServerAtIndexPath:indexPath]];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	if ([[self serverArrayForSection:section] count] == 0) {
		return @"Server Liste konnte nicht geladen werden. Bitte Abbrechen und erneut versuchen.";
	} else {
		return @"Wischen um das Passwort zu vergessen.";
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedServer = [self plakatServerAtIndexPath:indexPath];
    for (int s=0; s<[self numberOfSectionsInTableView:tableView]; s++) {
        for (int i=0; i<[self tableView:tableView numberOfRowsInSection:s]; i++) {
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:s]];
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {    
    PIKPlakatServer *server = [self plakatServerAtIndexPath:indexPath];
    self.measurementLabel.frame = CGRectMake(0,0,280,640);
    
    CGSize testSize = CGSizeMake(CGRectGetWidth(self.view.bounds) - 60, 640);
    CGSize realSize = [[self detailForPlakatServer:server] sizeWithFont:self.measurementLabel.font constrainedToSize:testSize lineBreakMode:UILineBreakModeWordWrap];
    
    
    CGFloat height = realSize.height;
    height += 32;
    return height;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    PIKPlakatServer *server = [self plakatServerAtIndexPath:indexPath];
    if ([server hasValidPassword]) {
        return YES;
    }
    return NO;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Passwort vergessen";
}

- (void)cancelAction {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)doneAction {
    if (![self.selectedServer.identifier isEqualToString:self.initialSelectedServer.identifier]) {
        [[PIKPlakatServerManager plakatServerManager] selectPlakatServer:self.selectedServer];
    }
    [self dismissViewControllerAnimated:YES completion:NULL];
}
@end
