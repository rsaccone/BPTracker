//
//  BPReadingListViewController.m
//  BPTracker
//
//  Created by Robert Saccone on 1/25/11.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "BPReadingListViewController.h"

#import <SLexUtil/NumericUtil.h>
#import <SLexUtil/PlatformHelper.h>
#import "BloodPressureReading.h"
#import "BloodPressureDataAnalyzer.h"
#import "BPDataStoreEvents.h"
#import "BPReadingDetailViewController.h"
#import "BPReadingSelectionViewController.h"
#import "BPTReadingTableViewCell.h"
#import "ExportDataViewController.h"
#import "FetchedResultsControllerFactory.h"
#import "TableViewUserDefaultsHelper.h"
#import "UserSettingKeys.h"

enum ImageIndex
{
    NormalIndex = 0,
    PreHypertensionImageIndex,
    HypertensionStage1ImageIndex,
    HypertensionStage2ImageIndex,
    HypertensionStage3ImageIndex,
    ImageIndexCount
};

// Class extension using anonymous category to hide
// certain properties and methods from consumers
// of the class.
@interface BPReadingListViewController () <BPReadingDetailViewControllerDelegate, BPReadingSelectionViewControllerDelegate, UIPopoverControllerDelegate>

typedef void (^DispatchQueueBlock)(void);

- (DispatchQueueBlock)getAutoSelectReadingFromIdBlock:(NSManagedObjectID *)objectId;
- (DispatchQueueBlock)getSyncTableViewSelectionWithDetailViewBlock;

- (ReadingDismissedBlock)readingDismissedBlock:(BloodPressureReading *)bpReading
                                  isNewReading:(BOOL)newReading
                          managedObjectContext:(NSManagedObjectContext *)moc;

- (DoneUpdatingBloodPressureReadingBlock)doneUpdatingReadingBlock:(BloodPressureReading*)bpReading
                                                     isNewReading:(BOOL)newReading
                                             managedObjectContext:(NSManagedObjectContext *)moc;

