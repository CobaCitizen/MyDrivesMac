//
//  JSONParser.h
//  MyDrivesMac
//
//  Created by Vasyl Bukshovan on 08/07/15.
//  Copyright (c) 2015 cobasoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JSONParser : NSObject

+(NSString*) dictionaryToJson:(NSDictionary *) dic;
+(NSString*) arrayToJson:(NSArray *) arr;

@end
