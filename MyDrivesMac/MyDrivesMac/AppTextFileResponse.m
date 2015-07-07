//
//  AppTextFileResponse.m
//  TextTransfer
//
//  Created by Matt Gallagher on 2009/07/13.
//  Copyright 2009 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import "AppTextFileResponse.h"
#import "HTTPServer.h"


NSString *_filePath;

@implementation AppTextFileResponse{

}


//
// load
//
// Implementing the load method and invoking
// [HTTPResponseHandler registerHandler:self] causes HTTPResponseHandler
// to register this class in the list of registered HTTP response handlers.
//
+ (void)load
{
	[HTTPResponseHandler registerHandler:self];
}

//
// canHandleRequest:method:url:headerFields:
//
// Class method to determine if the response handler class can handle
// a given request.
//
// Parameters:
//    aRequest - the request
//    requestMethod - the request method
//    requestURL - the request URL
//    requestHeaderFields - the request headers
//
// returns YES (if the handler can handle the request), NO (otherwise)
//
+ (BOOL)canHandleRequest:(CFHTTPMessageRef)aRequest
	method:(NSString *)requestMethod
	url:(NSURL *)requestURL
	headerFields:(NSDictionary *)requestHeaderFields
	server : (HTTPServer*)server
{

	if([[requestURL path] isEqualTo:@"/get.folder"]){
		return YES;
	}

	if([requestURL.path isEqualTo:@"/"]){
		_filePath = [NSString stringWithFormat: [server site] ,@"/index.html"];
		return YES;
	}
	
	_filePath = [NSString stringWithFormat:[server site],requestURL.path];
	
	
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:_filePath];
	if (!exists)
	{
		NSLog(@"File not found : %@", _filePath);
		return  NO;
	}

	return YES;
}


+(NSString*) getMimeType : (NSString *) filePath{

	NSString *ext = [filePath pathExtension];
	
	
	NSDictionary *dic = @{
		@"ico" : @"image/x-icon",
		@"html" : @"text/html",
		@"js" : @"text/javascript",
		@"css" : @"text/css",
		@"woff2" :@"application/octet-stream"
								};

	NSString *mime = dic[ext];

	if(mime == nil){
		NSLog(@"Extention not found :%@",ext);
		return @"application/octet-stream";
	}
	//return @"application/octet-stream";

	return mime;
	
}

-(NSString*) _dictionaryToJson:(NSDictionary *) dic{

	NSString *json = @"{";
	
	int i =0;
	for(NSString *key in dic){
		NSString *value = dic[key];
		NSString *s = [NSString stringWithFormat:@"\'%@\':\'%@\'", key,value];
		
		if(i>0){
			json = [json stringByAppendingString:@","];
		}
		json = [json stringByAppendingString:s];
		i++;
	}
	json = [json stringByAppendingString:@"}"];
	return json;
}
-(NSString*) _arrayToJson:(NSArray *) arr{
	
	NSString *json = @"[";
	for(int i =0; i < arr.count ; i++){
		NSDictionary *item = [arr objectAtIndex:i] ;
		NSString *s = [self _dictionaryToJson:item];
		if(i>0){
			json = [json stringByAppendingString:@","];
		}
		json = [json stringByAppendingString:s];
	}
	json = [json stringByAppendingString:@"]"];
	return json;
}

-(NSDictionary*) _parseQueryString{
	
  NSArray *parameters = [[[self url] query] componentsSeparatedByString:@"&"];
  
  NSMutableDictionary *dic = [NSMutableDictionary dictionary];
  
  for (NSString *param in parameters)
  {
	  NSArray *para = [param componentsSeparatedByString:@"="];
	  if ( [para count] == 2 )
	  {
		  dic[para[0]] = para[1];
	  }
	  else
	  {
		  dic[para[0]] = para[0];
	  }
  }
	return dic;
}
-(void) _sendJsonString:(NSString *)json{
	
	
	
	NSData *data =	[json dataUsingEncoding:NSUTF8StringEncoding];
	
	CFHTTPMessageRef response =	CFHTTPMessageCreateResponse(kCFAllocatorDefault, 200, NULL, kCFHTTPVersion1_1);
	CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Content-Type", (__bridge CFStringRef)@"text/json");
	CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Connection", (CFStringRef)@"close");
	CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Content-Length",
									 (__bridge CFStringRef)[NSString stringWithFormat:@"%ld", [data length]]);
	CFDataRef headerData = CFHTTPMessageCopySerializedMessage(response);
	
	@try
	{
		[self.fileHandle writeData:(__bridge NSData *)headerData];
		[self.fileHandle writeData:data];
	}
	@catch (NSException *exception)
	{
		// Ignore the exception, it normally just means the client
		// closed the connection from the other end.
	}
	@finally
	{
		CFRelease(headerData);
		[self.server closeHandler:self];
	}

}
-(void ) _sendFolder{
	
	NSDictionary *dic = [self _parseQueryString];

	NSString *folder = dic[@"folder"];
	
	if([folder isEqualTo:@"root"]){
		NSString *json = [self _arrayToJson:[self.server folders]];
		[self _sendJsonString:json];
		return;
	}
	else{
		
	}
}
//
// startResponse
//
// Since this is a simple response, we handle it synchronously by sending
// everything at once.
//
- (void)startResponse
{
	
	if([[self.url path] isEqualTo:@"/get.folder"]){
		[self _sendFolder];
		return;
	}
	if([self.requestMethod isEqualTo:@"GET"]){
		
	}
	NSString *mime = [AppTextFileResponse getMimeType: _filePath];
	//NSLog(@"File : %@", _filePath);
	NSData *fileData =	[NSData dataWithContentsOfFile:_filePath];
  	CFHTTPMessageRef response =	CFHTTPMessageCreateResponse(kCFAllocatorDefault, 200, NULL, kCFHTTPVersion1_1);
	CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Content-Type", (__bridge CFStringRef)mime);
	CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Connection", (CFStringRef)@"close");
	CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Content-Length",
		(__bridge CFStringRef)[NSString stringWithFormat:@"%ld", [fileData length]]);
	CFDataRef headerData = CFHTTPMessageCopySerializedMessage(response);

	@try
	{
		[self.fileHandle writeData:(__bridge NSData *)headerData];
		[self.fileHandle writeData:fileData];
	}
	@catch (NSException *exception)
	{
		// Ignore the exception, it normally just means the client
		// closed the connection from the other end.
	}
	@finally
	{
		CFRelease(headerData);
		[self.server closeHandler:self];
	}
}

//
// pathForFile
//
// In this sample application, the only file returned by the server lives
// at a fixed location, whose path is returned by this method.
//
// returns the path of the text file.
//
+ (NSString *)pathForFile
{
//	NSString *path =
//		[NSSearchPathForDirectoriesInDomains(
//				NSApplicationSupportDirectory,
//				NSUserDomainMask,
//				YES)
//			objectAtIndex:0];
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:_filePath];
	if (!exists)
	{
//		[[NSFileManager defaultManager]
//			createDirectoryAtPath:path
//			withIntermediateDirectories:YES
//			attributes:nil
//			error:nil];
		
	}
	return _filePath; //[path stringByAppendingPathComponent:@"file.txt"];
}

@end
