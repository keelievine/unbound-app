//
//  MainWindowController.m
//  Unbound5
//
//  Created by Bob on 10/4/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "MainWindowController.h"
#import "SearchQuery.h"
//#import "IKBBrowserItem.h"
#import "PageViewController.h"
#import "ImageViewController.h"
#import "IKImageViewController.h"
#import "Album.h"
#include <sys/types.h>
#include <pwd.h>

@interface MainWindowController()

@property (strong) NSURL *searchLocation;
//- (void)updatePathControl;

@end

@implementation MainWindowController

- (IBAction)openExistingDocument:(id)sender {
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    
    // This method displays the panel and returns immediately.
    // The completion handler is called when the user selects an
    // item or cancels the panel.
    [panel beginWithCompletionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSURL*  theDoc = [[panel URLs] objectAtIndex:0];
            
            // Open  the document.
        }
        
    }];
}

NSString * IVHomeDirectory()
{
    const struct passwd * passwd = getpwnam([NSUserName() UTF8String]);
    if(!passwd)
        return nil; // bail out cowardly
    const char *homeDir_c = getpwnam([NSUserName() UTF8String])->pw_dir;
    NSString *homeDir = [[NSFileManager defaultManager]
                         stringWithFileSystemRepresentation:homeDir_c
                         length:strlen(homeDir_c)];
    return homeDir;
}

NSArray * IVLibraryDirectory()
{
    NSArray * libraryDirectories = [NSArray arrayWithObject: [IVHomeDirectory() stringByAppendingPathComponent:@"Dropbox/"]];
    return libraryDirectories;
}

- (IBAction)importFilesAndDirectories:(id)sender {
    // Get the main window for the document.
    //NSWindow* window = [[[self windowControllers] objectAtIndex:0] window];
    NSError *error = nil;
    // Create and configure the panel.
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:NO];
    [panel setAllowsMultipleSelection:NO];
    [panel setMessage:@"Please select your Dropbox camera uploads folder"];
    
    NSArray *dirs = IVLibraryDirectory();
    DLog(@"dirs : %@", dirs);
    if ([dirs count]>0)
    {
        NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[dirs lastObject] error:&error];
        if (!files)
        {
            DLog(@"%@", error);
        } else if (files != nil)
        {
            NSURL *mainDropBoxFolderURL = [NSURL fileURLWithPath:[dirs lastObject] isDirectory:YES];
            NSDirectoryEnumerator *itr = [[NSFileManager defaultManager] enumeratorAtURL:mainDropBoxFolderURL includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLLocalizedNameKey, NSURLEffectiveIconKey, NSURLIsDirectoryKey, NSURLTypeIdentifierKey, nil] options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants errorHandler:nil];
            
            for (NSURL *url in itr) {
                if ([url.filePathURL.lastPathComponent isEqualToString:@"Camera Uploads"])
                {
                    NSURL *aFileURL = url;
                    self.searchLocation = aFileURL;
                    [searchLocationPathControl setURL:self.searchLocation];
                    [self updateRootSearchPath:self.searchLocation];
                    return;
                }
            }
            
        } 

    }
    
    //[panel setDirectoryURL:[NSURL fileURLWithPath:@"~/Dropbox/Camera Uploads/" isDirectory:YES]];
    //DLog(@"1)panel.directoryURL = %@", panel.directoryURL);
    [panel setDirectoryURL:[NSURL URLWithString:@"~/Dropbox"]];
    DLog(@"2)panel.directoryURL = %@", panel.directoryURL);
    
    // Display the panel attached to the document's window.
    [panel beginSheetModalForWindow:window completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSArray* urls = [panel URLs];
            self.searchLocation = [urls lastObject];
            [searchLocationPathControl setURL:self.searchLocation];
            [self updateRootSearchPath:self.searchLocation];
            // Use the URLs to build a list of items to import.
        }
        
    }];
}

