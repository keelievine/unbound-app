//
// Created by Ryan Harter on 3/13/18.
// Copyright (c) 2018 Pixite Apps LLC. All rights reserved.
//

import Foundation

class GeneralPrefsViewController: NSViewController, MASPreferencesViewController {

  private var pickerStartURL: NSURL?

  @IBOutlet weak var dbFolderButton: NSButton?
  @IBOutlet weak var folderDisplay: NSPathControl?
  @IBOutlet weak var workingSpinner: NSProgressIndicator?

  //MARK - MASPreferencesViewController
  private(set) var viewIdentifier: String = "General"
  private(set) var toolbarItemLabel: String? = NSLocalizedString("preferences.general.title", comment: "General")
  private(set) var toolbarItemImage: NSImage? = NSImage(named: .preferencesGeneral)

  override func viewDidLoad() {
    super.viewDidLoad()
    updateFolderField()
  }

  private func updateFolderField() {
    let urls = PIXFileParser.shared().observedDirectories
    if (urls == nil || urls!.isEmpty) {
      self.folderDisplay?.url = nil
    } else {
      self.folderDisplay?.url = urls![0]
    }
  }

  //MARK - IBActions

  @IBAction func chooseFolder(sender: NSButton) {
    PIXFileParser.shared().userChooseFolderDialog()
    updateFolderField()
  }

  @IBAction func reloadFiles(sender: NSButton) {
    PIXFileParser.shared().rescanFiles()
  }

  @IBAction func resetAlerts(sender: NSButton) {
    UserDefaults.standard.set(false, forKey: kPrefSupressDeleteWarning)
    UserDefaults.standard.set(false, forKey: kPrefSupressAlbumDeleteWarning)
  }

}
