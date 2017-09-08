//
//  URLHandler.m
//  BPTracker
//
//  Created by Robert Saccone on 1/31/13.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "URLHandler.h"

#import <SLexUtil/ActivityAlert.h>
#import <SLexUtil/ErrorMsgBuilder.h>
#import <SLexUtil/UIAlertView+Blocks.h>

#import "BPImportOrchestrator.h"

@interface URLHandler () <BPImportOrchestratorDelegate>

@property(nonatomic, copy) NSURL *url;
@property(nonatomic, strong) NSManagedObjectContext *parentMOC;
@property(nonatomic, assign) NSUInteger recordsImportedCount;
@property(nonatomic, assign) NSUInteger recordsUpdatedCount;
@property(nonatomic, strong) NSError *error;
@property(nonatomic, strong) BPImportOrchestrator *orchestrator;
@property(nonatomic, weak) id<URLHandlerDelegate> urlHandlerDelegate;
@property(nonatomic, strong) ActivityAlert *importProgressAlert;

@end

@implementation URLHandler
{
@private
    NSURL *url_;
    NSManagedObjectContext *parentMOC_;
    NSError *error;
    BPImportOrchestrator *orchestrator_;
    BOOL finished_;
    BOOL success_;
    BOOL canceled_;
}

@synthesize url = url_;
@synthesize parentMOC = parentMOC_;
@synthesize error = error_;
@synthesize orchestrator = orchestrator_;
@synthesize urlHandlerDelegate;
@synthesize finished = finished_;
@synthesize canceled = canceled_;
@synthesize recordsImportedCount;
@synthesize recordsUpdatedCount;

- (id)initWithURL:(NSURL *)url parentManagedObjectContext:(NSManagedObjectContext *)moc initError:(NSError * __autoreleasing *)initError
{
    self = [super init];
    
    if (self != nil)
    {
        url_ = [url copy];
        parentMOC_ = moc;
        orchestrator_ = [[BPImportOrchestrator alloc] initWithCSVFile:url.path parentManagedObjectContext:moc notificationDelegate:self error:initError];
        
        if (orchestrator_ == nil)
        {
            self = nil;
        }
    }
    
    return self;
}

- (void)begin:(id<URLHandlerDelegate>)delegate;
{
    self.urlHandlerDelegate = delegate;
    [ActivityAlert presentWithText:NSLocalizedString(@"IMPORT_READINGS_ACTIVITY_ALERT_TITLE", nil)];
    [self.orchestrator beginImport];
}

#pragma mark - BPImportOrchestratorDelegate Protocol methods

