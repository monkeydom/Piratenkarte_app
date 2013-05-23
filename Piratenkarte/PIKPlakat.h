//
//  PIKPlakat.h
//  Piratenkarte
//
//  Created by Dominik Wagner on 23.05.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MKDMutableLocationItemStorage.h"
#import <CoreLocation/CoreLocation.h>
#import "Api.pb.h"

@interface PIKPlakat : NSObject <MKDLocationItem, MKAnnotation>
@property (nonatomic) uint32_t plakatID;
@property (nonatomic, readonly, strong) NSString *locationItemIdentifier;
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic, strong) NSString *plakatType;
@property (nonatomic, strong) NSDate *lastModifiedDate;
@property (nonatomic, strong) NSDate *lastServerFetchDate;
@property (nonatomic, strong) NSString *comment;
@property (nonatomic, strong) NSString *imageURLString;
@property (nonatomic, strong) NSString *usernameOfLastChange;
@property (nonatomic, readonly) NSString *localizedType;
- (UIImage *)annotationImage;

- (instancetype)initWithPlakat:(Plakat *)aPlakat serverFetchDate:(NSDate *)aServerFetchDate;

@end
