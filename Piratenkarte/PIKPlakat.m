//
//  PIKPlakat.m
//  Piratenkarte
//
//  Created by Dominik Wagner on 23.05.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import "PIKPlakat.h"

@interface PIKPlakat ()
@property (nonatomic, strong, readwrite) NSString *locationItemIdentifier;
@end

@implementation PIKPlakat

- (instancetype)initWithPlakat:(Plakat *)aPlakat serverFetchDate:(NSDate *)aServerFetchDate {
    self = [self init];
    if (self) {
        self.lastModifiedDate = aServerFetchDate;
        [self updateValuesWithPlakat:(Plakat *)aPlakat];
    }
    return self;
}


- (void)setPlakatID:(uint32_t)aPlakatID {
    _plakatID = aPlakatID;
    self.locationItemIdentifier = [@(aPlakatID) stringValue];
}

- (void)updateValuesWithPlakat:(Plakat *)aPlakat {
    self.plakatID = aPlakat.id;
    self.coordinate = CLLocationCoordinate2DMake(aPlakat.lat, aPlakat.lon);
    self.plakatType = aPlakat.type;
    self.usernameOfLastChange = aPlakat.lastModifiedUser;
    self.lastModifiedDate = [NSDate dateWithTimeIntervalSince1970:aPlakat.lastModifiedTime];
    self.imageURLString = aPlakat.imageUrl;
    self.comment = aPlakat.comment;
}

@end
