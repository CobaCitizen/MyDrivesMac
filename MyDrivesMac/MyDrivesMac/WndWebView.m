//
//  WndWebView.m
//  MyDrivesMac
//
//  Created by Coba on 7/6/15.
//  Copyright (c) 2015 cobasoft. All rights reserved.
//

#import "WndWebView.h"

@interface WndWebView ()

@end

@implementation WndWebView

- (void)windowDidLoad {
    [super windowDidLoad];
    
//    NSString *urlStr = @"http://www.google.com";
    [[self.webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_url]]];
    [[self.webView windowScriptObject] setValue:self forKey:@"objcConnector"];
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector{
    if (aSelector == @selector(elementClicked:)) return NO;
    return YES;
}
-(void)elementClicked:(id)object{
    //object is the id of the element
    
    // <button id="example" onClick="window.objcConnector.elementClicked_(this.id)">Click me</button>
}
@end
