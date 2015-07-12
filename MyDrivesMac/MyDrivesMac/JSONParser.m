//
//  JSONParser.m
//  MyDrivesMac
//
//  Created by Vasyl Bukshovan on 08/07/15.
//  Copyright (c) 2015 cobasoft. All rights reserved.
//

#import "JSONParser.h"

@implementation JSONParser

+(NSString*) dictionaryToJson:(NSDictionary *) dic{
	
	NSString *json = @"{";
	
	int i =0;
	NSString *s;
	for(NSString *key in dic){
		id value = dic[key];

		if([value isKindOfClass:[NSString class]]){
			s = [NSString stringWithFormat:@"\"%@\":\"%@\"", key,value];
		}
		else if([value isKindOfClass:[NSNumber class]]){
			s = [NSString stringWithFormat:@"\"%@\":%lld", key, [value longLongValue]];
		}
		else {
		  s = [NSString stringWithFormat:@"\"%@\":\"%@\"", key,value];
		}
		if(i>0){
			json = [json stringByAppendingString:@","];
		}
		json = [json stringByAppendingString:s];
		i++;
	}
	json = [json stringByAppendingString:@"}"];
	return json;
}
+(NSString*) arrayToJson:(NSArray *) arr{
	
	NSString *json = @"[";
	for(int i =0; i < arr.count ; i++){
		NSDictionary *item = [arr objectAtIndex:i] ;
		NSString *s = [JSONParser dictionaryToJson:item];
		if(i>0){
			json = [json stringByAppendingString:@","];
		}
		json = [json stringByAppendingString:s];
	}
	json = [json stringByAppendingString:@"]"];
	return json;
}


@end
