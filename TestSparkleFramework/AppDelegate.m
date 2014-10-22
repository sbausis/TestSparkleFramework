//
//  AppDelegate.m
//  TestSparkleFramework
//
//  Created by Simon Pascal Baur on 22/10/14.
//  Copyright (c) 2014 Simon Pascal Baur. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    //SUUpdater* updater = [[SUUpdater alloc] init];
    //SUUpdater* updater = [[SUUpdater alloc] initForBundle:(NSBundle *)];
    //SUUpdater* updater = [SUUpdater updaterForBundle:(NSBundle *)myBundle];
    SUUpdater* updater = [SUUpdater sharedUpdater];
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