static void runOnMainQueue(void (^block)(void))
{
    if ([NSThread isMainThread])
    {
        block();
    }
    else
    {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

static NSString *buildImportMessage(NSUInteger importCount, NSUInteger updateCount, BOOL canceled)
{
    NSMutableString *msg = [[NSMutableString alloc] init];
    
    if (canceled)
    {
        [msg appendString:NSLocalizedString(@"IMPORT_READINGS_CANCELED_MSG", nil)];
        [msg appendString:@"\n"];
    }
    
    if (importCount == 1)
    {
        [msg appendString:NSLocalizedString(@"IMPORT_READING_ACTIVITY_ALERT_MSG_READING_IMPORTED", nil)];
    }
    else if (importCount > 1)
    {
        [msg appendFormat:NSLocalizedString(@"IMPORT_READING_ACTIVITY_ALERT_MSG_READINGS_IMPORTED", nil), importCount];
    }

    if (updateCount != 0)
    {   if (importCount != 0)
        {
            [msg appendString:@"\n"];
        }
        
        if (updateCount == 1)
        {
            [msg appendString:NSLocalizedString(@"IMPORT_READING_ACTIVITY_ALERT_MSG_READING_UPDATED", nil)];
        }
        else
        {
            [msg appendFormat:NSLocalizedString(@"IMPORT_READING_ACTIVITY_ALERT_MSG_READINGS_UPDATED", nil), updateCount];
        }
    }
    
    return msg;
}

- (void)importOrchestrator:(BPImportOrchestrator *)importOrch
        numRecordsImported:(NSUInteger)importCount
          numRecordsUpdated:(NSUInteger)updateCount
{
    NSLog(@"Import: imported records count %lu, updated records count %lu", (unsigned long)importCount, (unsigned long)updateCount);
    
    self.recordsImportedCount = importCount;
    
    URLHandler * __weak weakSelf = self;
    
    [self.parentMOC performBlock:^()
     {
         if ([weakSelf.parentMOC hasChanges])
         {
             [weakSelf.parentMOC save:nil];
         }
     }];
    
    runOnMainQueue(^()
    {
        [ActivityAlert setMessage:buildImportMessage(importCount, updateCount, NO)];
    });
}

- (void)importOrchestrator:(BPImportOrchestrator *)importOrch
           failedWithError:(NSError *)theError
      totalRecordsImported:(NSUInteger)recordsImported
       totalRecordsUpdated:(NSUInteger)recordsUpdated
{
    self.error = theError;
    NSLog(@"Imported failed with error %@", [theError localizedDescription ]);
    
    success_ = NO;
    canceled_ = NO;
    finished_ = YES;
    
    runOnMainQueue(^()
    {
       [ActivityAlert dismiss];
        
        //        NSString *msg = [ErrorMsgBuilder build:NSLocalizedString(@"IMPORT_READINGS_FAILURE_MSG", nil) error:theError];
        NSString *msg = [ErrorMsgBuilder build:nil error:theError];
        
        if (recordsImported || recordsUpdated)
        {
            msg = [NSString stringWithFormat:@"%@\n%@", msg,
                   buildImportMessage(recordsImported, recordsUpdated, NO)];
        }
        
        // Put up a message so the user knows the outcome.
        UIAlertView * alertView
            = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"IMPORT_READINGS_FAILURE_ALERT_TITLE", nil)
                                         message:msg
                              clickedButtonBlock:^(UIAlertView *alertView, NSInteger buttonIndex)
                                                   {
                                                       if (self.urlHandlerDelegate)
                                                       {
                                                           [self.urlHandlerDelegate handlerCompletion:self];
                                                       }
                                                   }
                               cancelButtonTitle:NSLocalizedString(@"OK_BUTTON_LABEL", nil)
                               otherButtonTitles:nil];
        [alertView show];
    });
}

- (void)importOrchestrator:(BPImportOrchestrator *)importOrch
      totalRecordsImported:(NSUInteger)recordsImported
       totalRecordsUpdated:(NSUInteger)recordsUpdated
               wasCanceled:(BOOL)canceled
{
    NSLog(@"Import completed, Record imported %lu, records updated %lu, Canceled is %@",
          (unsigned long)recordsImported, (unsigned long)recordsUpdated, canceled ? @"true" : @"false");

    canceled_ = canceled;
    success_ = canceled ? NO : YES;
    finished_ = YES;
    
    NSString *msg = buildImportMessage(recordsImported, recordsUpdated, canceled);

    NSString *title = nil;
    
    if (!canceled)
    {
        title = NSLocalizedString(@"IMPORT_READINGS_COMPLETE_TITLE", nil);
    }
    else
    {
        title = NSLocalizedString(@"IMPORT_READINGS_CANCELED_MSG", nil);
    }
    
    runOnMainQueue(^()
    {
        [ActivityAlert dismiss];
        
        // Put up a message so the user knows the outcome.
        UIAlertView * alertView
            = [[UIAlertView alloc] initWithTitle:title
                                         message:msg
                              clickedButtonBlock:^(UIAlertView *alertView, NSInteger buttonIndex)
                               {
                                   if (self.urlHandlerDelegate)
                                   {
                                       [self.urlHandlerDelegate handlerCompletion:self];
                                   }
                               }
                               cancelButtonTitle:NSLocalizedString(@"OK_BUTTON_LABEL", nil)
                               otherButtonTitles:nil];
        [alertView show];
    });
}

@end
