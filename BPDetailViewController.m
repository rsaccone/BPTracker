//
//  BPDetailViewController.m
//  BPTracker
//
//  Created by Robert Saccone on 4/27/14.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "BPDetailViewController.h"

#import "BloodPressureReading.h"
#import "BPReadingDetailViewController.h"
#import "BPReadingSelectionViewController.h"

@interface BPDetailViewController () <BPReadingDetailViewControllerDelegate>

- (void)addCompletionBlockToDictionary:(ReadingDismissedBlock)readingDismissedBlock forViewController:(BPReadingDetailViewController *)bpReadingDetailViewCtrlr;
- (ReadingDismissedBlock)removeCompletionBlockFromDictionary:(BPReadingDetailViewController *)bpReadingDetailViewCtrlr;

@property(nonatomic, assign) BOOL editingNewReading;
@property(nonatomic, strong) NSMutableDictionary *viewCtrlrToCompletionBlocks;

@end

@implementation BPDetailViewController

@synthesize currBPReadingDetailViewController;
@synthesize currBPReading;
@synthesize delegate;

- (id)init
{
    self = [super initWithNibName:@"BPDetailViewController" bundle:nil];

    if (self)
    {
        // Custom initialization
        _editingNewReading = NO;
        
        _viewCtrlrToCompletionBlocks = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    // Dispose of any resources that can be recreated.
}

#pragma mark - ReadingDismissedBlock Management

- (void)addCompletionBlockToDictionary:(ReadingDismissedBlock)readingDismissedBlock forViewController:(BPReadingDetailViewController *)bpReadingDetailViewCtrlr
{
    ReadingDismissedBlock copy = [readingDismissedBlock copy];
    [[self viewCtrlrToCompletionBlocks] setObject:copy forKey:[NSValue valueWithNonretainedObject:bpReadingDetailViewCtrlr]];
}

- (ReadingDismissedBlock)removeCompletionBlockFromDictionary:(BPReadingDetailViewController *)bpReadingDetailViewCtrlr
{
    NSValue *key = [NSValue valueWithNonretainedObject:bpReadingDetailViewCtrlr];
    
    ReadingDismissedBlock completionBlock = self.viewCtrlrToCompletionBlocks[key];
    
    if (completionBlock != nil)
    {
        [self.viewCtrlrToCompletionBlocks removeObjectForKey:key];
    }
    
    return completionBlock;
}

#pragma mark - BPReadingSlectionViewController methods

- (void)selectedReading:(BloodPressureReading *)bpReading
             completion:(ReadingDismissedBlock)readingDismissed;
{
    BPReadingDetailViewController *bpReadingDetailViewCtrlr =
    [[BPReadingDetailViewController alloc] init:bpReading newReading:NO setDefaultsFromReading:YES viewControllerDelegate:self];
    
    if (readingDismissed != nil)
    {
        [self addCompletionBlockToDictionary:readingDismissed forViewController:bpReadingDetailViewCtrlr];
    }
    
    [bpReadingDetailViewCtrlr setHidesBottomBarWhenPushed:YES];
    
    // Pop off the top leve reading, if any.
    [self popTopLevelReading];
    
    [self.navigationController pushViewController:bpReadingDetailViewCtrlr animated:NO];
}

- (void)editNewReading:(BloodPressureReading *)bpReading
            completion:(ReadingDismissedBlock)readingDismissed;
{
    if (!_editingNewReading && (bpReading != nil))
    {
        BPReadingDetailViewController *bpReadingDetailViewCtrlr =
        [[BPReadingDetailViewController alloc] init:bpReading newReading:YES setDefaultsFromReading:NO viewControllerDelegate:self];
        
        [bpReadingDetailViewCtrlr setHidesBottomBarWhenPushed:YES];
        
        if (readingDismissed != nil)
        {
            [self addCompletionBlockToDictionary:readingDismissed forViewController:bpReadingDetailViewCtrlr];
        }

        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:bpReadingDetailViewCtrlr];
        
        UINavigationController *topLevelNavigationController = self.navigationController;
        
        topLevelNavigationController.definesPresentationContext = YES;
        
        navController.modalPresentationStyle = UIModalPresentationCurrentContext; //UIModalPresentationPageSheet;
        
        [topLevelNavigationController presentViewController:navController animated:YES completion:NULL];
        
        self.editingNewReading = YES;
    }
}