-(void)punchHoleInSandboxForFile:(NSString*)file
{
    //only needed if we are in 10.7
    if (floor(NSAppKitVersionNumber) <= 1038) return;
    //only needed if we do not allready have permisions to the file
    if ([[NSFileManager defaultManager] isReadableFileAtPath:file] == YES) return;
    //make sure we have a expanded path
    file = [file stringByResolvingSymlinksInPath];
    NSString *message = [NSString stringWithFormat:@"Sandbox requires user permision to read %@",[file lastPathComponent]];
    
    NSOpenPanel *openDlg = [NSOpenPanel openPanel];
    [openDlg setPrompt:@"Allow in Sandbox"];
    [openDlg setTitle:message];
    [openDlg setShowsHiddenFiles:NO];
    [openDlg setTreatsFilePackagesAsDirectories:YES];
    [openDlg setDirectoryURL:[NSURL URLWithString:file]];
	[openDlg setCanChooseFiles:YES];
	[openDlg setCanChooseDirectories:NO];
	[openDlg setAllowsMultipleSelection:NO];
	if ([openDlg runModal] == NSOKButton){
        NSURL *selection = [[openDlg URLs] objectAtIndex:0];
        if ([[[selection path] stringByResolvingSymlinksInPath] isEqualToString:file]) {
            self.searchLocation = selection;
            return;
        }else{
            [[NSAlert alertWithMessageText:@"Wrong file was selected." defaultButton:@"Try Again" alternateButton:nil otherButton:nil informativeTextWithFormat:message] runModal];
            [self punchHoleInSandboxForFile:file];
        }
	}else{
        [[NSAlert alertWithMessageText:@"Was denied access to required files." defaultButton:@"Carry On" alternateButton:nil otherButton:nil informativeTextWithFormat:@"This software can not provide it's full functionality without access to certain files."] runModal];
    }
}

-(void)resetProperties
{
    self.directoryDict = [[NSMutableDictionary alloc] init];
    self.browserData = [[NSMutableArray alloc] init];
    self.directoryArray = [[NSMutableArray alloc] init];
    iSearchQueries = [[NSMutableArray alloc] init];
    
    
}

- (void)awakeFromNib {
    DLog(@"awakeFromNib");
    
    self.albumSortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]];
    
    [window setDelegate:self];  // we want to be notified when this window is closed
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(queryChildrenChanged:)
                                                 name:SearchQueryChildrenDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(searchItemChanged:)
                                                 name:SearchItemDidChangeNotification
                                               object:nil];
    
#ifdef DEBUG
    [self.browserView setCellsStyleMask:IKCellsStyleTitled | IKCellsStyleSubtitled];
#endif
    
    if ([[NSUserDefaults standardUserDefaults] valueForKey:@"searchLocationKey"]!=nil)
    {
        [self startLoading];
    }
}

