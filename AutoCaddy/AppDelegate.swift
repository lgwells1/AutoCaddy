//
//  AppDelegate.swift
//  AutoCaddy
//
//  Created by SESA251707 on 12/11/14.
//  Copyright (c) 2014 Larry Wells. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    var statusBar = NSStatusBar.systemStatusBar()
    var statusBarItem : NSStatusItem = NSStatusItem()
    var menu: NSMenu = NSMenu()
    var menuItem : NSMenuItem = NSMenuItem()
    var preferences : NSMenuItem = NSMenuItem()
    var exit : NSMenuItem = NSMenuItem()
    var rocketIcon:NSImage = NSImage(named: "rocket")!
    @IBOutlet weak var comboBox: NSComboBox!
    @IBOutlet weak var textboxAppPath: NSTextField!
    @IBOutlet weak var textboxName: NSTextField!
    @IBOutlet weak var lblStatusUpdate: NSTextField!
    @IBOutlet weak var selectedAppName: NSTextField!
    @IBOutlet weak var selectedAppPath: NSTextField!
    @IBOutlet weak var runatLogin: NSButton!

    

    override func awakeFromNib() {
        //Add statusBarItem
        statusBarItem = statusBar.statusItemWithLength(-1)
        statusBarItem.menu = menu
        var menuIcon:NSImage = NSImage(named:"menubaricon")!
        statusBarItem.image = menuIcon
        //Add line seperator
        menu.addItem(NSMenuItem.separatorItem())
        
        //Add Preferences to menu
        menu.addItemWithTitle("Preferences", action: Selector("showPreferencesWindow:"), keyEquivalent: "")
        var preferencesIcon:NSImage = NSImage(named:"preferences")!
        menu.itemWithTitle("Preferences")?.image = preferencesIcon
        
        //Add Exit to menu
        menu.addItemWithTitle("Exit", action: Selector("ExitApplication:"), keyEquivalent: "")
        var exitIcon:NSImage = NSImage(named:"exit")!
        menu.itemWithTitle("Exit")?.image = exitIcon
        //Load User Data
        loadData()
        //Check for run at login
        if(applicationIsInStartUpItems() == true)
        {
            runatLogin.state = 1
        }
    }
    
    //Create button
    @IBAction func btnCreate(sender: NSButton) {
        var appDel:AppDelegate = (NSApplication.sharedApplication().delegate as AppDelegate)
        var context:NSManagedObjectContext = appDel.managedObjectContext!
        var request = NSFetchRequest(entityName: "Apps")
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "name = %@", textboxName.stringValue)
        var results:NSArray = context.executeFetchRequest(request, error: nil)!
        var alert:NSAlert = NSAlert()
        var objectExist:Bool = false
        if(results.count > 0)
        {
            for res2 in results
            {
                if (res2.name == textboxName.stringValue)
                {
                    objectExist = true
                    println("\(res2.name) exist")
                }
            }
            
        }
        
        if (textboxName.stringValue.isEmpty || textboxAppPath.stringValue.isEmpty)
        {
            statusUpdate("Error: Name or Path may be missing.")
        }
        
        else
        {
            if (objectExist == true)
            {
                alert.messageText = "Error: Object with \(textboxName.stringValue) already exist. Please use a different name."
                alert.runModal()
                println("Error: Object with \(textboxName.stringValue) already exist. Please use a different name.")
            }
                
            else
            {
                var newApp = NSEntityDescription.insertNewObjectForEntityForName("Apps", inManagedObjectContext: context) as NSManagedObject
                newApp.setValue(textboxName.stringValue, forKey: "name")
                newApp.setValue(textboxAppPath.stringValue, forKey: "path")
                comboBox.addItemWithObjectValue(newApp.valueForKey("name") as String)
                createMenuItem(textboxName.stringValue)
                statusUpdate("Added: \(textboxName.stringValue)")
                println(newApp)
            }

        }
        
        
    }
    
    
    //Action for app selected in Combobox
    @IBAction func appSelected(sender: NSComboBoxCell) {
        var appDel:AppDelegate = (NSApplication.sharedApplication().delegate as AppDelegate)
        var context:NSManagedObjectContext = appDel.managedObjectContext!
        var request = NSFetchRequest(entityName: "Apps")
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "name = %@", sender.stringValue)
        var results:NSArray = context.executeFetchRequest(request, error: nil)!
        var appPath = ""
        if(results.count > 0)
        {
            //  var res : NSManagedObject = NSManagedObject()
            for var i = 0; i < results.count; i++
            {
                var res = results[i] as NSManagedObject
                selectedAppName.stringValue = res.valueForKey("name") as String
                selectedAppPath.stringValue = res.valueForKey("path") as String
            }
        }
        else
        {
            println("0 Results")
        }

    }
    
    //Delete Button for selected combobox item
    @IBAction func btnComboBoxDelete(sender: NSButton) {
        var itemIndex = comboBox.indexOfSelectedItem
        var error: NSErrorPointer = NSErrorPointer()
        var appDel:AppDelegate = (NSApplication.sharedApplication().delegate as AppDelegate)
        var context:NSManagedObjectContext = appDel.managedObjectContext!
        var request = NSFetchRequest(entityName: "Apps")
        request.returnsObjectsAsFaults = false
        //request.predicate = NSPredicate(format: "name = %@", tempMenuItem.title)
        var results:NSArray = context.executeFetchRequest(request, error: nil)!

        println("Found \(results.count) objects")
        if(results.count > 0)
        {
            for res in results
            {
                if(res.name == comboBox.stringValue)
                    
                {
                    var tempMenuItem:NSMenuItem = NSMenuItem()
                    println("Found data object: \(res.name)")
                    comboBox.removeItemAtIndex(comboBox.indexOfSelectedItem)
                    
                    //Check for item in menu
                    if(menu.itemWithTitle(res.name) != nil)
                    {
                        menu.removeItem(menu.itemWithTitle(res.name)!)
                    }
                    context.deleteObject(res as NSManagedObject)
                    context.save(error)
                    statusUpdate("Removed")
                    println("Success!")
                }
                
            }

        }
        else
        {
            println("Error Deleting Object \(comboBox.stringValue)")
            println(error)
        }

    }
    
    //Load data when at program startup
    func loadData()
    {
        var appDel:AppDelegate = (NSApplication.sharedApplication().delegate as AppDelegate)
        var context:NSManagedObjectContext = appDel.managedObjectContext!
        var sortByName:NSSortDescriptor = NSSortDescriptor(key: "name", ascending: true)    //Sort results alphabetically
        var sortDescriptors = [sortByName]
        var request = NSFetchRequest(entityName: "Apps")
        request.returnsObjectsAsFaults = false
        var pathValidation:NSFileManager = NSFileManager.defaultManager()
        var results:NSArray = context.executeFetchRequest(request, error: nil)!
        request.sortDescriptors = sortDescriptors
        var alert:NSAlert = NSAlert()
        
        if(results.count > 0)
        {
            //  var res : NSManagedObject = NSManagedObject()
            for var i = 0; i < results.count; i++
            {
                var res = results[i] as NSManagedObject
                var appName = res.valueForKey("name") as String
                var appPath = res.valueForKey("path") as String
                println("Loading...\(appName)")
                //Check path for valid app
                if(pathValidation.fileExistsAtPath(appPath))
                {
                    createMenuItem(appName)
                    comboBox.addItemWithObjectValue(appName)
                    println("Added: \(appName)")
                }
                else
                {
                    alert.messageText = "Error Loading File: File \(appName) does not exist at \(appPath)"
                    alert.runModal()
                    println("File Does Not Exist: \(appPath)")
                    comboBox.addItemWithObjectValue(appName)
                }
            }
        }
        else
        {
            println("0 Results")
        }

    }
    
    //Show About Window
    @IBAction func showAboutWindow(sender: AnyObject)
    {
        [NSApp.activateIgnoringOtherApps(true)]
        [NSApp.orderFrontStandardAboutPanel(sender)]
    }
    
    
    //Run At Login Checked 
    @IBAction func runatLogin(sender: AnyObject)
    {
        toggleLaunchAtStartup()
    }
    
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    //Exit App
    func ExitApplication(sender: NSMenuItem)
    {
        NSApplication.sharedApplication().terminate(self)
    }
    
    //Show Preferences Window
    func showPreferencesWindow(sender: AnyObject)
    {
        [window.makeKeyAndOrderFront(self)]
        [NSApp.activateIgnoringOtherApps(true)]
    }
    
    //Add menuitem to menu
    func createMenuItem(name:String)
    {
        var exist = false
        for menuItem in menu.itemArray
        {
            println(menuItem)
            if(menu.itemWithTitle(name) != nil)
            {
                exist = true
            }
            
        }
        
        if(exist == false)
        {
            menu.insertItemWithTitle(name, action: Selector("runSelectedApp:"), keyEquivalent: "", atIndex: 0)
            menu.itemWithTitle(name)?.image = rocketIcon
        }
       

    }
    
    
    //Run Selected App
    func runSelectedApp(sender: NSMenuItem)
    {
        var workspace : NSWorkspace = NSWorkspace()
        var pathValidation:NSFileManager = NSFileManager.defaultManager()
        var alert:NSAlert = NSAlert()
        let tempMenuItem = sender
        var appDel:AppDelegate = (NSApplication.sharedApplication().delegate as AppDelegate)
        var context:NSManagedObjectContext = appDel.managedObjectContext!
        var request = NSFetchRequest(entityName: "Apps")
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "name = %@", tempMenuItem.title)
        var results:NSArray = context.executeFetchRequest(request, error: nil)!
        var appPath = ""
        var appName = ""
        if(results.count > 0)
        {
            //  var res : NSManagedObject = NSManagedObject()
            for var i = 0; i < results.count; i++
            {
                var res = results[i] as NSManagedObject
                appPath = res.valueForKey("path") as String
                appName = res.valueForKey("name") as String
            }
        }
        else
        {
            println("0 Results")
        }
        if(pathValidation.fileExistsAtPath(appPath))
        {
            workspace.launchApplication(appPath)
        }
        else
        {
            alert.messageText = "Error Loading File: File \(appName) does not exist at \(appPath)"
            alert.runModal()
            println("File Does Not Exist: \(appPath)")
        }
        
    }
    
    //Status Update Label Func
    func statusUpdate(message: String)
    {
        lblStatusUpdate.stringValue = message
        var timer = NSTimer.scheduledTimerWithTimeInterval(1.5, target: self, selector: Selector("clearStatusLabel"), userInfo: nil, repeats: false)
    }
    
    //Clear name/path/status text values
    func clearStatusLabel()
    {
        lblStatusUpdate.stringValue = ""
        textboxName.stringValue = ""
        textboxAppPath.stringValue = ""
        selectedAppName.stringValue = ""
        selectedAppPath.stringValue = ""
        if(comboBox.stringValue != "")
       {
        comboBox.stringValue = ""
       }
        
        
    }
    
    //Startup Code
    func applicationIsInStartUpItems() -> Bool {
        return (itemReferencesInLoginItems().existingReference != nil)
    }
    
    func itemReferencesInLoginItems() -> (existingReference: LSSharedFileListItemRef?, lastReference: LSSharedFileListItemRef?) {
        var itemUrl : UnsafeMutablePointer<Unmanaged<CFURL>?> = UnsafeMutablePointer<Unmanaged<CFURL>?>.alloc(1)
        if let appUrl : NSURL = NSURL.fileURLWithPath(NSBundle.mainBundle().bundlePath) {
            let loginItemsRef = LSSharedFileListCreate(
                nil,
                kLSSharedFileListSessionLoginItems.takeRetainedValue(),
                nil
                ).takeRetainedValue() as LSSharedFileListRef?
            if loginItemsRef != nil {
                let loginItems: NSArray = LSSharedFileListCopySnapshot(loginItemsRef, nil).takeRetainedValue() as NSArray
                println("There are \(loginItems.count) login items")
                let lastItemRef: LSSharedFileListItemRef = loginItems.lastObject as LSSharedFileListItemRef
                for var i = 0; i < loginItems.count; ++i {
                    let currentItemRef: LSSharedFileListItemRef = loginItems.objectAtIndex(i) as LSSharedFileListItemRef
                    if LSSharedFileListItemResolve(currentItemRef, 0, itemUrl, nil) == noErr {
                        if let urlRef: NSURL =  itemUrl.memory?.takeRetainedValue() {
                            println("URL Ref: \(urlRef.lastPathComponent)")
                            if urlRef.isEqual(appUrl) {
                                return (currentItemRef, lastItemRef)
                            }
                        }
                    } else {
                        println("Unknown login application")
                    }
                }
                //The application was not found in the startup list
                return (nil, lastItemRef)
            }
        }
        return (nil, nil)
    }
    
    func toggleLaunchAtStartup() {
        let itemReferences = itemReferencesInLoginItems()
        let shouldBeToggled = (itemReferences.existingReference == nil)
        let loginItemsRef = LSSharedFileListCreate(
            nil,
            kLSSharedFileListSessionLoginItems.takeRetainedValue(),
            nil
            ).takeRetainedValue() as LSSharedFileListRef?
        if loginItemsRef != nil {
            if shouldBeToggled {
                if let appUrl : CFURLRef = NSURL.fileURLWithPath(NSBundle.mainBundle().bundlePath) {
                    LSSharedFileListInsertItemURL(
                        loginItemsRef,
                        itemReferences.lastReference,
                        nil,
                        nil,
                        appUrl,
                        nil,
                        nil
                    )
                    println("Application was added to login items")
                }
            } else {
                if let itemRef = itemReferences.existingReference {
                    LSSharedFileListItemRemove(loginItemsRef,itemRef);
                    println("Application was removed from login items")
                }
            }
        }
    }

    // CORE DATA BELOW
    // CORE DATA BELOW
    // CORE DATA BELOW
    // CORE DATA BELOW
    // CORE DATA BELOW
    // CORE DATA BELOW
    // CORE DATA BELOW
    // CORE DATA BELOW
    // CORE DATA BELOW
    // CORE DATA BELOW
    // CORE DATA BELOW
    // CORE DATA BELOW
    // CORE DATA BELOW
    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.LarryWells.AutoCaddy" in the user's Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask)
        let appSupportURL = urls[urls.count - 1] as NSURL
        return appSupportURL.URLByAppendingPathComponent("com.LarryWells.AutoCaddy")
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("AutoCaddy", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.) This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        let fileManager = NSFileManager.defaultManager()
        var shouldFail = false
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."

        // Make sure the application files directory is there
        let propertiesOpt = self.applicationDocumentsDirectory.resourceValuesForKeys([NSURLIsDirectoryKey], error: &error)
        if let properties = propertiesOpt {
            if !properties[NSURLIsDirectoryKey]!.boolValue {
                failureReason = "Expected a folder to store application data, found a file \(self.applicationDocumentsDirectory.path)."
                shouldFail = true
            }
        } else if error!.code == NSFileReadNoSuchFileError {
            error = nil
            fileManager.createDirectoryAtPath(self.applicationDocumentsDirectory.path!, withIntermediateDirectories: true, attributes: nil, error: &error)
        }
        
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator?
        if !shouldFail && (error == nil) {
            coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
            let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("AutoCaddy.storedata")
            if coordinator!.addPersistentStoreWithType(NSXMLStoreType, configuration: nil, URL: url, options: nil, error: &error) == nil {
                coordinator = nil
            }
        }
        
        if shouldFail || (error != nil) {
            // Report any error we got.
            let dict = NSMutableDictionary()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            if error != nil {
                dict[NSUnderlyingErrorKey] = error
            }
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            NSApplication.sharedApplication().presentError(error!)
            return nil
        } else {
            return coordinator
        }
    }()

    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving and Undo support

    @IBAction func saveAction(sender: AnyObject!) {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        if let moc = self.managedObjectContext {
            if !moc.commitEditing() {
                NSLog("\(NSStringFromClass(self.dynamicType)) unable to commit editing before saving")
            }
            var error: NSError? = nil
            if moc.hasChanges && !moc.save(&error) {
                NSApplication.sharedApplication().presentError(error!)
            }
        }
    }

    func windowWillReturnUndoManager(window: NSWindow) -> NSUndoManager? {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        if let moc = self.managedObjectContext {
            return moc.undoManager
        } else {
            return nil
        }
    }

    func applicationShouldTerminate(sender: NSApplication) -> NSApplicationTerminateReply {
        // Save changes in the application's managed object context before the application terminates.
        
        if let moc = managedObjectContext {
            if !moc.commitEditing() {
                NSLog("\(NSStringFromClass(self.dynamicType)) unable to commit editing to terminate")
                return .TerminateCancel
            }
            
            if !moc.hasChanges {
                return .TerminateNow
            }
            
            var error: NSError? = nil
            if !moc.save(&error) {
                // Customize this code block to include application-specific recovery steps.
                let result = sender.presentError(error!)
                if (result) {
                    return .TerminateCancel
                }
                
                let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
                let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
                let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
                let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
                let alert = NSAlert()
                alert.messageText = question
                alert.informativeText = info
                alert.addButtonWithTitle(quitButton)
                alert.addButtonWithTitle(cancelButton)
                let answer = alert.runModal()
                if answer == NSAlertFirstButtonReturn {
                    return .TerminateCancel
                }
            }
        }
        // If we got here, it is time to quit.
        return .TerminateNow
    }

}

