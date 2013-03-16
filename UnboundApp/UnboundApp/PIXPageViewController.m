//
//  PIXPageViewController.m
//  UnboundApp
//
//  Created by Bob on 12/15/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//
#import <Quartz/Quartz.h>

#import "PIXPageViewController.h"
#import "PIXAppDelegate.h"
#import "Album.h"
#import "PIXAlbum.h"
#import "PIXPhoto.h"
#import "PIXImageViewController.h"
#import "PIXLeapInputManager.h"
#import "PIXNavigationController.h"

@interface PIXPageViewController () <leapResponder>

@property NSArray * viewControllers;

@end

@implementation PIXPageViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        
    }
    
    return self;
}

-(void)awakeFromNib
{
    if (self.album!=nil)
    {
        [self.pageController.view setWantsLayer:YES];
        self.pageController.transitionStyle = NSPageControllerTransitionStyleHorizontalStrip;
    
        
        
    }
}
/*
-(void)setupToolbar
{
//    [self.navigationViewController setNavBarHidden:YES];
}
*/


- (void)willShowPIXView
{
    [[PIXLeapInputManager sharedInstance] addResponder:self];
    
    
    [self updateData];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.view.window makeFirstResponder:self];
        
    });
}

-(BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)willHidePIXView
{
    [[PIXLeapInputManager sharedInstance] removeResponder:self];
}

-(void)multiFingerSwipeUp
{
    [self.navigationViewController popViewController];
}

-(void)multiFingerSwipeRight
{
    [self.pageController navigateBack:nil];
}

-(void)moveForward:(id)sender
{
    [self.pageController navigateForward:nil];
}

-(void)moveRight:(id)sender
{
    [self.pageController navigateForward:nil];
}

-(void)moveLeft:(id)sender
{
    [self.pageController navigateBack:nil];
}



-(void)multiFingerSwipeLeft
{
    [self.pageController navigateForward:nil];
}

- (void)updateData {
    
    self.pagerData = [[self.album.photos array] mutableCopy];
    
    
    // set the first image in our list to the main magnifying view
    if ([self.pagerData count] > 0) {
        [self.pageController setArrangedObjects:self.pagerData];
        NSInteger index = [self.album.photos indexOfObject:self.initialSelectedObject];
        [self.pageController setSelectedIndex:index];
    }
}

-(void)setAlbum:(PIXAlbum *)album
{
    _album = album;
}

-(void)preloadNextImagesForIndex:(NSUInteger)anIndex
{
    
    for(NSUInteger i = anIndex -2; i < anIndex+2; i++)
    {
        if(i < [self.pagerData count])
        {
            // this will cause the image to preload
            [(PIXPhoto *)[self.pagerData objectAtIndex:i] fullsizeImage];
        }
    }
    
}


@end

@implementation PIXPageViewController (NSPageControllerDelegate)
- (NSString *)pageController:(NSPageController *)pageController identifierForObject:(id)object {
    
    if (![[object imageRepresentationType] isEqualToString:IKImageBrowserQTMoviePathRepresentationType]) {
        return @"picture";
    }
    return @"video";
}

- (NSViewController *)pageController:(NSPageController *)pageController viewControllerForIdentifier:(NSString *)identifier {
    //NSLog(@"pageController.selectedIndex : %ld", pageController.selectedIndex);
    if (![identifier isEqualToString:@"video"])
    {
        PIXImageViewController *aVC =  [[PIXImageViewController alloc] initWithNibName:@"imageview" bundle:nil];
        aVC.pageViewController = self;
        return aVC;
    } else {
        NSViewController *videoView = [[NSViewController alloc] initWithNibName:@"videoview" bundle:nil];
        return videoView;
    }
}

-(void)pageController:(NSPageController *)pageController prepareViewController:(NSViewController *)viewController withObject:(id)object {
    
    if(object == nil) return;
    
    viewController.representedObject = object;
    // viewControllers may be reused... make sure to reset important stuff like the current magnification factor.
    
    // Normally, we want to reset the magnification value to 1 as the user swipes to other images. However if the user cancels the swipe, we want to leave the original magnificaiton and scroll position alone.
    
    BOOL isRepreparingOriginalView = (self.initialSelectedObject && self.initialSelectedObject == object) ? YES : NO;
    if (!isRepreparingOriginalView) {
        [(NSScrollView*)viewController.view setMagnification:1.0];
        //[self makeSelectedViewFirstResponder];
    }
    
    [self preloadNextImagesForIndex:pageController.selectedIndex];
    
}

- (void)pageControllerWillStartLiveTransition:(NSPageController *)pageController {
    // Remember the initial selected object so we can determine when a cancel occurred.
    self.initialSelectedObject = [pageController.arrangedObjects objectAtIndex:pageController.selectedIndex];
}

-(void)makeSelectedViewFirstResponder
{
    NSWindow *mainWindow = [[NSApplication sharedApplication] mainWindow];
    //[mainWindow setContentView:aViewController.view];
    
    NSView *aView = self.pageController.selectedViewController.view;//
    //aView = [self.pageController.selectedViewController.view enclosingScrollView];
    /*if (aView == nil) {
     aView = aViewController.view;
     }*/
    
    
    [mainWindow makeFirstResponder:self];
}


- (void)pageController:(NSPageController *)pageController didTransitionToObject:(id)object
{
    //NSLog(@"didTransitionToObject : %@", object);
    
    
    [self makeSelectedViewFirstResponder];
    /*dispatch_async(dispatch_get_current_queue(), ^{
     
     NSWindow *mainWindow = [[NSApplication sharedApplication] mainWindow];
     //[mainWindow setContentView:aViewController.view];
     
     NSView *aView = self.pageController.selectedViewController.view;//
     //aView = [self.pageController.selectedViewController.view enclosingScrollView];
     
     
     [mainWindow makeFirstResponder:aView];
     
     });*/
}

- (void)pageControllerDidEndLiveTransition:(NSPageController *)aPageController {
    [aPageController completeTransition];
    [self makeSelectedViewFirstResponder];
}



@end

