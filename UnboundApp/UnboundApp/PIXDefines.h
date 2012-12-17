//
//  PIXDefines.h
//  UnboundApp
//
//  Created by Bob on 12/13/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#ifndef UnboundApp_PIXDefines_h
#define UnboundApp_PIXDefines_h

static const NSString *ALBUM = @"ALBUM";
static const NSString *PHOTO = @"PHOTO";


static NSString *AlbumCreatedNotification = @"AlbumCreatedNotification";
static NSString *AlbumDidChangeNotification = @"AlbumDidChangeNotification";
static NSString *AlbumDeletedNotification = @"AlbumDeletedNotification";

static const NSString *kUB_ALBUMS_LOADED_FROM_FILESYSTEM = @"UB_ALBUMS_LOADED_FROM_FILESYSTEM";

#define FFString(msg, description) NSLocalizedStringFromTableInBundle(msg, @"Unbound", [NSBundle bundleForClass:[PIXMainWindowController class]], description)

// ===========================
// = Constant Localized NSStrings =
// ===========================

#define MSG_WINDOW_TITLE                     FFString(@"Unbound",       @"Default window title.")


#endif
