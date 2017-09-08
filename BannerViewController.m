//
//  BannerViewController.m
//  BPTracker
//
//  Created by Robert Saccone on 4/24/13.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "BannerViewController.h"

NSString * const BannerViewActionWillBegin = @"BannerViewActionWillBegin";
NSString * const BannerViewActionDidFinish = @"BannerViewActionDidFinish";

static const NSTimeInterval BANNER_VIEW_OBSCURED_REMOVAL_TIMEOUT_IN_SECS        =   30.0f;
static const NSTimeInterval BANNER_VIEW_OBSCURED_CHECK_TIMER_INTERVAL_IN_SECS   =   5.0f;

@interface BannerViewController ()

// This method is used by BannerViewSingletonController to inform instances of BannerViewController that the banner has loaded/unloaded.
- (void)updateLayout;

@end

@interface BannerViewManager : NSObject <ADBannerViewDelegate>

@property(nonatomic, readonly) ADBannerView *bannerView;
@property(nonatomic, retain) NSDate *bannerObscuredStartTime;
@property(nonatomic, assign) BOOL adIsCoveringApp;

+ (BannerViewManager *)sharedInstance;

- (void)addBannerViewController:(BannerViewController *)controller;
- (void)removeBannerViewController:(BannerViewController *)controller;

@end

@implementation BannerViewController
{
    UIViewController *_contentController;
}

@synthesize contentController = _contentController;

- (UINavigationItem *)navigationItem
{
    if (_contentController != nil)
    {
        return _contentController.navigationItem;
    }
    
    return super.navigationItem;
}

- (instancetype)initWithContentViewController:(UIViewController *)contentController
{
    self = [super init];
    if (self != nil) {
        _contentController = contentController;
        [[BannerViewManager sharedInstance] addBannerViewController:self];
        
        UITabBarItem *tbi = _contentController.tabBarItem;
        
        if (tbi != nil)
        {
            self.tabBarItem = tbi;
        }
        
        self.title = _contentController.title;
    }
    return self;
}

- (void)dealloc
{
    [[BannerViewManager sharedInstance] removeBannerViewController:self];
}

- (void)loadView
{
    CGRect mainScreenBounds = [[UIScreen mainScreen] bounds];
    UIView *contentView = [[UIView alloc] initWithFrame:mainScreenBounds];
    [self addChildViewController:_contentController];
    [contentView addSubview:_contentController.view];
    [self.contentController didMoveToParentViewController:self];
    self.view = contentView;
}

- (void)setContentController:(UIViewController *)contentController
{
    if (contentController != _contentController)
    {
        if (self.view != nil)
        {
            if (_contentController != nil)
            {
                [_contentController.view removeFromSuperview];
                [_contentController removeFromParentViewController];
                
                _contentController = nil;
            }
            
            if (contentController != nil)
            {
                _contentController = contentController;
                
                [self addChildViewController:_contentController];
                [self.view addSubview:_contentController.view];
            }
        }
        else
        {
            _contentController = contentController;
        }
    }
}

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [_contentController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}
#endif

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return [_contentController preferredInterfaceOrientationForPresentation];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return [_contentController supportedInterfaceOrientations];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIViewController *cc = self.contentController;
    
    if (cc != nil)
    {
        self.title = cc.title;
    }
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (void)viewDidLayoutSubviews
{
    CGRect contentFrame = self.view.bounds, bannerFrame = CGRectZero;
    ADBannerView *bannerView = [BannerViewManager sharedInstance].bannerView;
    
    // Grab the bottom and top bar offsets so the graph can be presented without
    // being clipped.
    CGFloat bottomBarOffset = self.bottomLayoutGuide.length;
    
    // On iOS 7 the content frame will be sized under any bars at the bottom
    // of the display.  Compensate for this.
    contentFrame = CGRectMake(contentFrame.origin.x, contentFrame.origin.y, contentFrame.size.width, contentFrame.size.height - bottomBarOffset);

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
    NSString *contentSizeIdentifier;
    // If configured to support iOS <6.0, then we need to set the currentContentSizeIdentifier in order to resize the banner properly.
    // This continues to work on iOS 6.0, so we won't need to do anything further to resize the banner.
    if (contentFrame.size.width < contentFrame.size.height) {
        contentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
    }
    else {
        contentSizeIdentifier = ADBannerContentSizeIdentifierLandscape;
    }
    bannerFrame.size = [ADBannerView sizeFromBannerContentSizeIdentifier:contentSizeIdentifier];
#else
    // If configured to support iOS >= 6.0 only, then we want to avoid currentContentSizeIdentifier as it is deprecated.
    // Fortunately all we need to do is ask the banner for a size that fits into the layout area we are using.
    // At this point in this method contentFrame=self.view.bounds, so we'll use that size for the layout.
    bannerFrame.size = [bannerView sizeThatFits:contentFrame.size];
#endif
    
    if (bannerView.bannerLoaded) {
        contentFrame.size.height -= bannerFrame.size.height;
        bannerFrame.origin.y = contentFrame.size.height;
    }
    else {
        bannerFrame.origin.y = contentFrame.size.height;
    }
    _contentController.view.frame = contentFrame;
    // We only want to modify the banner view itself if this view controller is actually visible to the user.
    // This prevents us from modifying it while it is being displayed elsewhere.
    if (self.isViewLoaded && (self.view.window != nil)) {
        [self.view addSubview:bannerView];
        bannerView.frame = bannerFrame;
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
        bannerView.currentContentSizeIdentifier = contentSizeIdentifier;
#endif
    }
}

