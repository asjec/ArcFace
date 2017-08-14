//
//  AFRCDManager.m
//  ArcFR
//
//  Created by clin on 17/04/01.
//  Copyright (c) 2017年 arcsoft. All rights reserved.
//

#import "AFRCDManager.h"
#import "AFRCDPerson+CoreDataClass.h"
#import "AFRPerson.h"
#import "AFRCDVersion+CoreDataClass.h"

static  NSString* const kAFRModelName = @"FSDKFR";
static  NSString* const kAFRPersonEntityName = @"AFRCDPerson";
static  NSString* const kAFRVersionEntityName = @"AFRCDVersion";

@interface AFRCDManager ()

@property (readwrite, assign, nonatomic) NSUInteger maxPersonID;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory;

@end

@implementation AFRCDManager

- (id)init
{
    if (self = [super init]) {
    }
    
    return self;
}

- (void)reset
{
    
}

- (void)setFrModelVersion:(NSUInteger)frModelVersion
{
    NSManagedObjectContext *managedContext = self.managedObjectContext;
    NSFetchRequest* request = [AFRCDVersion fetchRequest];
    NSArray *arrayVersions = [managedContext executeFetchRequest:request error:nil];
    if(arrayVersions.count > 0)
    {
        AFRCDVersion *cdVersion = [arrayVersions objectAtIndex:0];
        cdVersion.frmodelversion = (int32_t)frModelVersion;
    }
    else
    {
        AFRCDVersion* cdVersion = [NSEntityDescription insertNewObjectForEntityForName:kAFRVersionEntityName inManagedObjectContext:managedContext];
        cdVersion.frmodelversion = (int32_t)frModelVersion;
     }
    
    [self saveContext:managedContext];  
}

- (NSUInteger)getFrModeVersion
{
    NSFetchRequest* request = [AFRCDVersion fetchRequest];
    NSArray* objects = [self.managedObjectContext executeFetchRequest:request error:nil];
    if (objects == nil) {
        NSLog(@"There are error!");
    }
    
    NSUInteger frModelVersion = 0;
    for (AFRCDVersion *cdVersion in objects) {
        frModelVersion = cdVersion.frmodelversion;
        break;
    }
    
    return frModelVersion;
}

- (NSArray*)allPersons
{
    NSFetchRequest* request = [AFRCDPerson fetchRequest];
    NSError* error = nil;
    NSArray* objects = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (objects == nil) {
        NSLog(@"There are error!");
    }
    
    NSMutableArray* afrPersonArray = [[NSMutableArray alloc]init];
    for (AFRCDPerson* cdPerson in objects)
    {
        AFRPerson* person = [[AFRPerson alloc] initWithCDPerson:cdPerson];
        [afrPersonArray addObject:person];
        
        if (cdPerson.personID > self.maxPersonID) {
            self.maxPersonID = cdPerson.personID;
        }
    }
    
    return afrPersonArray;
}


- (BOOL)addPerson:(AFRPerson*)person
{
    if (NULL == person) {
        return NO;
    }
    
    NSFetchRequest* request = [AFRCDPerson fetchRequest];
    NSArray* objects = [self.managedObjectContext executeFetchRequest:request error:nil];
    if (objects == nil) {
        NSLog(@"There are error!");
    }
    
    NSManagedObjectContext *managedContext = self.managedObjectContext;
    AFRCDPerson* cdPerson = [NSEntityDescription insertNewObjectForEntityForName:kAFRPersonEntityName inManagedObjectContext:managedContext];
    [person toCDPersion:cdPerson];
    
    [self saveContext:managedContext];
    
    return YES;
}

- (BOOL)updatePersonFeatureData:(NSArray *)arrayPersons
{
    if(nil == arrayPersons)
        return NO;
    
    NSManagedObjectContext *managedContext = self.managedObjectContext;
    NSFetchRequest* request = [AFRCDPerson fetchRequest];
    
    for (AFRPerson *person in arrayPersons) {
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"personID==%d", person.Id];
        [request setPredicate:predicate];
        
        NSArray *arrayMatchPersons = [managedContext executeFetchRequest:request error:nil];
        for (AFRCDPerson *cdPerson in arrayMatchPersons) {
            cdPerson.faceFeatureData = person.faceFeatureData;
        }
    }
    
    [self saveContext:managedContext];
    return YES;
}


#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.arcsoft.Core_data_persistence" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:kAFRModelName withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"AFRModel.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"AFR_DB_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext:(NSManagedObjectContext*)managedContext {
    if (managedContext != nil) {
        NSError *error = nil;
        if ([managedContext hasChanges] && ![managedContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
#if DEBUG
            abort();
#endif
        }
    }
}

@end
