//
//  AFRCDPerson+CoreDataProperties.m
//  
//
//  Created by yalichen on 17/5/3.
//
//  This file was automatically generated and should not be edited.
//

#import "AFRCDPerson+CoreDataProperties.h"

@implementation AFRCDPerson (CoreDataProperties)

+ (NSFetchRequest<AFRCDPerson *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"AFRCDPerson"];
}

@dynamic faceFeatureData;
@dynamic faceID;
@dynamic faceThumb;
@dynamic faceThumbHeight;
@dynamic faceThumbWidth;
@dynamic name;
@dynamic personID;

@end
