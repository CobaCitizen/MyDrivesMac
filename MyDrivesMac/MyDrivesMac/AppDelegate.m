//
//  AppDelegate.m
//  MyDrivesMac
//
//  Created by Coba on 7/6/15.
//  Copyright (c) 2015 cobasoft. All rights reserved.
//

#import "AppDelegate.h"
#import "WndWebView.h"
#import "HTTPServer.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (strong) WndWebView *wndWebViewController;




@end


@implementation AppDelegate
{
	HTTPServer *_server;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

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
		if([strAddress isLike:@"*.*"]){
          [self.cbAddresses addItemWithObjectValue:strAddress];
		}
    }
	[self.cbAddresses selectItemAtIndex:0];
	self.fldPort.stringValue = @"13003";
}

-(IBAction)actViewLog:(id)sender {
    
    self.wndWebViewController = [[WndWebView alloc] initWithWindowNibName:@"WndWebView"];
	self.wndWebViewController.url = [NSString stringWithFormat:@"http://%@:%d", _server.host,_server.port];
    [self.wndWebViewController showWindow:self];
}

-(IBAction)actAddFolder:(id)sender {
}

-(IBAction)actRemoveFolder:(id)sender {
}

-(IBAction)actEditFolder:(id)sender {
}

-(IBAction)actGetFreePort:(id)sender {
}

-(IBAction)actStartServer:(id)sender {
	if(_server){
		return;
	}
	NSString *host =(NSString*) [self.cbAddresses objectValueOfSelectedItem];
	int port = (int)[self.fldPort integerValue];
	if(port == 0){
		self.fldPort.stringValue =@"13003";
		port = 13003;
	}
	_server = [[HTTPServer alloc] initWithHost:host andPort:port];
	[_server start];
	
}

-(IBAction)actStopServer:(id)sender {
	if(_server){
		[_server stop];
		_server = nil;
	}
}
@end
