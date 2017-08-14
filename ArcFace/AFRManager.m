//
//  AFRManager.m
//  ARCFaceRecognizeTestbed
//
//  Created by clin on 4/1/17.
//  Copyright © 2017 ArcSoftSpotlight. All rights reserved.
//

#import "AFRManager.h"
#import "AFRCDManager.h"




@interface AFRManager ()
{
    
}

@property (atomic, assign) NSUInteger maxPersonId;
@property (nonatomic, strong) AFRCDManager* cdManager;
@property (nonatomic, strong, readwrite) NSMutableArray* allPersons;

@end

@implementation AFRManager


- (instancetype)init
{
    if (self = [super init]) {
        _cdManager = [[AFRCDManager alloc] init];
        
        _frModelVersion = [_cdManager getFrModeVersion];
        _allPersons = [NSMutableArray arrayWithArray:[_cdManager allPersons]];
        _maxPersonId = _cdManager.maxPersonID;
    }
    
    return self;
}

- (BOOL)addPerson:(AFRPerson*)person
{
    [_allPersons addObject:person];
    
    return [_cdManager addPerson:person];
}

- (NSUInteger)getNewPersonID
{
    self.maxPersonId += 1;
    return self.maxPersonId;
}

- (void)setFrModelVersion:(NSUInteger)frModelVersion
{
    _frModelVersion = frModelVersion;
    _cdManager.frModelVersion = frModelVersion;
}

- (BOOL)updateAllPersonsFeatureData
{
    return [_cdManager updatePersonFeatureData:_allPersons];
}
@end
