//
//  AppDelegate.h
//  MyDrivesMac
//
//  Created by Coba on 7/6/15.
//  Copyright (c) 2015 cobasoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/Webkit.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (retain, nonatomic) IBOutlet WebView *myWebView;

@end