- (void)setupNavigationItem:(BOOL)editingAllowed editing:(BOOL)editing;
- (void)configureCell:(BPTReadingTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (UIColor *)mapBloodPresureCategoryToColor:(enum BloodPressureCategory)category;
- (void)loadBPImageLevels;
- (void)selectAndScrollIntoView:(NSIndexPath *)selection;
- (void)selectReadingAtIndex:(NSIndexPath *)indexPath;
- (NSString *)buildFetchedResultsControllerCacheName;
- (void)createNewBloodPressureReading:(id)sender;
- (void)sortReadings:(id)sender;
- (void)exportBloodPressureReadings:(id)sender;

@property(nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property(nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property(nonatomic, strong) NSMutableArray *bpLevelImages;
@property(nonatomic, strong) NSArray *sortAscendingRightButtonsArray;
@property(nonatomic, strong) NSArray *sortDescendingRightButtonsArray;
@property(nonatomic, strong) NSIndexPath *indexOfEditItem;
@property(nonatomic, strong) NSDateFormatter *shortStyleDateTimeFormatter;
@property(nonatomic, strong) TableViewUserDefaultsHelper *tableViewUserDefaultsHelper;
@property(nonatomic, strong) UIPopoverController *bpReadingDetailPopover;
@property(nonatomic, strong) UIPopoverController *exportDataPopover;
@property(nonatomic, strong) NSManagedObjectContext *bpReadingDetailPopoverMoc;
@property(nonatomic, assign) BOOL restoreSelectionFromDefaults;
@property(nonatomic, assign) BOOL sortAscending;
@property(nonatomic, assign, getter = isIdiomPad) BOOL idiomPad;

@end


@implementation BPReadingListViewController
{
@private
    id<BPReadingSelectionViewController> __weak readingSelectionViewController_;
	NSFetchedResultsController *fetchedResultsController_;
	NSManagedObjectContext *managedObjectContext_;
    NSMutableArray *bpLevelImages_;
    NSArray *sortAscendingRightButtonsArray_;
    NSArray *sortDescendingRightButtonsArray_;
    BloodPressureReading *currBloodPressureReading_;
    NSDateFormatter *shortStyleDateTimeFormatter_;
    TableViewUserDefaultsHelper *tableViewUserDefaultsHelper_;
    BOOL restoreSelectionFromDefaults_;
    BOOL sortAscending_;
    BOOL idiomPad_;
}

@synthesize readingSelectionViewController=readingSelectionViewController_;
@synthesize bpLevelImages=bpLevelImages_;
@synthesize indexOfEditItem;
@synthesize fetchedResultsController = fetchedResultsController_;
@synthesize managedObjectContext=managedObjectContext_;
@synthesize sortAscendingRightButtonsArray = sortAscendingRightButtonsArray_;
@synthesize sortDescendingRightButtonsArray = sortDescendingRightButtonsArray_;
@synthesize shortStyleDateTimeFormatter = shortStyleDateTimeFormatter_;
@synthesize tableViewUserDefaultsHelper = tableViewUserDefaultsHelper_;
@synthesize restoreSelectionFromDefaults = restoreSelectionFromDefaults_;
@synthesize sortAscending = sortAscending_;
@synthesize idiomPad = idiomPad_;

static NSString *const bpTableViewCellName = @"BPTReadingTableViewCell";

static enum ImageIndex mapBloodPressureCategoryToImageIndex(enum BloodPressureCategory category)
{
    switch (category)
    {
        case Low:
        case Low_Normal:
        case Normal:
            return NormalIndex;
            
        case Prehypertension_Borderline:
            return PreHypertensionImageIndex;
            
        case Stage1_Mild_Hypertension:
        case Stage2_Moderate_Hypertension:
            return HypertensionStage1ImageIndex;
            
        case Stage3_Severe_Hypertension:
        case Stage4_Very_Severe_Hypertension:
            return HypertensionStage2ImageIndex;
            
        default:
            NSCAssert1(NO, @"Unrecognized blood pressure category <%d>", category);
            return NormalIndex;
    }
}

#pragma mark - View lifecycle

static NSString *bpImageNames[] = 
    { 
        @"SysGreen_DiaGreen", 
        @"SysGreen_DiaYellow", 
        @"SysGreen_DiaOrange", 
        @"SysGreen_DiaRed",
        @"SysGreen_DiaDeepRed",
        @"SysYellow_DiaGreen",
        @"SysYellow_DiaYellow", 
        @"SysYellow_DiaOrange", 
        @"SysYellow_DiaRed",
        @"SysYellow_DiaDeepRed",
        @"SysOrange_DiaGreen",
        @"SysOrange_DiaYellow", 
        @"SysOrange_DiaOrange", 
        @"SysOrange_DiaRed",
        @"SysOrange_DiaDeepRed",
        @"SysRed_DiaGreen",
        @"SysRed_DiaYellow", 
        @"SysRed_DiaOrange", 
        @"SysRed_DiaRed",
        @"SysRed_DiaDeepRed",
        @"SysDeepRed_DiaGreen",
        @"SysDeepRed_DiaYellow",
        @"SysDeepRed_DiaOrange",
        @"SysDeepRed_DiaRed",
        @"SysDeepRed_DiaDeepRed"
    };
        

- (void)loadBPImageLevels
{
    NSUInteger imageArraySize = (NSUInteger)COUNT_OF(bpImageNames);
    
    NSMutableArray *bpLevelImages = [NSMutableArray arrayWithCapacity:imageArraySize];
     
     for (NSUInteger index = 0; index < imageArraySize; ++index)
     {
         UIImage *image = [UIImage imageWithContentsOfFile: [[NSBundle mainBundle] pathForResource:bpImageNames[index] ofType:@"png"]];
         
         NSAssert1(image != nil, @"BP Image {0}.png could not be loaded.", bpImageNames[index]);
         
         [bpLevelImages addObject:image];
     }
    
    [self setBpLevelImages:bpLevelImages];
}

-(id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    if (managedObjectContext == nil)
    {
        NSLog(@"BPReadingListViewController: nil managedObjectContext passed!");
        NSAssert(managedObjectContext != nil, @"managedObjectContext is nil!");
        
        
        return nil;
    }
    
    // call the superclasses dedicated initializer.
    NSString *nibName = @"BPReadingListViewController";
    
    self = [super initWithNibName:nibName bundle:nil];
    
    if (self != nil)
    {
        managedObjectContext_ = managedObjectContext;
        restoreSelectionFromDefaults_ = YES;
        
        idiomPad_ = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
        
        NSArray *keyNames = [NSArray arrayWithObjects:bpTableViewSectionSelectedKey, bpTableViewRowSelectedKey, bpTableViewEditSelectedKey, bpTableViewSortAscendingKey, nil];
        
        tableViewUserDefaultsHelper_ = [[TableViewUserDefaultsHelper alloc] initWithKeyNames:keyNames];

        UITabBarItem *tbi = [self tabBarItem];
        
        [tbi setTitle:NSLocalizedString(@"BP_READINGS_LIST_TITLE", @"Blood Pressure Readings")];
        UIImage *image = [UIImage imageNamed:@"notepad.png"];
        [tbi setImage:image];
        
        [self setupNavigationItem:YES editing:NO];
    }
    
    return self;
}

-(id)init
{
    return [self initWithManagedObjectContext:nil];
}

// The designated initializer of the base.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
{
    return [self init];
}

- (void)setupNavigationItem:(BOOL)editingAllowed editing:(BOOL)editing;
{
    UINavigationItem *navItem = self.navigationItem;
    
    if (!editing)
    {
        // Add a '+' bar button for adding a new bp reading.
        UIBarButtonItem *addNewBPReadingItem = [[UIBarButtonItem alloc]
                                                initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                target:self
                                                action:@selector(createNewBloodPressureReading:)];

        if (!self.sortAscendingRightButtonsArray)
        {

            UIImage *sortAscImg = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"arrow-up" ofType:@"png"]];

            UIBarButtonItem *sortAscendingItem = [[UIBarButtonItem alloc]
                                                  initWithImage:sortAscImg
                                                  style:UIBarButtonItemStyleBordered
                                                  target:self
                                                  action:@selector(sortReadings:)];

            self.sortAscendingRightButtonsArray = [NSArray arrayWithObjects:addNewBPReadingItem, sortAscendingItem, nil];
        }

        if (!self.sortDescendingRightButtonsArray)
        {
            UIImage *sortDescImg = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"arrow-down" ofType:@"png"]];
            
            UIBarButtonItem *sortDescendingItem = [[UIBarButtonItem alloc]
                                                   initWithImage:sortDescImg
                                                   style:UIBarButtonItemStyleBordered
                                                   target:self
                                                   action:@selector(sortReadings:)];
            
            self.sortDescendingRightButtonsArray = [NSArray arrayWithObjects:addNewBPReadingItem, sortDescendingItem, nil];
        }
    
        UIBarButtonItem *exportButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                      target:self
                                                                                      action:@selector(exportBloodPressureReadings:)];
        
        navItem.leftBarButtonItems = [NSArray arrayWithObjects:self.editButtonItem, exportButton, nil];
     
        self.editButtonItem.enabled = editingAllowed;
        
        self.sortAscending = [self.tableViewUserDefaultsHelper getSortAscendingFlag];
        
        if (self.sortAscending)
        {
            navItem.rightBarButtonItems = self.sortAscendingRightButtonsArray;
        }
        else
        {
            navItem.rightBarButtonItems = self.sortDescendingRightButtonsArray;
        }
    }
    else
    {
        if (editingAllowed)
        {
            navItem.leftBarButtonItems = [NSArray arrayWithObjects:self.editButtonItem, nil];
            self.editButtonItem.enabled = YES;
        }
        else
        {
            navItem.leftBarButtonItems = nil;
        }
        
        navItem.rightBarButtonItems = nil;
    }
}

