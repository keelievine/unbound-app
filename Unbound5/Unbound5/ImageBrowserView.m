/*
 
 File:		ImageBrowserView.m
 
 Abstract:	IKImageBrowserView is a view that can display and browse a 
 large amount of images and movies. This sample code demonstrates 
 how to use the view in a Cocoa Application.
 
 Version:	1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the
 following terms, and your use, installation, modification or
 redistribution of this Apple software constitutes acceptance of these
 terms.  If you do not agree with these terms, please do not use,
 install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc.
 may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple.  Except
 as expressly stated in this notice, no other rights or licenses, express
 or implied, are granted by Apple herein, including but not limited to
 any patent rights that may be infringed by your derivative works or by
 other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright © 2009 Apple Inc. All Rights Reserved
 
 */

#import "ImageBrowserView.h"
#import "ImageBrowserCell.h"


@implementation ImageBrowserView

-(void)awakeFromNib
{
    [self setConstrainsToOriginalSize:YES];
    //[self setAnimates:YES];
    [self setAllowsReordering:YES];
	// cell spacing
	//[self setIntercellSpacing:NSMakeSize(5.0f, 5.0f)];
    
	// forground color for the cell's titles
	//NSMutableDictionary * options = [[NSMutableDictionary alloc] init];
	//[options setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
	//[self setValue:options forKey:IKImageBrowserCellsTitleAttributesKey];
    
}

-(BOOL)ignoreModifierKeysForDraggingSession:(NSDraggingSession *)session
{
    return YES;
}

-(NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context
{
    switch (context)
    {
        case NSDraggingContextOutsideApplication:
            return NSDragOperationCopy;
            break;
            
        case NSDraggingContextWithinApplication:
            return NSDragOperationMove;
            break;
            
    }
    return NSDragOperationCopy;
}

/**
 This method is used to seemlessly reload data. Since the selected image is
 bound to the current image of the image view, when we do the usual
 reloadData, the selection is lost. If we're in fullscreen, it'll break it.
 So this method reloads data and select the next available image just after
 that.
 */
-(void)reloadDataAndKeepSelection
{
	// remember the first selected image
	//int selectedIndex = (int)[[self selectionIndexes] firstIndex];
    
	// reload the data
	/*[(ImageBrowserDelegate *)[self delegate] setIgnoreSelectionChanges:YES];
	[super reloadData];
	[(ImageBrowserDelegate *)[self delegate] setIgnoreSelectionChanges:NO];
    
	// restore the selection, taking care of out of bound indexes
	int numImages = (int)[[self dataSource] numberOfItemsInImageBrowser:self];
	if (numImages != 0)
	{
		if (selectedIndex >= numImages)
			selectedIndex = numImages - 1;
		[self setSelectionIndexes:[NSIndexSet indexSetWithIndex:selectedIndex]
             byExtendingSelection:NO];
	}
	else
	{
		// if there is no more images, we need to explicitely set the image
		// property of the delegate to nil.
		// This is because [super reloadData] set the current selection to
		// nothing, so setting it again to nothing will NOT call the selection
		// changed delegate, thus the need to explicitely call setSelectedImage.
		[(ImageBrowserDelegate *)[self delegate] setSelectedImage:nil];
	}*/
}

/*-(void)reloadData
{
	[super reloadData];
	[self scrollPoint:NSMakePoint(0, [self frame].size.height)];
}*/

//---------------------------------------------------------------------------------
// newCellForRepresentedItem:
//
// Allocate and return our own cell class for the specified item. The returned cell must not be autoreleased 
//---------------------------------------------------------------------------------
- (IKImageBrowserCell *) newCellForRepresentedItem:(id) cell
{
	return [[ImageBrowserCell alloc] init];
}

//---------------------------------------------------------------------------------
// drawRect:
//
// override draw rect and force the background layer to redraw if the view did resize or did scroll 
//---------------------------------------------------------------------------------
- (void) drawRect:(NSRect) rect
{
	//retrieve the visible area
	NSRect visibleRect = [self visibleRect];
	
	//compare with the visible rect at the previous frame
	if(!NSEqualRects(visibleRect, lastVisibleRect)){
		//we did scroll or resize, redraw the background
		[[self backgroundLayer] setNeedsDisplay];
		
		//update last visible rect
		lastVisibleRect = visibleRect;
	}
	
	[super drawRect:rect];
}

-(BOOL)showTitles
{
	return [self cellsStyleMask] & IKCellsStyleTitled;
}

-(void)setShowTitles:(BOOL)showTitles
{
	if (showTitles == YES)
		[self setCellsStyleMask:[self cellsStyleMask] | IKCellsStyleTitled];
	else
		[self setCellsStyleMask:[self cellsStyleMask] & ~IKCellsStyleTitled];
}

-(void)keyDown:(NSEvent *)theEvent
{
    DLog(@"keyDown : %@", theEvent);
	// get the event and the modifiers
	 NSString * characters = [theEvent charactersIgnoringModifiers];
     unichar event = [characters characterAtIndex:0];
     
     switch (event)
     {
     case ' ':

     break;
     
     default:
     [super keyDown:theEvent];
     }
}

-(void)otherMouseDown:(NSEvent *)theEvent
{
	DLog(@"otherMouseDown");
}


@end
