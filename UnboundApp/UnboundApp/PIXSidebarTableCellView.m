//
//  PIXSidebarTableCellView.m
//  UnboundApp
//
//  Created by Bob on 12/15/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXSidebarTableCellView.h"
#import "Album.h"
#import "PIXDefines.h"

@implementation PIXSidebarTableCellView

- (void)awakeFromNib {
    // We want it to appear "inline"
    //[[self.button cell] setBezelStyle:NSInlineBezelStyle];
    NSImage *anImage = [NSImage imageNamed:@"nophoto"];
    
    
    [self.imageView setImage:anImage];
    [self.imageView setImageScaling:NSImageScaleNone];
    //[self.imageView setImageFrameStyle:NSImagef:]
    [self.detailTextLabel setStringValue:@"Loading"];
    
    
    [self.imageView setWantsLayer:YES];
    
    
    [self.imageView.layer setBorderColor:[[NSColor colorWithCalibratedWhite:0.0 alpha:0.4] CGColor]];
    [self.imageView.layer setBorderWidth:1.0];
    [self.imageView.layer setCornerRadius:2.5];
    
    
    CGColorRef color = CGColorCreateGenericGray(1.0, 1.0);
    [self.imageView.layer setBackgroundColor:color];
    [self.imageView.layer setShadowOpacity:1.0];
    [self.imageView.layer setShadowRadius:2.0];
    [self.imageView.layer setShadowColor:[NSColor blackColor].CGColor];
    //[self.imageView.layer setShadowOffset:CGSizeMake(0, -1)];
    
    
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AlbumDidChangeNotification object:_album];
    
    //self.button = nil;
    //[super dealloc];
}

-(void)updateAlbumInfo:(NSNotification *)note
{
    [self.textField setStringValue:self.album.title];
    if ([_album thumbnailImage]!=nil)
    {
        [self.imageView setImage:[_album thumbnailImage]];
    }
    
    else
    {
        [self.imageView setImage:[NSImage imageNamed:@"nophoto"]];
    }
    [self.detailTextLabel setStringValue:[self.album imageSubtitle]];
}

-(void)setFrame:(NSRect)frameRect
{
    // i wasn't able to figure out where the 10px inset was coming
    // from in the cells. I'm fixing it here but it's a bit of a hack. (scott)
    frameRect.size.width += 10;
    [super setFrame:frameRect];
    
}

-(void)setAlbum:(Album *)newAlbum
{
    if (newAlbum!=_album)
    {
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AlbumDidChangeNotification object:_album];
        
        _album = newAlbum;
        if (_album!=nil)
        {
            [self updateAlbumInfo:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAlbumInfo:) name:AlbumDidChangeNotification object:_album];
            
        }
        
        
    }
    
}

// use this to switch text color when highligthed
- (void)setBackgroundStyle:(NSBackgroundStyle)style
{
    [super setBackgroundStyle:style];
    
    // If the cell's text color is black, this sets it to white
    [((NSCell *)self.detailTextLabel.cell) setBackgroundStyle:style];
    
    // Otherwise you need to change the color manually
    switch (style) {
        case NSBackgroundStyleLight:
            [self.detailTextLabel setTextColor:[NSColor colorWithCalibratedWhite:0.4 alpha:1.0]];
            break;
            
        case NSBackgroundStyleDark:
        default:
            [self.detailTextLabel setTextColor:[NSColor colorWithCalibratedWhite:1.0 alpha:1.0]];
            break;
    }
}

@end