- (void)startLoading {
    
    [self resetProperties];
    
    // look for the saved search location in NSUserDefaults
    NSError *error = nil;
    NSData *bookMarkDataToResolve = [[NSUserDefaults standardUserDefaults] objectForKey:@"searchLocationKey"];
    if (bookMarkDataToResolve)
    {
        // resolve the bookmark data into our NSURL
        self.searchLocation = [NSURL URLByResolvingBookmarkData:bookMarkDataToResolve
                                                        options:NSURLBookmarkResolutionWithSecurityScope
                                                  relativeToURL:nil
                                            bookmarkDataIsStale:nil
                                                        error:&error];
        [self.searchLocation startAccessingSecurityScopedResource];
    } else {
        //[self punchHoleInSandboxForFile:@"/Users/inzan/Dropbox/Camera Uploads"];
        [self importFilesAndDirectories:nil];
        
        return;
        /*NSOpenPanel *openPanel = [NSOpenPanel openPanel];
        [openPanel setAllowsMultipleSelection:NO];
        [openPanel setMessage:@"Choose a location to search for photos and images:"];
        [openPanel setCanChooseDirectories:YES];
        [openPanel setCanChooseFiles:NO];
        [openPanel setPrompt:@"Choose"];
        [openPanel setTitle:@"Choose Location"];
        
        // set the default location to the Documents folder
        NSArray *documentsFolderPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSURL *dbURL = [NSURL URLWithString:@"/Users/inzan/Documents/Dropbox"];
        [openPanel setDirectoryURL:dbURL];
        //[openPanel setDirectoryURL:[NSURL fileURLWithPath:[documentsFolderPath objectAtIndex:0]]];
        [openPanel beginSheetModalForWindow:window
                          completionHandler:^(NSInteger returnCode) {

                              NSLog(@"done open panel");
                          }];
        //[NSApp runModalForWindow:panel];
        //[window addChildWindow:panel ordered:NSWindowAbove];
        return;*/
    }
    
    
    

    

    /*iGroupRowCell = [[NSTextFieldCell alloc] init];
    [iGroupRowCell setEditable:NO];
    [iGroupRowCell setLineBreakMode:NSLineBreakByTruncatingTail];
    

    [resultsOutlineView setTarget:self];
    [resultsOutlineView setDoubleAction:@selector(resultsOutlineDoubleClickAction:)];
    
    NSString *placeHolderStr = NSLocalizedString(@"Select an item to show its location.", @"Placeholder string for location items");
    [[pathControl cell] setPlaceholderString:placeHolderStr];
    [pathControl setTarget:self];
    [pathControl setDoubleAction:@selector(pathControlDoubleClick:)];
    
    [predicateEditor setRowHeight:25];
    
    // add some rows
    [[predicateEditor enclosingScrollView] setHasVerticalScroller:NO];
    iPreviousRowCount = 3;
    [predicateEditor addRow:self];
    
    // put the focus in the text field
    id displayValue = [[predicateEditor displayValuesForRow:1] lastObject];
    if ([displayValue isKindOfClass:[NSControl class]])
        [window makeFirstResponder:displayValue];
    
    [self updatePathControl];*/
    
    
    

    
    if (self.searchLocation == nil)
    {
        DLog(@"No searchLocation specified!");
        assert(NO);
    } 
    
    // lastly, point our searchLocation NSPathControl to the search location
    [searchLocationPathControl setURL:self.searchLocation];
    [self createNewSearchForWithScopeURL:self.searchLocation];
    //[self updateRootSearchPath:self.searchLocation];
    

}

- (BOOL)windowShouldClose:(id)sender {
    NSLog(@"windowShouldClose was called");
    //for (SearchQuery *query in iSearchQueries) {
        // we are no longer interested in accessing SearchQuery's bookmarked search location,
        // so it's important we balance the start/stop access to security scoped bookmarks here
        //
        //[[query _searchURL] stopAccessingSecurityScopedResource];
    //}
    [self.searchLocation stopAccessingSecurityScopedResource];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    return YES;
}

-(void)showMainView
{
    [window setContentView:self.mainContentView];
}

//- (void)createNewSearchForPredicate:(NSPredicate *)predicate withTitle:(NSString *)title withScopeURL:(NSURL *)url
- (void)createNewSearchForWithScopeURL:(NSURL *)url {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(kMDItemContentTypeTree = 'public.image') OR  (kMDItemContentTypeTree = 'public.movie')"];

        
    //TODO: add video/custom query support
    //predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:imagesPredicate, predicate, nil]];
    
    // we are interested in accessing this bookmark for our SearchQuery class
    //NSURL *url = self.searchLocation;
    //[url startAccessingSecurityScopedResource];
    
    // Create an instance of our datamodel and keep track of things.
    SearchQuery *searchQuery = [[SearchQuery alloc] initWithSearchPredicate:predicate title:@"Search" scopeURL:url];
    [iSearchQueries addObject:searchQuery];
    //[searchQuery release];
    
    // Reload the children of the root item, "nil". This only works on 10.5 or higher
    /*[resultsOutlineView reloadItem:nil reloadChildren:YES];
    [resultsOutlineView expandItem:searchQuery];
    NSInteger row = [resultsOutlineView rowForItem:searchQuery];
    [resultsOutlineView scrollRowToVisible:row];
    [resultsOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];*/
    
}

