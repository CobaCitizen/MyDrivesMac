//
//  PList.h
//  MyDrivesMac
//
//  Created by Vasyl Bukshovan on 07/07/15.
//  Copyright (c) 2015 cobasoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PList : NSObject
//Convert Object(Dictionary,Array) to Plist(NSData)
+(NSData *) objToPlistAsData:(id)obj;

//Convert Object(Dictionary,Array) to Plist(NSString)
+(NSString *) objToPlistAsString:(id)obj;

//Convert Plist(NSData) to Object(Array,Dictionary)
+(id) plistToObjectFromData:(NSData *)data;

//Convert Plist(NSString) to Object(Array,Dictionary)
+(id) plistToObjectFromString:(NSString*)str;

@end
