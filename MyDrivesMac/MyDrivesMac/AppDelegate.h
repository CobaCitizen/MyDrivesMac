//
//  AppDelegate.h
//  MyDrivesMac
//
//  Created by Coba on 7/6/15.
//  Copyright (c) 2015 cobasoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource>

@property (nonatomic, retain) NSMutableArray *dataFolders;

@property (nonatomic, retain) IBOutlet NSComboBox *cbAddresses;
@property (nonatomic, retain) IBOutlet NSTextField *fldPort;
@property (nonatomic, retain) IBOutlet NSTextField *timerLabel;
@property (nonatomic, retain) IBOutlet NSTableView *foldersView;


@end