-(NSMutableArray *)searchItemsFromResults:(NSArray *)children forDirectory:(NSString *)path
{
    DLog(@"Starting searchItemsFromResults");
    //NSMutableArray *tmpArray = [NSMutableArray arrayWithCapacity:[children count] ];
    for (SearchItem *item in children)
    {
        if ([self.browserData containsObject:item])
        {
            //assert(NO);
            continue;
        }
        //NSLog(@"item : %@", [item debugDescription]);

        NSString *fullPath = [item.metadataItem valueForAttribute:(NSString *)kMDItemPath];
        NSString *dirPath = [fullPath stringByDeletingLastPathComponent];
        Album *album = [self.directoryDict valueForKey:dirPath];
        if (album==nil)
        {
            album = [[Album alloc] initWithFilePath:dirPath];
            [self.directoryDict setValue:album forKey:dirPath];
            [self.directoryArray addObject:album];
            [self.tableView reloadData];
        }
        if (![album.photos containsObject:item])
        {
            [album addPhotosObject:item];
        }
        
    }
    Album *anAlbum = [self.directoryDict valueForKey:path];
    DLog(@"Finished searchItemsFromResults");
    return anAlbum.photos;
}

- (void)queryChildrenChanged:(NSNotification *)note {
    DLog(@"queryChildrenChanged : %@", note);
    
    SearchQuery *query = (SearchQuery *)[note object];
    DLog(@"Current album count     : %ld", self.directoryArray.count);
    DLog(@"incoming children count : %ld", query.children.count);
    //NSLog(@"children : %@", query.children);
    /*for (SearchItem *item in query.children)
    {
        NSLog(@"item : %@", [item debugDescription]);
        if (item.thumbnailImage!=nil)
        {
            IKBBrowserItem *bItem = [[IKBBrowserItem alloc] init];
            bItem.url = item.filePathURL;
            bItem.image = item.thumbnailImage;
            [self.browserData addObject:bItem];
        }
    }*/
    
    //Filter for the correct directory
    //NSString *path = [_item valueForAttribute:(NSString *)kMDItemPath];
    
    
    self.browserData = [self searchItemsFromResults:query.children forDirectory:[query._searchURL path]];//[NSMutableArray arrayWithArray:query.children];
    [self.browserView reloadData];
    //[resultsOutlineView reloadItem:[note object] reloadChildren:YES];
}

- (void)searchItemChanged:(NSNotification *)note {
    NSLog(@"searchItemChanged : %@", note);
    SearchItem *item = (SearchItem *)[note object];
    NSLog(@"item : %@", [item debugDescription]);
    /*if (item.thumbnailImage!=nil)
    {
        IKBBrowserItem *bItem = [[IKBBrowserItem alloc] init];
        bItem.url = item.filePathURL;
        bItem.image = item.thumbnailImage;
        [self.browserData addObject:bItem];
        [self.browserView reloadData];
    }*/
    // When an item changes, it only will affect the display state.
    // So, we only need to redisplay its contents, and not reload it
    /*NSInteger row = [resultsOutlineView rowForItem:[note object]];
    if (row != -1) {
        [resultsOutlineView setNeedsDisplayInRect:[resultsOutlineView rectOfRow:row]];
        if ([resultsOutlineView isRowSelected:row]) {
            [self updatePathControl];
        }
    }*/
}


-(void)refreshBrowser
{
    //[self.browserData removeAllObjects];
    //[self.browserView reloadData];
    //NSURL *url = self.searchLocation;
    
    //[self loadPhotosForURL:self.searchLocation];
    //[self loadSubDirectoryInfo:self.searchLocation];
    [self createNewSearchForWithScopeURL:self.searchLocation];
    //[self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    
    [self.browserView reloadData];
}

-(NSMutableArray *)albumArray;
{
    return self.directoryArray;//[self.directoryArray sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]];
    /*NSMutableArray *anArray = [[NSMutableArray alloc] init];
    for (id anObject in [self.directoryDict objectEnumerator])
    {
        [anArray addObject:anObject];
    }
    return anArray;*/
}

#pragma mark - NSPathControl support