- (void)viewDidLoad 
{
    [super viewDidLoad];
    self.tableView.autoresizingMask = UIViewAutoresizingNone; //UIViewAutoresizingFlexibleHeight;
//    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.automaticallyAdjustsScrollViewInsets = YES;
    
    self.title = NSLocalizedString(@"BP_READINGS_LIST_TITLE", @"Blood Pressure Readings");
    
    // Load the NIB file that contains our custom tableview cell.
    UINib *nib = [UINib nibWithNibName:bpTableViewCellName bundle:nil];
    
    // Register the NIB.
    [self.tableView registerNib:nib forCellReuseIdentifier:bpTableViewCellName];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];

    self.shortStyleDateTimeFormatter = dateFormatter;

    [self loadBPImageLevels];
    
	NSError * __autoreleasing error = nil;
	if (![[self fetchedResultsController] performFetch:&error])
	{
		/*
		 Replace this implementation with code to handle the error appropriately.
		 
		 abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
		 */
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}
    
    // When running in a split view controller turn off the ability to pop
    // the view by swiping left.
    if (self.splitViewController)
    {
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
        {
            self.navigationController.interactivePopGestureRecognizer.enabled = NO;
        }
    }
}

- (void)selectAndScrollIntoView:(NSIndexPath *)selection;
{
    NSAssert(selection != nil, @"selection == nil");
    
    UITableView *tv = self.tableView;
    [tv selectRowAtIndexPath:selection animated:NO scrollPosition:UITableViewScrollPositionNone];
    [tv scrollToRowAtIndexPath:selection atScrollPosition:UITableViewScrollPositionNone animated:YES];
}

- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
    
    if (self.indexOfEditItem != nil)
    {
        [self selectAndScrollIntoView:self.indexOfEditItem];
        
        self.indexOfEditItem = nil;
        
        [self.tableViewUserDefaultsHelper saveEditingFlag:NO];
    }
    else if (self.restoreSelectionFromDefaults)
    {
        self.restoreSelectionFromDefaults = NO;
        
        NSIndexPath *selection = [self.tableViewUserDefaultsHelper getSavedSelection];
        
        if (selection != nil)
        {
            // Check that the stored index path is still vaild since an invalid one
            // will cause the objectAtIndexPath method to raise an exeception.
            NSInteger selectedSection = selection.section;
            
            if (selectedSection < [self numberOfSectionsInTableView:self.tableView])
            {
                NSInteger selectedRow = selection.row;
                
                if (selectedRow < [self tableView:self.tableView numberOfRowsInSection:selectedSection])
                {
                    if ([[self fetchedResultsController] objectAtIndexPath:selection] !=nil)
                    {
                        [self selectAndScrollIntoView:selection];
                    
                        if ([self.tableViewUserDefaultsHelper getSavedEditingFlag])
                        {
                            [self tableView:self.tableView didSelectRowAtIndexPath:selection];
                        }
                    }
                }
            }
        }
    }
}

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

#pragma mark - Custom Property Methods

