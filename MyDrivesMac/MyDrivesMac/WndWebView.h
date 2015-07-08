//
//  WndWebView.h
//  MyDrivesMac
//
//  Created by Coba on 7/6/15.
//  Copyright (c) 2015 cobasoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Webkit/WebKit.h>

@interface WndWebView : NSWindowController

@property (weak) IBOutlet WebView *webView;
@property (nonatomic) NSString *url;

@end