-(void)updateRootSearchPath:(NSURL *)newRootSearchPath
{
    self.searchLocation = newRootSearchPath;
    NSData *bookmarkData = [self.searchLocation bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                                         includingResourceValuesForKeys:nil
                                                          relativeToURL:nil
                                                                  error:nil];
    DLog(@"updateRootSearchPath : %@", newRootSearchPath.path);
    if(bookmarkData){
        [[NSUserDefaults standardUserDefaults] setObject:bookmarkData forKey:@"searchLocationKey"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.searchLocation startAccessingSecurityScopedResource];
    }
    
    
    [self resetProperties];
    [self.tableView reloadData];
    [self createNewSearchForWithScopeURL:self.searchLocation];
}

//NSFilePathControl calls this when user selects a new root directory
- (IBAction)searchLocationChanged:(id)sender {
    
    NSURL *oldSearchURL = self.searchLocation;
    NSURL *newURL = (NSURL *)[sender URL];
    [self updateRootSearchPath:newURL];
    
    if (oldSearchURL!=nil)
    {
        [oldSearchURL stopAccessingSecurityScopedResource];
    }
    
    // write out the NSURL as a security-scoped bookmark to NSUserDefaults
    // (so that we can resolve it again at re-launch)
    //

    
    //self.directoryDict = [NSMutableDictionary dictionary];
    //Album *anAlbum = [[Album alloc] initWithFilePath:[[sender URL] path]];
    //self.selectedAlbum = anAlbum;
    
    
    
    
    
    //[self refreshBrowser];
    //[self.directoryArray removeAllObjects];
}

// -------------------------------------------------------------------------------
//	willDisplayOpenPanel:openPanel:
//
//	Delegate method to NSPathControl to determine how the NSOpenPanel will look/behave.
// -------------------------------------------------------------------------------
- (void)pathControl:(NSPathControl *)pathControl willDisplayOpenPanel:(NSOpenPanel *)openPanel {
    
    // customize the open panel to choose directories
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setMessage:@"Choose a location to search for photos and images:"];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:NO];
    [openPanel setPrompt:@"Choose"];
    [openPanel setTitle:@"Choose Location"];
    
    // set the default location to the Documents folder
    NSArray *documentsFolderPath = NSSearchPathForDirectoriesInDomains(NSUserDirectory, NSUserDomainMask, YES);
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:[documentsFolderPath objectAtIndex:0]]];
}



#pragma mark -

#pragma mark Browser Data Source Methods

- (NSUInteger) numberOfItemsInImageBrowser:(IKImageBrowserView *) aBrowser
{
	return [self.browserData count];
}

- (id) imageBrowser:(IKImageBrowserView *) aBrowser itemAtIndex:(NSUInteger)index
{
	return [self.browserData objectAtIndex:index];
}

/* implement some optional methods of the image-browser's datasource protocol to be able to remove and reoder items */

/*	remove
 The user wants to delete images, so remove these entries from our datasource.
 */
- (void)imageBrowser:(IKImageBrowserView *)view removeItemsAtIndexes:(NSIndexSet *)indexes
{
	[self.browserData removeObjectsAtIndexes:indexes];
    [self.browserView reloadData];
}

/* action called when the zoom slider did change */
- (IBAction)zoomSliderDidChange:(id)sender
{
	/* update the zoom value to scale images */
    [self.browserView setZoomValue:[sender floatValue]];
	
	/* redisplay */
    //[self.imageBrowserController.browserView setNeedsDisplay:YES];
}