- (void)setReadingSelectionViewController:(id<BPReadingSelectionViewController>)readingSelectionViewController
{
    if (readingSelectionViewController != readingSelectionViewController_)
    {
        if (readingSelectionViewController_ != nil)
        {
            readingSelectionViewController_.delegate = nil;
        }
        
        readingSelectionViewController_ = readingSelectionViewController;
        
        if (readingSelectionViewController_ != nil)
        {
            readingSelectionViewController_.delegate = self;
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    NSInteger count = [[[self fetchedResultsController] sections] count];
    
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    // Return the number of rows in the section.
    NSArray *sections = [[self fetchedResultsController] sections];
    
    NSUInteger count = sections.count;
    
    if (count == 0)
    {
        NSLog(@"numberOfRowsInSection: sections count is 0, returning 0");
        return 0;
    }
    
    id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
    NSUInteger numberOfObjects = [sectionInfo numberOfObjects];
    NSLog(@"numberOfRowsInSection %lu", (unsigned long)numberOfObjects);
    
    return numberOfObjects;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
    NSArray *sections = [[self fetchedResultsController] sections];
    
    NSUInteger count = sections.count;
    
    if (count == 0)
        return nil;

	id <NSFetchedResultsSectionInfo> theSection = [sections objectAtIndex:section];
    
    /*
     Section information derives from an event's sectionIdentifier, which is a string representing the number (year * 1000) + month.
     To display the section title, convert the year and month components to a string representation.
     */
    static NSArray *monthSymbols = nil;
    
    if (!monthSymbols) 
    {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setCalendar:[NSCalendar currentCalendar]];
        monthSymbols = [formatter monthSymbols];
    }
    
    NSInteger numericSection = [[theSection name] integerValue];
    
	NSInteger year = numericSection / 1000;
	NSInteger month = numericSection - (year * 1000);
	
	NSString *titleString = [NSString stringWithFormat:@"%@ %ld", [monthSymbols objectAtIndex:month - 1], (long)year];
	
	return titleString;
}

- (UIColor *)mapBloodPresureCategoryToColor:(enum BloodPressureCategory)category
{
    switch (category)
    {
        case Low:
        case Low_Normal:
        case Normal:
            return [UIColor greenColor];
            
        case Prehypertension_Borderline:
            return [UIColor yellowColor];
            
        case Stage1_Mild_Hypertension:
            return [UIColor orangeColor];
            
        case Stage2_Moderate_Hypertension:
        case Stage3_Severe_Hypertension:
        case Stage4_Very_Severe_Hypertension:
            return [UIColor redColor];
            
        default:
            break;
    }
    
    return [UIColor blackColor];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    BPTReadingTableViewCell *cell
        = (BPTReadingTableViewCell *)[tableView dequeueReusableCellWithIdentifier:bpTableViewCellName];

    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(BPTReadingTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    // Configure the cell...
    BloodPressureReading *bpReading = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    
    NSDate *date = [bpReading readingDate];
    NSString *formattedDateString = [self.shortStyleDateTimeFormatter stringFromDate:date];
    
    unsigned short systolic = [[bpReading systolic] unsignedShortValue];
    unsigned short diastolic = [[bpReading diastolic] unsignedShortValue];
    unsigned short pulse = [[bpReading pulse] unsignedShortValue];
    
    NSString *entryFormatStr = NSLocalizedString(@"BP_READING_LIST_ENTRY", nil);
    
    NSString *cellTitle = [NSString stringWithFormat:entryFormatStr, 
                          systolic,
                          diastolic,
                          pulse];
    
    
    enum BloodPressureCategory systolicCategory = 
    [[BloodPressureDataAnalyzer instance] systolicCategory:[[bpReading systolic] shortValue]];
    
    enum ImageIndex systolicIndex = mapBloodPressureCategoryToImageIndex(systolicCategory);
    
    enum BloodPressureCategory diastolicCategory = 
    [[BloodPressureDataAnalyzer instance] diastolicCategory:[[bpReading diastolic] shortValue]];
    
    enum ImageIndex diastolicIndex = mapBloodPressureCategoryToImageIndex(diastolicCategory);
    
    NSUInteger arrayIndex = (((NSUInteger)systolicIndex) * ((NSUInteger)ImageIndexCount)) 
    + (NSUInteger)diastolicIndex;
    
#if 0
    [cell setTitle:cellTitle 
          subTitle:[bpReading note] 
              time:formattedDateString 
         thumbnail:[[self bpLevelImages] 
                    objectAtIndex:arrayIndex]];
#endif
    
    cell.bpReadingLabel.text = cellTitle;
    cell.notesLabel.text = bpReading.note;
    cell.thumbNailView.image = [[self bpLevelImages] objectAtIndex:arrayIndex];
    cell.readingDateLabel.text = formattedDateString;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath 
{
    
    if (editingStyle == UITableViewCellEditingStyleDelete) 
    {
        // Delete the row from the data source.
        BloodPressureReading *bpReadingToDelete = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        
        if (self.readingSelectionViewController != nil)
        {
            BloodPressureReading *selectedReading = self.readingSelectionViewController.currBPReading;
            
            if ([bpReadingToDelete.objectID isEqual:selectedReading.objectID])
            {
                [self.readingSelectionViewController popTopLevelReading];
            }
        }
        
        [managedObjectContext_ deleteObject:bpReadingToDelete];
        
        NSError * __autoreleasing error = nil;
        
        if (![managedObjectContext_ save:&error]) 
        {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
            abort();
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:BPStoreChangedNotification object:nil];
        
        if (self.isIdiomPad)
        {
            dispatch_async(dispatch_get_main_queue(),
                           [self getSyncTableViewSelectionWithDetailViewBlock]);
        }
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert)
    {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }   
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - TableView Methods

- (void)setEditing:(BOOL)flag animated:(BOOL)animated
{
	// Always call super implementation of this method,
	// it needs to do work.
	[super setEditing:flag animated:animated];
	
	NSLog(@"setEditing: flag = %d, animated = %d", flag, animated);
    
    if (self.readingSelectionViewController != nil)
    {
        self.readingSelectionViewController.currBPReadingDetailViewController.allowEditing = !flag;
    }

    [self setupNavigationItem:YES editing:flag];

#if 0	
	// You need to insert / remove a new row in to the table view.
	if (flag)
	{
		// If entering edit mode, add another row to our table view.
		NSIndexPath *indexPath =
		[NSIndexPath indexPathForRow:[possessions count] inSection:0];
		
		NSArray *paths = [NSArray arrayWithObject:indexPath];
		
		[[self tableView] insertRowsAtIndexPaths:paths
								withRowAnimation:UITableViewRowAnimationLeft];
	}
	else 
	{
		// If leaving edit mode, remove last row from table view.
		NSIndexPath *indexPath = 
		[NSIndexPath indexPathForRow:[possessions count] inSection:0];
		
		NSArray *paths = [NSArray arrayWithObject:indexPath];
		
		[[self tableView] deleteRowsAtIndexPaths:paths
								withRowAnimation:UITableViewRowAnimationFade];
		
	}
#endif	
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self selectReadingAtIndex:indexPath];
}

- (void)selectReadingAtIndex:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    BloodPressureReading *bpReading = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    
    if (bpReading != nil)
    {
        [self.tableViewUserDefaultsHelper saveSelectedIndex:indexPath withEditFlag:YES];
        self.indexOfEditItem = indexPath;
        
        if (self.readingSelectionViewController == nil)
        {
            BPReadingDetailViewController *bpReadingDetailViewCtrlr =
            [[BPReadingDetailViewController alloc] init:bpReading
                                             newReading:NO
                                 setDefaultsFromReading:YES
                                           doneCallback:[self doneUpdatingReadingBlock:bpReading isNewReading:NO managedObjectContext:nil]];
            
            [bpReadingDetailViewCtrlr setHidesBottomBarWhenPushed:YES];
            [[self navigationController] pushViewController:bpReadingDetailViewCtrlr animated:YES];
        }
        else
        {
            [self invokeDetailViewWithReading:bpReading
                                 isNewReading:NO
                         managedObjectContext:managedObjectContext_];
        }
    }
}

#pragma mark - Blood Pressure Reading Detail Update Blocks

- (ReadingDismissedBlock)readingDismissedBlock:(BloodPressureReading *)bpReading
                                  isNewReading:(BOOL)newReading
                          managedObjectContext:(NSManagedObjectContext *)moc
{
    BPReadingListViewController * __weak weakSelf = self;
    
    ReadingDismissedBlock readingDismissedBlock = ^void(BOOL saved)
    {
        BPReadingListViewController * __strong strongSelf = weakSelf;
        
        if (strongSelf != nil)
        {
            if (saved)
            {
                NSError * __autoreleasing error = nil;
                
                if ((moc != nil) && ![moc save:&error])
                {
                    NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
                    abort();
                }
                
                // Now do a save on the moc that was given to the BPReadingListView
                // as the changes will have been posted to it now.
                if (![strongSelf.managedObjectContext save:&error])
                {
                    NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
                    abort();
                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName:BPStoreChangedNotification object:nil];
            }
            else
            {
                // Clear out the current edit item so the table
                // won't try to scroll to an invalid location.
                // Do this before updating the managed context
                // so that it will be nil when the endUpdate method
                // is invoked after the rollback.
                if (strongSelf.indexOfEditItem != nil)
                {
                    strongSelf.indexOfEditItem = nil;
                }
                
                // All that is required is to remove
                // the object from the context since
                // it hasn't been saved.
                [moc rollback];
            }
        }
    };
    
    return [readingDismissedBlock copy];
}

- (DoneUpdatingBloodPressureReadingBlock)doneUpdatingReadingBlock:(BloodPressureReading*)bpReading
                                                     isNewReading:(BOOL)newReading
                                             managedObjectContext:(NSManagedObjectContext *)moc
{
    BPReadingListViewController * __weak weakSelf = self;
    ReadingDismissedBlock readingDismissedBlock = [self readingDismissedBlock:bpReading
                                                                 isNewReading:newReading
                                                         managedObjectContext:moc];
    
    DoneUpdatingBloodPressureReadingBlock doneUpdatingBlock = ^BOOL(BOOL saved)
    {
        BPReadingListViewController * __strong strongSelf = weakSelf;

        if (strongSelf != nil)
        {
            readingDismissedBlock(saved);
            
            if (newReading)
            {
                if (strongSelf.bpReadingDetailPopover != nil)
                {
                    [strongSelf.bpReadingDetailPopover dismissPopoverAnimated:YES];
                    strongSelf.bpReadingDetailPopover = nil;
                    dispatch_async(dispatch_get_main_queue(), [self getAutoSelectReadingFromIdBlock:bpReading.objectID]);
                }
                else
                {
                    [strongSelf dismissViewControllerAnimated:YES completion:NULL];
                }
                
                return YES;
            }
        }
        
        return NO;
    };
    
    return [doneUpdatingBlock copy];
}

#pragma mark - Selected Reading Block Methods

- (DispatchQueueBlock)getAutoSelectReadingFromIdBlock:(NSManagedObjectID *)objectId
{
    BPReadingListViewController * __weak weakSelf = self;

    DispatchQueueBlock autoSelectReadingFromIdBlock = ^void(void)
    {
        BPReadingListViewController * __strong strongSelf = weakSelf;
        
        if (strongSelf != nil)
        {
            BloodPressureReading *bpReading = (BloodPressureReading *)[strongSelf.managedObjectContext objectWithID:objectId];
            
            if (bpReading != nil)
            {
                NSIndexPath *indexPath = [strongSelf.fetchedResultsController indexPathForObject:bpReading];
                
                if (indexPath != nil)
                {
                    [strongSelf selectReadingAtIndex:indexPath];
                }
            }
        }
    };
    
    return [autoSelectReadingFromIdBlock copy];
}

- (DispatchQueueBlock)getSyncTableViewSelectionWithDetailViewBlock;
{
    BPReadingListViewController * __weak weakSelf = self;
    
    DispatchQueueBlock syncSelectionBlock = ^void(void)
    {
        BPReadingListViewController * __strong strongSelf = weakSelf;
        
        if (strongSelf != nil)
        {
            BloodPressureReading *currBPReading = [self.readingSelectionViewController currBPReading];
            
            NSIndexPath *selIndexPath = strongSelf.tableView.indexPathForSelectedRow;
            
            if (selIndexPath != nil)
            {
                BloodPressureReading *selBPReading = [strongSelf.fetchedResultsController objectAtIndexPath:selIndexPath];
                
                if (currBPReading != nil)
                {
                    if (selBPReading != nil)
                    {
                        if ([selBPReading.objectID isEqual:currBPReading.objectID])
                        {
                            return;
                        }
                    }
                }
                
                [strongSelf invokeDetailViewWithReading:selBPReading
                                           isNewReading:NO
                                   managedObjectContext:strongSelf.managedObjectContext];
            }
        }
    };
    
    return [syncSelectionBlock copy];
}

#pragma mark - Invoke Reading Selection Detail View Controller

- (void)invokeDetailViewWithReading:(BloodPressureReading *)bpReading
                       isNewReading:(BOOL)newReading
               managedObjectContext:(NSManagedObjectContext *)moc
{
    ReadingDismissedBlock readingDismissedBlock = [self readingDismissedBlock:bpReading
                                                                 isNewReading:newReading
                                                         managedObjectContext:moc];
    
    if (newReading)
    {
        [self.readingSelectionViewController editNewReading:bpReading completion:readingDismissedBlock];
    }
    else
    {
        [self.readingSelectionViewController selectedReading:bpReading completion:readingDismissedBlock];
    }
}

#pragma mark -
#pragma CoreData controller related methods

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [[self tableView] beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller 
                    didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo
                    atIndex:(NSUInteger)sectionIndex 
                    forChangeType:(NSFetchedResultsChangeType)type
{
    NSIndexSet *set = [NSIndexSet indexSetWithIndex:sectionIndex];
    
    switch (type)
    {
        case NSFetchedResultsChangeInsert:
            [[self tableView] insertSections:set
                            withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [[self tableView] deleteSections:set
                            withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        default:
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tv = [self tableView];
    
    switch (type)
    {
        case NSFetchedResultsChangeInsert:
            [tv insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                      withRowAnimation:UITableViewRowAnimationFade];
            self.indexOfEditItem = newIndexPath;
            break;
            
        case NSFetchedResultsChangeDelete:
            [tv deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                      withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:(BPTReadingTableViewCell *)[tv cellForRowAtIndexPath:indexPath]
                    atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            {
                NSIndexPath *currEditItem = self.indexOfEditItem;
                
                if (currEditItem != nil)
                {
                    if ([currEditItem compare:indexPath] == NSOrderedSame)
                    {
                        self.indexOfEditItem = newIndexPath;
                    }
                }
                
                [tv deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                          withRowAnimation:UITableViewRowAnimationFade];
                [tv insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                          withRowAnimation:UITableViewRowAnimationFade];
            }
            break;            
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    UITableView *tv = self.tableView;
    
    // If editing a blood pressure reading then 
    // don't cause the table to reload the data 
    // as the contents of the table will be 
    // refreshed once the editing is complete.
    [tv endUpdates];
    
    NSIndexPath *editItemIndex = self.indexOfEditItem;
    
    if (editItemIndex != nil)
    {
        [tv selectRowAtIndexPath:editItemIndex animated:NO scrollPosition:UITableViewScrollPositionNone];
        [tv scrollToRowAtIndexPath:editItemIndex atScrollPosition:UITableViewScrollPositionNone animated:YES];
        
        self.indexOfEditItem = nil;
    }
}

#pragma mark - Action methods

- (void)exportBloodPressureReadings:(id)sender
{
    NSLog(@"exportBloodPressureReadings called.");
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        ExportDataViewController *exportDataViewController = [[ExportDataViewController alloc] initWithManagedObjectContext:self.managedObjectContext];

        [exportDataViewController setHidesBottomBarWhenPushed:YES];
        
        BPReadingListViewController * __weak weakSelf = self;
        
        exportDataViewController.completionCallback = ^()
        {
            BPReadingListViewController * __strong strongSelf = weakSelf;
            
            if (strongSelf != nil)
            {
                [strongSelf dismissViewControllerAnimated:YES completion:NULL];
            }
        };

        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:exportDataViewController];

        [self presentViewController:navController animated:YES completion:NULL];
    }
    else
    {
        // On iPad use a pop-over controller.
        if (self.exportDataPopover == nil)
        {
            ExportDataViewController *exportDataViewController = [[ExportDataViewController alloc] initWithManagedObjectContext:self.managedObjectContext];

            BPReadingListViewController * __weak weakSelf = self;

            exportDataViewController.completionCallback = ^()
            {
                BPReadingListViewController * __strong strongSelf = weakSelf;
                
                if (strongSelf != nil)
                {
                    if (strongSelf.exportDataPopover != nil)
                    {
                        [strongSelf.exportDataPopover dismissPopoverAnimated:YES];
                        strongSelf.exportDataPopover = nil;
                    }
                }
            };
            
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:exportDataViewController];

            self.exportDataPopover = [[UIPopoverController alloc] initWithContentViewController:navController];

            self.exportDataPopover.delegate = self;
            
            if (self.bpReadingDetailPopover != nil)
            {
                // BPReadingDetailPopover is showing.  Hide it.
                [self.bpReadingDetailPopover dismissPopoverAnimated:YES];
                self.bpReadingDetailPopover = nil;
            }

            [self.exportDataPopover presentPopoverFromBarButtonItem:(UIBarButtonItem *)sender
                                                permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
        }
        else
        {
            // Export data popover is showing, hide it.
            [self.exportDataPopover dismissPopoverAnimated:YES];
            self.exportDataPopover = nil;
        }
    }
}

- (void)createNewBloodPressureReading:(id)sender
{
    NSLog(@"createNewBloodPressureReading called.");
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        BloodPressureReading *newBloodPressureReading = [NSEntityDescription
                                                         insertNewObjectForEntityForName:@"BloodPressureReading"inManagedObjectContext:managedObjectContext_];

        BPReadingDetailViewController *bpReadingDetailViewCtrlr =
        [[BPReadingDetailViewController alloc] init:newBloodPressureReading newReading:YES setDefaultsFromReading:NO viewControllerDelegate:self];

        [bpReadingDetailViewCtrlr setHidesBottomBarWhenPushed:YES];

        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:bpReadingDetailViewCtrlr];

        [self presentViewController:navController animated:YES completion:NULL];
    }
    else
    {
        // On iPad use a pop-over controller.
        if (self.bpReadingDetailPopover == nil)
        {

            // create writer MOC
            NSManagedObjectContext *scratchMoc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
            
            [scratchMoc setParentContext:managedObjectContext_];
            BloodPressureReading *newBloodPressureReading = [NSEntityDescription
                                                             insertNewObjectForEntityForName:@"BloodPressureReading"
                                                             inManagedObjectContext:scratchMoc];
            
            DoneUpdatingBloodPressureReadingBlock doneBlock = [self doneUpdatingReadingBlock:newBloodPressureReading
                                                                                isNewReading:YES
                                                                        managedObjectContext:scratchMoc];
            
            BPReadingDetailViewController *bpReadingDetailViewCtrlr =
            [[BPReadingDetailViewController alloc] init:newBloodPressureReading
                                             newReading:YES
                                 setDefaultsFromReading:NO
                                      doneCallback:doneBlock];
            
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:bpReadingDetailViewCtrlr];
        
            self.bpReadingDetailPopover = [[UIPopoverController alloc] initWithContentViewController:navController];
            self.bpReadingDetailPopover.delegate = self;

            if (self.exportDataPopover != nil)
            {
                // Export data popover is showing, hide it.
                [self.exportDataPopover dismissPopoverAnimated:YES];
                self.exportDataPopover = nil;
            }
            
            [self.bpReadingDetailPopover presentPopoverFromBarButtonItem:(UIBarButtonItem *)sender
                permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES]; 
        }
        else
        {
            // BPReadingDetailPopover is showing.  Hide it.
            [self.bpReadingDetailPopover dismissPopoverAnimated:YES];
            self.bpReadingDetailPopover = nil;
        }       

        /*
        // Do something different when running with a selection delegate (on the iPad).
        if (!self.readingSelectionDelegate.editingNewReading)
        {
            // create writer MOC
            NSManagedObjectContext *scratchMoc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
            
            [scratchMoc setParentContext:managedObjectContext_];
            BloodPressureReading *newBloodPressureReading = [NSEntityDescription
                                                             insertNewObjectForEntityForName:@"BloodPressureReading"
                                                             inManagedObjectContext:scratchMoc];
            
            // Allow the user to edit it.
            [self invokeDetailViewWithReading:newBloodPressureReading
                                 isNewReading:YES
                         managedObjectContext:scratchMoc];
        }
        */
    }
}

- (void)sortReadings:(id)sender
{
    if (self.sortAscending)
    {
        self.navigationItem.rightBarButtonItems = self.sortDescendingRightButtonsArray;
        self.sortAscending = NO;
    }
    else
    {
        self.navigationItem.rightBarButtonItems = self.sortAscendingRightButtonsArray;
        self.sortAscending = YES;
    }
    
    if (self.tableView.editing)
    {
        self.navigationItem.rightBarButtonItem = nil;        
    }
    
    [self.tableViewUserDefaultsHelper saveSortAscendingFlag:self.sortAscending];
    [self.tableViewUserDefaultsHelper saveSelectedIndex:nil withEditFlag:NO];
    
    self.fetchedResultsController = nil;
    
	NSError * __autoreleasing error = nil;
	if (![[self fetchedResultsController] performFetch:&error])
	{
		/*
		 Replace this implementation with code to handle the error appropriately.
		 
		 abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
		 */
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}
    
    [self.tableView reloadData];
}

#pragma mark - BPReadingDetailViewControllerDegate implementation

- (BOOL)doneUpdatingBloodPressureReading:(BPReadingDetailViewController *)viewController
                    bloodPressureReading:(BloodPressureReading *)reading
                                   saved:(BOOL)saved
                              newReading:(BOOL)newReading
{
    if (saved)
    {
        NSError * __autoreleasing error = nil;
        
        if (![managedObjectContext_ save:&error]) 
        {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
            abort();
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:BPStoreChangedNotification object:nil];
    }
    else
    {
        // Clear out the current edit item so the table
        // won't try to scroll to an invalid location.
        // Do this before updating the managed context
        // so that it will be nil when the endUpdate method
        // is invoked after the rollback.
        if (self.indexOfEditItem != nil)
        {
            self.indexOfEditItem = nil;
        }
        
        // All that is required is to remove
        // the object from the context since
        // it hasn't been saved.
        [managedObjectContext_ rollback];
    }
    
    if (newReading)
    {
        if (self.bpReadingDetailPopover != nil)
        {
            [self.bpReadingDetailPopover dismissPopoverAnimated:YES];
            self.bpReadingDetailPopover = nil;
        }
        else
        {
            [self dismissViewControllerAnimated:YES completion:NULL];
        }
        
        return YES;
    }
    
    return NO;
}

- (void)modeChanged:(BOOL)editing
{
    
    if (self.readingSelectionViewController != nil)
    {
        [self setupNavigationItem:!editing editing:NO];
    }
}

#pragma mark -
#pragma mark Fetched results controller

- (NSString *)buildFetchedResultsControllerCacheName
{
    NSString *sortOrder = nil;
    
    if (self.sortAscending)
    {
        sortOrder = @"Ascending";
    }
    else
    {
        sortOrder = @"Descending";
    }
    
    NSString *className = NSStringFromClass([self class]);
    
    return [NSString stringWithFormat:@"%@_%@", className, sortOrder];
}

- (NSFetchedResultsController *)fetchedResultsController
{
    // Set up the fetched results controller if needed.
    if (fetchedResultsController_ == nil) 
	{
        NSString *cacheName = [self buildFetchedResultsControllerCacheName];
        
        [NSFetchedResultsController deleteCacheWithName:cacheName];
        
        NSFetchedResultsController *fetchedResultsCtrlr
            = [[FetchedResultsControllerFactory instance] makeBPFetchedResultsControllerWithManagedObjectContext:managedObjectContext_
                                                                                              sectionNameKeyPath:@"sectionId"
                                                                                                   sortAscending:self.sortAscending
                                                                                                       cacheName:cacheName batchSize:20];
        
        if (fetchedResultsCtrlr != nil)
        {
            fetchedResultsCtrlr.delegate = self;
            self.fetchedResultsController = fetchedResultsCtrlr;
        }
    }
	
	return fetchedResultsController_;
}    

#pragma mark - Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

#pragma mark - UIPopoverDelegate Methods

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.bpReadingDetailPopover = nil;
    self.exportDataPopover = nil;
}

@end

