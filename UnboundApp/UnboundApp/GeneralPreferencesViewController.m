
#import "GeneralPreferencesViewController.h"
#import "PIXFileParser.h"
#import "PIXAppDelegate.h"
#import "PIXDefines.h"

@interface GeneralPreferencesViewController ()

@property NSURL * pickerStartURL;
@property (weak) IBOutlet NSButton * dbFolderButton;
@property (weak) IBOutlet NSTextField * folderDisplay;

@property (strong) IBOutlet NSProgressIndicator * workingSpinner;

@end

@implementation GeneralPreferencesViewController

- (id)init
{
    return [super initWithNibName:@"GeneralPreferencesView" bundle:nil];
}

-(void)awakeFromNib
{
    // set the folder display
    
    [self updateFolderFeild];
    
    [self.workingSpinner bind:@"animate"
                     toObject:[PIXFileParser sharedFileParser]
                  withKeyPath:@"isWorking"
                      options: nil]; //@{NSValueTransformerNameBindingOption : NSNegateBooleanTransformerName}];
}

-(void)updateFolderFeild
{
    NSArray * directoryURLs = [[PIXFileParser sharedFileParser] observedDirectories];
    
    if([directoryURLs count])
    {
        self.folderDisplay.stringValue = [(NSURL *)[directoryURLs objectAtIndex:0] path];
    }
    
    else
    {
        self.folderDisplay.stringValue = @"No Folders Observed!";
    }
    
    // check to see if the dropbox folder exits
    NSURL * dropboxPhotosFolder = [[PIXFileParser sharedFileParser] defaultDBFolder];
    
    NSNumber * isDirectory;
    [dropboxPhotosFolder getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
    
    // if there is no dropbox photos folder or it's already selected then remove that option
    if(![isDirectory boolValue] || [[dropboxPhotosFolder path] isEqualToString:self.folderDisplay.stringValue])
    {
        [self.dbFolderButton setHidden:YES];
        self.pickerStartURL = [NSURL fileURLWithPath:@"~/"];
    }
    
    else
    {
        self.pickerStartURL = [NSURL fileURLWithPath:@"~/Dropbox/"];
    }
}

#pragma mark -
#pragma mark MASPreferencesViewController

- (NSString *)identifier
{
    return @"GeneralPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNamePreferencesGeneral];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"General", @"General Unbound Preferences");
}

-(IBAction)themeChanged:(id)sender
{
    // the user default (@"backgroundTheme") is changed through a binding. We just need to send out the notification

    [[NSNotificationCenter defaultCenter] postNotificationName:@"backgroundThemeChanged" object:nil];
}


- (IBAction)useDBDefaults:(id)sender
{
    [[PIXFileParser sharedFileParser] stopObserving];
    
    NSURL * dropboxPhotosFolder = [[PIXFileParser sharedFileParser] defaultDBFolder];
    NSURL * dropboxCUFolder = [[PIXFileParser sharedFileParser] defaultDBCameraUploadsFolder];
    
    
    [[PIXFileParser sharedFileParser] setObservedURLs:@[dropboxPhotosFolder, dropboxCUFolder]];
    
    [[PIXAppDelegate sharedAppDelegate] clearDatabase];
    
    [[PIXFileParser sharedFileParser] scanFullDirectory];
    
    [[PIXFileParser sharedFileParser] startObserving];
    
    
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kAppFirstRun];
        
    [self updateFolderFeild];
    
}

- (IBAction)chooseFolder:(id)sender
{
    // Create the File Open Dialog class.
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:NO];
    
    [openPanel setCanCreateDirectories:YES];
    [openPanel setDirectoryURL:self.pickerStartURL];
        
    [openPanel runModal];
    
    if([[openPanel URLs] count] == 1)
    {
        [[PIXFileParser sharedFileParser] stopObserving];
        
        [[PIXFileParser sharedFileParser] setObservedURLs:[openPanel URLs]];
        
        [[PIXAppDelegate sharedAppDelegate] clearDatabase];
        
        [[PIXFileParser sharedFileParser] scanFullDirectory];
        
        [[PIXFileParser sharedFileParser] startObserving];
        
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kAppFirstRun];
                
        [self updateFolderFeild];
    }
}

- (IBAction)reloadFiles:(id)sender
{
    [[PIXAppDelegate sharedAppDelegate] clearDatabase];
    [[PIXFileParser sharedFileParser] scanFullDirectory];
}

@end
