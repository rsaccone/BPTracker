//
//  BPDataImporterBase.m
//  BPTracker
//
//  Created by Robert Saccone on 10/9/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "BPDataImporterBase.h"
#import "BloodPressureDataAnalyzer.h"

typedef enum Import_State
{
    NotStarted = 0,
    Importing,
    Error,
    RolledBack,
    Committed,
    CommitFailure,
    NumStates
} ImportState;

typedef enum Import_Action
{
    Begin = 0,
    Import,
    Commit,
    Rollback,
    NumActions
} ImportAction;

const int BatchSizeDefault = 100;

NSString *const ImportStateNames[] =
{
    @"NotStarted",
    @"Importing",
    @"Error",
    @"RolledBack",
    @"Committed",
    @"CommitFailure"
};

NSString *const ActionNames[] =
{
    @"Begin",
    @"Import",
    @"Commit",
    @"Rollback"
};

const ImportState StateActionTransitions[][NumActions] =
{
    //                  A C T I O N S
    // Begin        // Import   // Commit   // Rollback      S T A T E S
    {  Importing,   Error,      Error,      Error  },       // NotStarted
    {  Error,       Importing,  Committed,  RolledBack },   // Importing
    {  Error,       Error,      Error,      Error  },       // Error
    {  Importing,   Error,      Error,      Error },        // RolledBack
    {  Importing,   Error,      Error,      Error },        // Commited
    {  Error,       Error,      Error,      RolledBack },   // CommitFailure
};

@interface BPDataImporterBase ()

- (void)throwNotImplException:(NSString *)methodName;

@end

@implementation BPDataImporterBase
{
@private
    NSManagedObjectContext *managedObjectContext_;
    NSMutableDictionary *dateToReading_;
    NSMutableArray *importReadingDates_;
    NSDateFormatter *dateFormatter_;
    ImportState currState_;
    NSUInteger newReadingsImportedCount_;
    NSUInteger readingsUpdatedCount_;
}

@synthesize managedObjectContext = managedObjectContext_;
@synthesize dateToReading = dateToReading_;
@synthesize importReadingDates = importReadingDates_;
@synthesize dateFormatter = dateFormatter_;
@synthesize newReadingsImportedCount = newReadingsImportedCount_;
@synthesize readingsUpdatedCount = readingsUpdatedCount_;


- (void)raiseInvalidStateException:(ImportState)state attemptedAction:(ImportAction)action
{
    NSAssert(state < NumStates, @"state >= NumStates");
    NSAssert(action < NumActions, @"action >= NumActions");
    
    NSString *actionName = ActionNames[action];
    NSString *importStateName = ImportStateNames[state];
    
    NSString *reason = [NSString stringWithFormat:@"Action (%@) is invalid in state (%@)", actionName, importStateName];
    NSException* myException = [NSException
                                exceptionWithName:NSInternalInconsistencyException
                                reason:reason
                                userInfo:nil];
    @throw myException;
}

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc
                     batchSizeHint:(NSUInteger)batchHint
{
    if (moc == nil)
    {
        NSLog(@"ExportDataViewController: nil managedObjectContext passed!");
        NSAssert(moc != nil, @"managedObjectContext is nil!");
        
        
        return nil;
    }
    
    self = [super init];
    
    if (self != nil)
    {
        currState_ = NotStarted;
        managedObjectContext_ = moc;
        managedObjectContext_.undoManager = nil;
        newReadingsImportedCount_ = 0;
        readingsUpdatedCount_ = 0;
        
        if (batchHint == 0)
        {
            batchHint = BatchSizeDefault;
        }
        
        importReadingDates_ = [[NSMutableArray alloc] initWithCapacity:batchHint];
        
        if (importReadingDates_ == nil)
        {
            return nil;
        }
        
        dateToReading_ = [[NSMutableDictionary alloc] initWithCapacity:batchHint];
        
        if (dateToReading_ == nil)
        {
            return nil;
        }
    }
    
    return self;
}

- (void)begin
{
    ImportState nextState = StateActionTransitions[currState_][Begin];
    
    if (nextState == Error)
    {
        [self raiseInvalidStateException:currState_ attemptedAction:Begin];
    }
    
    self.newReadingsImportedCount = 0;
    self.readingsUpdatedCount = 0;
    
    [self beginImpl];
     
    currState_ = Importing;
}

- (BloodPressureReading *)findPressureReading:(BloodPressureReading *)match
{
    return nil;
}

- (BOOL)import:(BloodPressureReading *)reading error:(NSError * __autoreleasing *)error;
{
    ImportState nextState = StateActionTransitions[currState_][Import];

    if (nextState == Error)
    {
        [self raiseInvalidStateException:currState_ attemptedAction:Import];
    }
    
    if (reading == nil)
    {
        return NO;
    }
    
    BPValidationResult valResult = [[BloodPressureDataAnalyzer instance] validateComponents:reading];
    
    if (valResult)
    {
        // Extend the method to return an NSError with information for the user.
        return NO;
    }
    
    BOOL result = [self importImpl:reading error:error];
    
    if (result)
    {
        currState_ = nextState;
    }
    
    return result;
}

- (BOOL)commit:(NSError * __autoreleasing *)error
{
    ImportState nextState = StateActionTransitions[currState_][Commit];
    
    if (nextState == Error)
    {
        [self raiseInvalidStateException:currState_ attemptedAction:Commit];
    }
    
    BOOL result = [self commitImpl:error];

    if (result)
    {
        currState_ = nextState;
    }
    else
    {
        currState_ = CommitFailure;
    }
    
    return result;
}

- (void)rollback
{
    ImportState nextState = StateActionTransitions[currState_][Rollback];
    
    if (nextState == Error)
    {
        [self raiseInvalidStateException:currState_ attemptedAction:Import];
    }
    
    
    [self rollbackImpl];
    
    currState_ = nextState;
}

- (void)throwNotImplException:(NSString *)methodName
{
    NSString *exceptMsg = [NSString stringWithFormat:@"Method call %@ NOT implemented!", methodName];
    
    NSException* myException = [NSException
                                exceptionWithName:NSGenericException
                                reason:exceptMsg
                                userInfo:nil];
    @throw myException;
}

- (void)beginImpl
{
    [self throwNotImplException:NSStringFromSelector(_cmd)];
}

- (BOOL)importImpl:(BloodPressureReading *)reading error:(NSError * __autoreleasing *)error
{
    [self throwNotImplException:NSStringFromSelector(_cmd)];
    
    return NO;
}

- (BOOL)commitImpl:(NSError * __autoreleasing *)error
{
    [self throwNotImplException:NSStringFromSelector(_cmd)];
    
    return NO;
}

- (void)rollbackImpl
{
    [self throwNotImplException:NSStringFromSelector(_cmd)];
}

#pragma mark - Date Formatter property

- (NSDateFormatter *)dateFormatter
{
    if (dateFormatter_ == nil)
    {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
        dateFormatter_ = dateFormatter;
    }
    
    return dateFormatter_;
}

@end

