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
//@property (strong) WndWebView *wndWebViewController;




@end


@implementation AppDelegate
{
	HTTPServer *_server;
	long long timer_count;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    [self readSettingsFile];
    [self fillAddressesCombo];
	//----------------------------
	timer_count = 0;
	
	NSTimer*timer=[NSTimer scheduledTimerWithTimeInterval:5
												   target:self
												 selector:@selector(timerFired:)
												 userInfo:nil
												  repeats:YES];
}
- (void)timerFired:(NSTimer*)theTimer{
	self.timerLabel.stringValue = [NSString stringWithFormat:@"%lld", timer_count++ ];
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

//-(IBAction)actViewLog:(id)sender {
//    
//    self.wndWebViewController = [[WndWebView alloc] initWithWindowNibName:@"WndWebView"];
//	self.wndWebViewController.url = [NSString stringWithFormat:@"http://%@:%d", _server.host,_server.port];
//    [self.wndWebViewController showWindow:self];
//}

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
	
	@try {
		NSString *host =(NSString*) [self.cbAddresses objectValueOfSelectedItem];
		int port = (int)[self.fldPort integerValue];
		if(port == 0){
			self.fldPort.stringValue =@"13003";
			port = 13003;
		}
		_server = [[HTTPServer alloc] initWithHost:host andPort:port];
		[_server start];
		
		[_foldersView setDataSource:self];
	}
	@catch (NSException *exception) {
		NSLog(@"Exception .....");
	}
	@finally {
		
	}
	
}

-(IBAction)actStopServer:(id)sender {
	if(_server){
		[_server stop];
		_server = nil;
		[_foldersView setDataSource:nil];

	}
}

//- (void)applicationDidFinishLaunching:(NSNotification*)notification
//{
//	[tableView setDataSource:self];
//}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [_server.folders count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	
	NSString* returnValue=nil;
 
	// The column identifier string is the easiest way to identify a table column.
	NSString *columnIdentifer = [aTableColumn identifier];
 
	// Get the name at the specified row in namesArray
	NSDictionary *item = [_server.folders objectAtIndex:rowIndex];
 
 
	returnValue = item[columnIdentifer];
	return [NSString stringWithString:returnValue];
//	return [_server.folders objectAtIndex:rowIndex];
}


@end
