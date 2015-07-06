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
    
//    NSURL *url = [[NSBundle mainBundle] URLForResource:@"index" withExtension:@"html"];
    [self readSettingsFile];
    [self fillAddressesCombo];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
}


-(void)readSettingsFile {
    NSString *plistPath;
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                              NSUserDomainMask, YES) objectAtIndex:0];
    plistPath = [rootPath stringByAppendingPathComponent:@"Folders.plist"];
}

-(void)fillAddressesCombo {
    NSArray *ipAddresses =  [[NSHost currentHost] addresses];
    
    for(NSString *strAddress in ipAddresses) {
        [self.cbAddresses addItemWithObjectValue:strAddress];
    }
}

@end
