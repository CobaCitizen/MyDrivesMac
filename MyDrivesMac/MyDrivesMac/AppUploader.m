//
//  AppUploader.m
//  MyDrivesMac
//
//  Created by Vasyl Bukshovan on 09/07/15.
//  Copyright (c) 2015 cobasoft. All rights reserved.
//
#import "HTTPServer.h"
#import "AppUploader.h"

@implementation AppUploader{
	NSFileHandle *file;
	NSString *action;

	long long size;
	long long filesize;
	long long start;
	long long end;
	long long total;
}

+ (void)load
{
	[HTTPResponseHandler registerHandler:self];
}

+ (BOOL)canHandleRequest:(CFHTTPMessageRef)aRequest
				  method:(NSString *)requestMethod
					 url:(NSURL *)requestURL
			headerFields:(NSDictionary *)requestHeaderFields
				 server : (HTTPServer*)server
{
	
	if(
	     [[requestURL path] isEqualToString:@"/open"]
	   ||[[requestURL path] isEqualToString:@"/continue"]
	   ||[[requestURL path] isEqualToString:@"/close"]
	   ){
		return YES;
	}
	return NO;
}
- (id)initWithRequest:(CFHTTPMessageRef)aRequest
			   method:(NSString *)method
				  url:(NSURL *)requestURL
		 headerFields:(NSDictionary *)requestHeaderFields
		   fileHandle:(NSFileHandle *)requestFileHandle
			   server:(HTTPServer *)aServer
{
	self = [super init];
	if (self != nil)
	{
		self.request = (__bridge CFHTTPMessageRef)(__bridge id)aRequest;
		self.requestMethod = method;
		self.url = requestURL;
		self.headerFields = requestHeaderFields;
		self.fileHandle = requestFileHandle;
		self.server = aServer;
		
		[[NSNotificationCenter defaultCenter]
			addObserver:self
			selector:@selector(receiveIncomingDataNotification:)
			name:NSFileHandleDataAvailableNotification
			object: self.fileHandle];
		
		[self.fileHandle waitForDataInBackgroundAndNotify];
	}
	return self;
}

/*
-(void) _closeFile{
	if(file != nil) {
		[file closeFile];
		file = nil;
		[self sendJsonString:[NSString stringWithFormat:@"{result:'ok',msg:'%@',offset:%lld}", action,end] closeConnect:NO];
	//	[self.server closeHandler:self];
	}
}
 */
-(void) _writeData:(NSData *) data {

		[file writeData:data];
		total -= data.length;
		NSLog([NSString stringWithFormat:@"total: %lld",total]);
		if(total <= 0){
			if(end >= filesize){
				action = @"close";
			}
//			[self sendJsonString:[NSString stringWithFormat:@"{result:'ok',msg:'%@',offset:%lld}", action,end] closeConnect:NO];
			[self.server closeHandler:self];
		}
}
-(void) _upload{
	
	NSString *s = self.headerFields[@"coba-file-info"];
	NSDictionary *prms = [self parseQueryString:s];
	
	NSString *name = [self.server redirect:[HTTPServer URLDecode:prms[@"name"]]];
	action = prms[@"action"];
	
	size = [NSString stringWithString:prms[@"size"]].longLongValue;
	filesize = [NSString stringWithString:prms[@"filesize"]].longLongValue;
	start = [NSString stringWithString:prms[@"start"]].longLongValue;
	end = [NSString stringWithString:prms[@"end"]].longLongValue;
	

	
	
	if(	 [[self.url path] isEqualToString:@"/open"]){
		[[NSFileManager defaultManager] createFileAtPath:name contents:nil attributes:nil];
		file = [NSFileHandle fileHandleForWritingAtPath:name];
	}
	else if([[self.url path] isEqualToString:@"/continue"]){
		file = [NSFileHandle fileHandleForUpdatingAtPath:name];
	}
	else if([[self.url path] isEqualToString:@"/close"]){
		file = [NSFileHandle fileHandleForUpdatingAtPath:name];
	}
	
	if (file == nil)
		NSLog(@"Failed to open file");
	
	[file seekToFileOffset: start];
	
    total = size;

	NSData *data = [self.fileHandle availableData];
	if(data.length > 0){
		[self _writeData:data];
	 }
//		@try {
//			NSData *data =	[self.fileHandle readDataOfLength:1024];
//			if(data.length == 0) break;
//			[file writeData:data];
//			total -= data.length;
//		}
//		@catch (NSException *exception) {
//			total = 0;
//		}
//		@finally {
//		}
//	}
//	[file closeFile];
//	[self sendJsonString:[NSString stringWithFormat:@"{result:'ok',msg:'%@',offset:%lld}", action,end]];
}
- (void)startResponse
{
	
	if(	 [[self.url path] isEqualToString:@"/open"]
	   ||[[self.url path] isEqualToString:@"/continue"]
	   ||[[self.url path] isEqualToString:@"/close"]){
		[self _upload];
		return;
	}
/*
	CFDataRef headerData;
	
	
	NSString *mime = [AppTextFileResponse getMimeType: _filePath];
	
	NSData *fileData =	[NSData dataWithContentsOfFile:_filePath];
	
	CFHTTPMessageRef response =	CFHTTPMessageCreateResponse(kCFAllocatorDefault, 200, NULL, kCFHTTPVersion1_1);
	CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Content-Type", (__bridge CFStringRef)mime);
	CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Connection", (CFStringRef)@"close");
	CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Content-Length",
									 (__bridge CFStringRef)[NSString stringWithFormat:@"%ld", [fileData length]]);
	headerData = CFHTTPMessageCopySerializedMessage(response);
	
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
 */
}
- (void)receiveIncomingDataNotification:(NSNotification *)notification
{
	NSFileHandle *incomingFileHandle = [notification object];
	NSData *data = [incomingFileHandle availableData];
	NSLog([NSString stringWithFormat:@"data length: %lu" , (unsigned long)[data length]]);

	if ([data length] == 0)
	{
		[self.server closeHandler:self];
	}
	else {
		[self _writeData:data];
		[incomingFileHandle waitForDataInBackgroundAndNotify];
	}
	
	//
	// This is a default implementation and simply ignores all data.
	// If you need the HTTP body, you need to override this method to continue
	// accumulating data. Don't forget that new data may need to be combined
	// with any HTTP body data that may have already been received in the
	// "request" body.
	//
	
	//[incomingFileHandle waitForDataInBackgroundAndNotify];
	
}
- (void)endResponse
{
	if(file != nil) {
		[file closeFile];
		file = nil;
	}
//	if (self.fileHandle) {
	//	[self sendJsonString:[NSString stringWithFormat:@"{result:'ok',msg:'%@',offset:%lld}", action,end]];
	//	[super endResponse];
//	}
	
	if (self.fileHandle)
	{
		
		[self sendJsonString:[NSString stringWithFormat:@"{result:'ok',msg:'%@',offset:%lld}", action,end] closeConnect:NO];
		
		[[NSNotificationCenter defaultCenter]
			removeObserver:self
			name:NSFileHandleDataAvailableNotification
			object:self.fileHandle];

		[self.fileHandle closeFile];
	    self.fileHandle = nil;
	}
	
	//[server release];
	//self.server = nil;
}


@end
