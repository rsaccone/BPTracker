//
//  BPReadingNoteTaker.m
//  BPTracker
//
//  Created by Robert Saccone on 10/17/11.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "NoteTakerViewController.h"
#import <SLexUtil/PlatformHelper.h>

// Class extension using anonymous category to hide
// internal methods and properties from consumers
// of the class.
@interface NoteTakerViewController ()

@property(nonatomic, copy) NSString *noteText;
@property(nonatomic, weak) id keyboardWillShowObserver;
@property(nonatomic, weak) id keyboardWillHideObserver;

- (void)notifyDelegateToDismissView;

@end

@implementation NoteTakerViewController
{
@private
    UITextView  * __weak notesField_;
    
    NSString    *noteText_;
    BOOL        canceled_;
}

@synthesize delegate;
@synthesize notesField=notesField_;
@synthesize noteText=noteText_;
@synthesize canceled=canceled_;

#pragma mark - Initialization

- (id)init
{
    static NSString * const nibName = @"NoteTakerViewController";
    
    self = [super initWithNibName:nibName bundle:nil];
    if (self) 
    {
        // Custom initialization.
        
        // Create item
        UIBarButtonItem *bbi = [[UIBarButtonItem alloc]
                                initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                target:self
                                action:@selector(done:)];
        
        [[self navigationItem] setRightBarButtonItem:bbi];
        
        // Cancel item
        bbi = [[UIBarButtonItem alloc]
               initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
               target:self
               action:@selector(cancel:)];
        
        [[self navigationItem] setLeftBarButtonItem:bbi];
    }
    
    return self;
}

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
{
    return [self init];
}

- (id)initWithNoteText:(NSString *)noteText
{
    self = [self init];
    
    if (self)
    {
        [self setNoteText:noteText];
    }
    
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self registerForNotifications];
    
    // Do any additional setup after loading the view from its nib.
    NSString *text = [self noteText];
    
    if (text != nil)
    {
        [[self notesField] setText:text];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    
    // Make the keyboard appear when the application launches.
    [super viewWillAppear:animated];
    [[self notesField] becomeFirstResponder];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark -Text view delegate methods

- (BOOL)textViewShouldBeginEditing:(UITextView *)aTextView 
{
    return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)aTextView 
{
    [[self notesField] resignFirstResponder];
    return YES;
}

- (void)notifyDelegateToDismissView
{
    if ([delegate respondsToSelector:@selector(noteTakerViewControllerShouldBeDismissed:)])
    {
        [delegate noteTakerViewControllerShouldBeDismissed:self];
    }
}

#pragma mark - Actions

- (IBAction)cancel:(id)sender
{
    NSLog(@"cancel pressed...");
    
    canceled_ = YES;
    
    [self notifyDelegateToDismissView];
}

- (IBAction)done:(id)sender
{
    NSLog(@"done pressed...");
    
    [self setNoteText:[[self notesField] text]];
    
    [self notifyDelegateToDismissView];
}

#pragma mark - Notification Management

- (void)registerForNotifications
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    
    NoteTakerViewController * __weak weakSelf = self;
    
    self.keyboardWillShowObserver =
        [center addObserverForName:UIKeyboardWillShowNotification
                            object:nil
                             queue:mainQueue
                        usingBlock:^(NSNotification *notification)
        {
            /*
             Reduce the size of the text view so that it's not obscured by the keyboard.
             Animate the resize so that it's in sync with the appearance of the keyboard.
             */
            
            NSDictionary *userInfo = [notification userInfo];
            
            // Get the origin of the keyboard when it's displayed.
            NSValue* aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
            
            // Get the top of the keyboard as the y coordinate of its origin in self's view's coordinate system. The bottom of the text view's frame should align with the top of the keyboard's final position.
            CGRect keyboardRect = [aValue CGRectValue];
            keyboardRect = [weakSelf.view convertRect:keyboardRect fromView:nil];
            
            CGFloat keyboardTop = keyboardRect.origin.y;
            CGRect newTextViewFrame = weakSelf.view.bounds;
            newTextViewFrame.size.height = keyboardTop - weakSelf.view.bounds.origin.y;
            
            // Get the duration of the animation.
            NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
            NSTimeInterval animationDuration;
            [animationDurationValue getValue:&animationDuration];
            
            // Animate the resize of the text view's frame in sync with the keyboard's appearance.
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:animationDuration];
            
            [[weakSelf notesField] setFrame:newTextViewFrame];
            
            [UIView commitAnimations];
        }];
    
    
    self.keyboardWillHideObserver =
        [center addObserverForName:UIKeyboardWillHideNotification
                            object:nil
                             queue:mainQueue
                        usingBlock:^(NSNotification *notification)
         {
             NSDictionary* userInfo = [notification userInfo];
             
             /*
              Restore the size of the text view (fill self's view).
              Animate the resize so that it's in sync with the disappearance of the keyboard.
              */
             NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
             NSTimeInterval animationDuration;
             [animationDurationValue getValue:&animationDuration];
             
             [UIView beginAnimations:nil context:NULL];
             [UIView setAnimationDuration:animationDuration];
             
             [[weakSelf notesField] setFrame:weakSelf.view.bounds];
             
             [UIView commitAnimations];
         }];
}

- (void)unregisterForNotifications
{
    // Unregister from all notifications for this observer.
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    if (self.keyboardWillShowObserver != nil)
    {
        [center removeObserver:self.keyboardWillShowObserver name:UIKeyboardDidShowNotification object:nil];
    }
    
    if (self.keyboardWillHideObserver != nil)
    {
        [center removeObserver:self.keyboardWillHideObserver name:UIKeyboardWillHideNotification object:nil];
    }
}

#pragma mark - Memory management

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc 
{
    [self unregisterForNotifications];
}

@end
