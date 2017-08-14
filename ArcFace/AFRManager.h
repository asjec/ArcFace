//
//  AFRManager.h
//  ARCFaceRecognizeTestbed
//
//  Created by clin on 4/1/17.
//  Copyright © 2017 ArcSoftSpotlight. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFRPerson.h"

@interface AFRManager : NSObject

@property (nonatomic, strong, readonly) NSArray* allPersons;
@property (nonatomic, assign) NSUInteger frModelVersion;

- (BOOL)addPerson:(AFRPerson*)person;

- (NSUInteger)getNewPersonID;

- (BOOL)updateAllPersonsFeatureData;

@end
