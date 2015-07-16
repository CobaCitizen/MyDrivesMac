//
//  EditFolder.m
//  MyDrivesMac
//
//  Created by Vasyl Bukshovan on 16/07/15.
//  Copyright (c) 2015 cobasoft. All rights reserved.
//
#import "HTTPServer.h"
#import "EditFolder.h"



@interface EditFolder ()


@end

static EditFolder* currentForm = nil;


@implementation EditFolder

+(void) showRecord:(NSString*)name folder:(NSString*)folder{
	
	EditFolder *frm = [[EditFolder alloc] initWithWindowNibName:@"EditFolder"];
	
	currentForm = frm;
	
	NSWindow *wnd = [frm window];
	[wnd center];
	[wnd orderFront: self];
	
	[frm.textFolder setStringValue:folder];
	[frm.textName setStringValue:name];

	[NSApp runModalForWindow: wnd];
}
+(EditFolder*) currentForm{
	return currentForm;
}
- (void)windowDidLoad {
    [super windowDidLoad];
	self.needSaveRecord = NO;
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}
- (void)windowWillClose:(NSNotification *)notification {
//	[NSApp stopModal];
}
-(IBAction) cancelEditRecord:(id) sender{
//	[self close];
	[NSApp stopModal];
}
-(IBAction) applayEditRecord:(id) sender{
	self.needSaveRecord = YES;
//	[self close];
   [NSApp stopModal];
}

-(IBAction)showFolderSelector:(id) sender{
	
	NSOpenPanel* panel = [NSOpenPanel openPanel];
	[panel setCanChooseDirectories:YES];
	[panel setCanCreateDirectories:YES];


	[panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){
		if (result == NSFileHandlingPanelOKButton) {
			NSArray* urls = [panel URLs];
			if([urls count] == 1) {
				NSURL *url = urls[0];
			//	[self _applaySelectedFolder:[url path]];
				[self.textFolder setStringValue: [NSString stringWithFormat:@"%@/" , [HTTPServer URLDecode:[url path]]]];

			}
		}
	}];
}
@end
