//
//  AppDelegate.m
//  MyDrivesMac
//
//  Created by Coba on 7/6/15.
//  Copyright (c) 2015 cobasoft. All rights reserved.
//

#import "AppDelegate.h"


@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;


@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {


    NSString *urlText = @"file://Users/maksim/Projects/MyDrivesMac/MyDrivesMac/index.html";
    NSURL *url = [NSURL URLWithString:urlText];
    [[self.myWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
}

@end
