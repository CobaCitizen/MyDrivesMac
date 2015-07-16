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
#import "EditFolder.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;

@end


@implementation AppDelegate
{
	HTTPServer *_server;
	long long _timer_count;
	NSMutableDictionary *_settings;
	NSMutableArray *_folders;
	
	NSTimer *_timer;
	NSDateFormatter *_dateFormatter;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    [self fillAddressesCombo];
	
	_settings = [HTTPServer loadServerSettings];
	_folders = _settings[@"folders"];
	
	[_foldersView reloadData];
	
	_timer_count = 0;
	_dateFormatter = [[NSDateFormatter alloc]init];
	[_dateFormatter setDateFormat:@"dd.MM.YY HH:mm:ss"];
	[self.timerLabel setStringValue:@"Server Stopped"];
	
}
- (void)timerFired:(NSTimer*)theTimer{
	self.timerLabel.stringValue = [NSString stringWithFormat:@"%lld", _timer_count++ ];
	
	NSDate *currDate = [NSDate date];
	[self.timerLabel setStringValue:[_dateFormatter stringFromDate:currDate]];
}
- (void)applicationWillTerminate:(NSNotification *)aNotification {
}


//-(void)readSettingsFile {
//    NSString *plistPath;
//    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
//                                                              NSUserDomainMask, YES) objectAtIndex:0];
//    plistPath = [rootPath stringByAppendingPathComponent:@"Folders.plist"];
//}

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
-(IBAction)actAddFolder:(id)sender {
	
	[EditFolder showRecord: @"~New Name" folder:@"/Users/"];
	
	EditFolder *frm = [EditFolder currentForm];
	if(frm.needSaveRecord){
		NSMutableDictionary * item = [NSMutableDictionary new];
		item[@"name"] = frm.textName.stringValue;
		item[@"path"] = frm.textFolder.stringValue;
    	[item setValue: [NSNumber numberWithInt:1] forKey:@"d"];
		[_folders addObject:item];
		[HTTPServer saveSettings:_settings];
		[_foldersView reloadData];
	}
	[frm close];

	return;
}
-(IBAction)actRemoveFolder:(id)sender {
	NSInteger index = [self.foldersView selectedRow];
	if(index == -1){
		[self _showMessage:@"Select record for edit!"];
		return;
	}
	
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"Delete"];
	[alert addButtonWithTitle:@"Cancel"];
	[alert setMessageText:@"Delete the record?"];
	[alert setInformativeText:@"Deleted records cannot be restored."];
	[alert setAlertStyle:NSWarningAlertStyle];
	
	if ([alert runModal] == NSAlertFirstButtonReturn) {
		[_folders removeObjectAtIndex:index];
		[HTTPServer saveSettings:_settings];
		[_foldersView reloadData];
	}
	alert = nil;
}
-(IBAction)actEditFolder:(id)sender {
	NSInteger index = [self.foldersView selectedRow];
	if(index == -1){
		[self _showMessage:@"Select record for edit!"];
		return;
	}
	NSMutableDictionary *item = _folders[index];
	[EditFolder showRecord: item[@"name"] folder:item[@"path"]];
	
	EditFolder *frm = [EditFolder currentForm];
	if(frm.needSaveRecord){
		item[@"name"] = frm.textName.stringValue;
		item[@"path"] = frm.textFolder.stringValue;
		[HTTPServer saveSettings:_settings];
	}
	[frm close];
	return;
}

-(IBAction)actGetFreePort:(id)sender {
}
-(void)_stopTimer{
	if(_timer != nil){
		[_timer invalidate];
		_timer = nil;
    	[self.timerLabel setStringValue:@"Server Stopped"];
	}
}
-(void) _showMessage:(NSString*) message{
	
	NSAlert *alert = [[NSAlert alloc] init] ;
	[alert setMessageText:message];
	[alert setAlertStyle:NSCriticalAlertStyle];
	[alert setInformativeText:@"Message"];
	[alert runModal];
	
}

-(void) _showServerError{

	NSString *errorName = _server.lastError.description;
	
	NSAlert *alert = [[NSAlert alloc] init] ;
	[alert setMessageText:errorName];
	[alert setAlertStyle:NSCriticalAlertStyle];
	[alert setInformativeText:@"Error"];
	[alert runModal];
	
	_server = nil;
	[self _stopTimer];
	
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
		
		if(_server.lastError != nil) {
			[self _showServerError];
		}
		else {
			_timer=[NSTimer scheduledTimerWithTimeInterval:1
													target:self
												  selector:@selector(timerFired:)
												  userInfo:nil
												   repeats:YES];
		}
	}
	@catch (NSException *exception) {

	}
	@finally {
		
	}
	
}

-(IBAction)actStopServer:(id)sender {
	if(_server){
		[_server stop];
		_server = nil;
	}
	[self _stopTimer];
}

//- (void)applicationDidFinishLaunching:(NSNotification*)notification
//{
//	[tableView setDataSource:self];
//}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [_folders count];
}
//- (void)tableView:(NSTableView *)tableView
//  willDisplayCell:(id)cell
//  forTableColumn:(NSTableColumn *)tableColumn
//  row:(NSInteger)row;
//{
//	NSDictionary *item = [_server.folders objectAtIndex:row];
//	[cell setTitle:@"Name"];
//	NSString *name = [cell title];
//	[cell setState:item[name] ];
//}
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	
	NSString* returnValue=nil;
 
	NSString *columnIdentifer = [aTableColumn identifier];
 
	NSDictionary *item = [_folders objectAtIndex:rowIndex];
 
	returnValue = item[columnIdentifer];
	return [NSString stringWithString:returnValue];
}
//- (NSView *)tableView:(NSTableView *)tableView
//   viewForTableColumn:(NSTableColumn *)tableColumn
//	row:(NSInteger)row {
//
//	NSString *columnIdentifer = [tableColumn identifier];
//
//	NSTableCellView *result = [tableView makeViewWithIdentifier:columnIdentifer owner:self];
//	
//	NSDictionary *item = [_server.folders objectAtIndex:row];
// 
//	NSString *returnValue = item[columnIdentifer];
//	result.textField.stringValue = item[columnIdentifer];
//
//	// Return the result
//	return result;
//}

@end