- (void)popTopLevelReading
{
    BPReadingDetailViewController *topBPReadingDetailVC = self.currBPReadingDetailViewController;
    
    if (topBPReadingDetailVC != nil)
    {
        // If working on editing a new reading than cancel edit mode.
        // This will ensure that the readingDismissedBlock for the
        // view controller will be cleaned up correctly.
        if (topBPReadingDetailVC.newReading)
        {
            // Canceling edit mode will take care of cleaning up the
            // blockentry in the
            [topBPReadingDetailVC cancelEditMode];
        }
        else
        {
            (void)[self removeCompletionBlockFromDictionary:topBPReadingDetailVC];
        }
    }
    
    [self.navigationController popToRootViewControllerAnimated:NO];
}

#pragma mark - BPReadingDetailViewControllerDegate implementation

- (void)modeChanged:(BOOL) editing
{
    id<BPReadingSelectionViewControllerDelegate> del = self.delegate;
    
    if (del != nil)
    {
        [del modeChanged:editing];
    }
    
}

- (BOOL)doneUpdatingBloodPressureReading:(BPReadingDetailViewController *)viewController
                    bloodPressureReading:(BloodPressureReading *)reading
                                   saved:(BOOL)saved
                              newReading:(BOOL)newReading
{
    ReadingDismissedBlock readingDismissed = [self removeCompletionBlockFromDictionary:viewController];
    
    if (readingDismissed != nil)
    {
        // Invoke the block.
        readingDismissed(saved);
    }
    
    if (newReading)
    {
        [self dismissViewControllerAnimated:YES completion:NULL];
        
        self.editingNewReading = NO;
        
        return YES;
    }
    
    return NO;
}

#pragma mark - currBPReading Property

- (BloodPressureReading *)currBPReading
{
    BPReadingDetailViewController *currDetailController = self.currBPReadingDetailViewController;
    
    if (currDetailController != nil)
    {
        return currDetailController.bloodPressureReading;
    }
    
    return nil;
}

- (BPReadingDetailViewController *)currBPReadingDetailViewController
{
    UIViewController *topVC = [self.navigationController topViewController];
    
    if ((topVC != nil) && ([topVC isKindOfClass:[BPReadingDetailViewController class]]))
    {
        return (BPReadingDetailViewController *)topVC;
    }
    
    return nil;
}

#pragma mark - UISplitViewControllerDelegate

- (void)splitViewController:(UISplitViewController *)svc
          popoverController:(UIPopoverController *)pc
  willPresentViewController:(UIViewController *)aViewController
{
    
}

- (BOOL)splitViewController:(UISplitViewController *)svc
   shouldHideViewController:(UIViewController *)vc
              inOrientation:(UIInterfaceOrientation)orientation
{
    return NO;
}

- (void)splitViewController:(UISplitViewController *)svc
     willHideViewController:(UIViewController *)aViewController
          withBarButtonItem:(UIBarButtonItem *)barButtonItem
       forPopoverController:(UIPopoverController *)pc
{
    barButtonItem.title = @"Readings";
    
    // Place the bar button on the left side of the nav. item
    self.navigationItem.leftBarButtonItem = barButtonItem;
}

- (void)splitViewController:(UISplitViewController *)svc
     willShowViewController:(UIViewController *)aViewController
  invalidatingBarButtonItem:(UIBarButtonItem *)button
{
    // Remove the bar button item from the navigation item.
    // Double check that it is correct even though we know it is.
    if (button == self.navigationItem.leftBarButtonItem)
    {
        self.navigationItem.leftBarButtonItem = nil;
    }
}

@end
