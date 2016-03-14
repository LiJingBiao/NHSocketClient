//
//  AppDelegate.m
//  NHSocketClient
//
//  Created by hu jiaju on 16/3/11.
//  Copyright © 2016年 hu jiaju. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    NSApplication *app = [NSApplication sharedApplication];
    NSWindow *window = app.keyWindow;
    CGSize size = [[NSScreen mainScreen] frame].size;
    [[window standardWindowButton:NSWindowZoomButton] setEnabled:false];
    [window setMinSize:CGSizeMake(1000, 500)];
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