// The only essential/required tableview dataSource method
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.albumArray count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    Album *album = [self.albumArray objectAtIndex:rowIndex];
    return album.title;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    NSLog(@"tableViewSelectionDidChange : %@", aNotification.object);
    if ([self.tableView selectedRow]==-1)
    {
        return;
    }
    Album *anAlbum =  [self.albumArray objectAtIndex:[self.tableView selectedRow]];
    self.selectedAlbum = anAlbum;
    
    //[self.browserData removeAllObjects];
    //[self.browserView reloadData];
   // NSURL *searchURL = [NSURL URLWithString:[newDir valueForKey:@"filePath"]];
    //Album *anAlbum = [self.directoryDict valueForKey:newDir.filePath];
    if (anAlbum!=nil)
    {
        self.browserData = anAlbum.photos;
        //[self.browserView reloadData];
    } else {
        //assert(NO);
        NSURL *searchURL = [NSURL URLWithString:[anAlbum valueForKey:@"filePath"]];
        [self createNewSearchForWithScopeURL:searchURL];
    }
    
    //[url startAccessingSecurityScopedResource];
    //[self loadPhotosForURL:searchURL];
    //[url stopAccessingSecurityScopedResource];
    [self.browserView reloadData];
}

// This method is optional if you use bindings to provide the data
/*- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    // Group our "model" object, which is a dictionary
    Album *album = (Album *)[self.albumArray objectAtIndex:row];
    
    
    // In IB the tableColumn has the identifier set to the same string as the keys in our dictionary
    NSString *identifier = [tableColumn identifier];
    //NSTableCellView *cellView = [tableView makeViewWithIdentifier:identifier owner:self];
    //cellView.objectValue = album;
    
    NSTextField *textField = [tableView makeViewWithIdentifier:identifier owner:self];
    textField.objectValue = album.title;
    return textField;
    
    / *if (!identifier || [identifier isEqualToString:@"MainCell"]) {
        
        
        
        // We pass us as the owner so we can setup target/actions into this main controller object
        
        // Then setup properties on the cellView based on the column
        //cellView.textField.stringValue = album.title;
        //cellView.imageView.image = [dictionary objectForKey:@"Image"];
    } /*else if ([identifier isEqualToString:@"SizeCell"]) {
        NSTextField *textField = [tableView makeViewWithIdentifier:identifier owner:self];
        NSImage *image = [dictionary objectForKey:@"Image"];
        NSSize size = image ? [image size] : NSZeroSize;
        NSString *sizeString = [NSString stringWithFormat:@"%.0fx%.0f", size.width, size.height];
        textField.objectValue = sizeString;
        return textField;
    } else {
        NSAssert1(NO, @"Unhandled table column identifier %@", identifier);
    }* /
    //return cellView;
}*/


// -------------------------------------------------------------------------------
//	imageBrowserSelectionDidChange:aBrowser
//
//	User chose a new image from the image browser.
// -------------------------------------------------------------------------------
- (void)imageBrowserSelectionDidChange:(IKImageBrowserView *)aBrowser
{
    
    NSLog(@"imageBrowserSelectionDidChange");
}

// -------------------------------------------------------------------------------
//  imageBrowser:cellWasDoubleClickedAtIndex:index
// -------------------------------------------------------------------------------
- (void)imageBrowser:(IKImageBrowserView *)aBrowser cellWasDoubleClickedAtIndex:(NSUInteger)index
{
    
    self.pageViewController = [[PageViewController alloc] initWithNibName:@"PageViewController" bundle:nil];
    NSInteger selectedRow = self.tableView.selectedRow;
    if (selectedRow<0 || selectedRow>[self.albumArray count]) {
        selectedRow = 0;
    }
    //NSURL *aURL = [NSURL fileURLWithPath:self.selectedAlbum.filePath isDirectory:YES];
    if (self.selectedAlbum == nil)
    {
        self.selectedAlbum = (Album*)[[self albumArray] objectAtIndex:selectedRow ];
    }
    
    //NSURL *aURL = [NSURL fileURLWithPath:[[[self albumArray] objectAtIndex:selectedRow ] valueForKey:@"filePath"]];
    self.pageViewController.album = self.selectedAlbum;
    self.pageViewController.initialSelectedItem = [self.selectedAlbum.photos objectAtIndex:index];
    
    self.pageViewController.parentWindowController = self;
    self.pageViewController.view.frame = ((NSView*)window.contentView).bounds;
    self.mainContentView = window.contentView;
    
    //self.pageViewController.pageController.selectedIndex = index;
    [window setContentView:self.pageViewController.view];
    
    NSLog(@"cellWasDoubleClickedAtIndex");
}


@end
