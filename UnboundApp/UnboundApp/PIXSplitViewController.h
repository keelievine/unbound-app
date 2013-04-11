//
//  PIXSplitViewController.h
//  UnboundApp
//
//  Created by Bob on 12/15/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXViewController.h"

@class Album;
@class PIXAlbum;

@protocol PIXSplitViewControllerDelegate <NSObject>

-(void)albumSelected:(PIXAlbum *)anAlbum atIndex:(NSUInteger)index;

@end

@interface PIXSplitViewController : PIXViewController <NSSplitViewDelegate>

@property (nonatomic,weak) id <PIXSplitViewControllerDelegate> delegate;

@property (nonatomic,weak) IBOutlet NSSplitView *splitView;
@property (nonatomic,weak) IBOutlet NSView *leftPane;
@property (nonatomic,weak) IBOutlet NSView *rightPane;

@property (nonatomic,weak) IBOutlet NSSegmentedControl *backButtonSegment;
@property (nonatomic,weak) IBOutlet NSSlider * sizeSlider;

//@property (nonatomic, strong) Album* selectedAlbum;
@property (nonatomic, strong) id selectedAlbum;

-(IBAction)backBarSegmentChanged:(id)sender;
-(IBAction)sliderValueChanged:(id)sender;


@end
