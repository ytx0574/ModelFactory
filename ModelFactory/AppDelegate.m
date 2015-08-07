//
//  AppDelegate.m
//  ModelFactory
//
//  Created by Johnson on 6/8/15.
//  Copyright (c) 2015 Johnson. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag;
{
    [sender.windows.firstObject makeKeyAndOrderFront:self];
    return YES;
}

@end