- (void)updateLayout
{
    [UIView animateWithDuration:0.25 animations:^{
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.view addSubview:[BannerViewManager sharedInstance].bannerView];
}

- (NSString *)title
{
    return _contentController.title;
}

@end

@implementation BannerViewManager {
    ADBannerView *_bannerView;
    NSMutableSet *_bannerViewControllers;
    NSTimer *_bannerViewCheckTimer;
    NSDate *_bannerObscuredStartTime;
    BOOL _adIsCoveringApp;
}

@synthesize bannerObscuredStartTime = _bannerObscuredStartTime;
@synthesize adIsCoveringApp = _adIsCoveringApp;
@synthesize bannerView = _bannerView;

+ (BannerViewManager *)sharedInstance
{
    static BannerViewManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[BannerViewManager alloc] init];
    });
    return sharedInstance;
}

static ADBannerView *createBannerView()
{
    ADBannerView *bannerView;
    
    // On iOS 6 ADBannerView introduces a new initializer, use it when available.
    if ([ADBannerView instancesRespondToSelector:@selector(initWithAdType:)])
    {
        bannerView = [[ADBannerView alloc] initWithAdType:ADAdTypeBanner];
    }
    else
    {
        bannerView = [[ADBannerView alloc] init];
    }
    
    return bannerView;
}

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _bannerView = createBannerView();
        _bannerView.delegate = self;
        _bannerViewControllers = [[NSMutableSet alloc] init];
        [self setupBannerViewMonitorTimer];
    }
    return self;
}

- (ADBannerView *)bannerView
{
    if (_bannerView == nil)
    {
        NSLog(@"BannerViewMgr - Recreating banner view");
        _bannerView = createBannerView();
        _bannerView.delegate = self;
        [self setupBannerViewMonitorTimer];
    }
    
    return _bannerView;
}

- (void)setupBannerViewMonitorTimer
{
    if (_bannerViewCheckTimer == nil)
    {
        _bannerViewCheckTimer = [NSTimer timerWithTimeInterval:BANNER_VIEW_OBSCURED_CHECK_TIMER_INTERVAL_IN_SECS
                                                        target:self selector:@selector(checkIfAdBannerShouldBeRemovedTimerMethod:)
                                                      userInfo:nil
                                                       repeats:YES];

        [[NSRunLoop mainRunLoop] addTimer:_bannerViewCheckTimer forMode:NSDefaultRunLoopMode];
        NSLog(@"BannerViewManager -> Registered for banner view removal timer.");
    }
}

- (void)stopBannerViewMonitorTimer
{
    if (_bannerViewCheckTimer != nil)
    {
        [_bannerViewCheckTimer invalidate];
        _bannerViewCheckTimer = nil;
        NSLog(@"BannerViewManager -> Unregistered for banner view removal timer.");
    }
}

- (void)checkIfAdBannerShouldBeRemovedTimerMethod:(NSTimer*)theTimer
{
    if (self.adIsCoveringApp || (_bannerView == nil))
    {
        self.bannerObscuredStartTime = nil;
        return;
    }
    
    NSDate *currTime = [NSDate date];
    
    for (BannerViewController *bvc in _bannerViewControllers)
    {
        // If the bannerview is visible or an add is covering the app
        if (bvc.isViewLoaded && (bvc.view.window != nil))
        {
            NSLog(@"Banner View Controller %@ is visible", bvc);
            self.bannerObscuredStartTime = nil;
            return;
        }
    }
    
    // Reaching here means that the bannerview is obscured and
    // potentially can be removed from the view hierarchy in order
    // to avoid wasting ads if it has been a significant amount of time.
    if (self.bannerObscuredStartTime != nil)
    {
        NSTimeInterval diff = [currTime timeIntervalSinceDate:self.bannerObscuredStartTime];

        if (diff >= BANNER_VIEW_OBSCURED_REMOVAL_TIMEOUT_IN_SECS)
        {
            NSLog(@"BannerViewMgr: BannerView is covered for %f seconds, removing from view hierarchy", diff);
            [_bannerView removeFromSuperview];
            _bannerView.delegate = nil;
            _bannerView = nil;
            self.bannerObscuredStartTime = nil;
            [self stopBannerViewMonitorTimer];
        }
    }
    else
    {
        self.bannerObscuredStartTime = currTime;
    }
}

- (void)addBannerViewController:(BannerViewController *)controller
{
    [_bannerViewControllers addObject:controller];
}

- (void)removeBannerViewController:(BannerViewController *)controller
{
    [_bannerViewControllers removeObject:controller];
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    for (BannerViewController *bvc in _bannerViewControllers) {
        [bvc updateLayout];
    }
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    for (BannerViewController *bvc in _bannerViewControllers) {
        [bvc updateLayout];
    }
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
    self.adIsCoveringApp = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:BannerViewActionWillBegin object:self];
    return YES;
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner
{
    self.adIsCoveringApp = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:BannerViewActionDidFinish object:self];
}


@end
