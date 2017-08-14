//
//  AFRCDManager.h
//  ArcFR
//
//  Created by clin on 17/04/01.
//  Copyright (c) 2017年 arcsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class AFRPerson;

@interface AFRCDManager : NSObject

@property (readonly, assign, nonatomic) NSUInteger maxPersonID;

- (id)init;
- (void)reset; // clear memory cache

- (NSArray*)allPersons;
- (BOOL)addPerson:(AFRPerson*)person;

- (void)setFrModelVersion:(NSUInteger)frModelVersion;
- (NSUInteger)getFrModeVersion;
- (BOOL)updatePersonFeatureData:(NSArray*)arrayPersons;

@end
