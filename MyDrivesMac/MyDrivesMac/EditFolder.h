//
//  EditFolder.h
//  MyDrivesMac
//
//  Created by Vasyl Bukshovan on 16/07/15.
//  Copyright (c) 2015 cobasoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface EditFolder : NSWindowController

 
+(EditFolder*) currentForm;

+(void) showRecord:(NSString*)name folder:(NSString*)folder;

@property (nonatomic, retain) IBOutlet NSTextField *textName;
@property (nonatomic, retain) IBOutlet NSTextField *textFolder;
@property BOOL needSaveRecord;

-(IBAction)cancelEditRecord:(id) sender;
-(IBAction)applayEditRecord:(id) sender;
-(IBAction)showFolderSelector:(id) sender;
@end
