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
	NSString *outputFileName;
	
	long long size;
	long long filesize;
	long long start;
	long long end;
	long long total;
	long long readed;
	
	BOOL needWaitData;
	NSFileHandle *incomingFileHandle;
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
		needWaitData =YES;
		readed = 0;
		
		[[NSNotificationCenter defaultCenter]
			addObserver:self
			selector:@selector(receiveIncomingDataNotification:)
			name:NSFileHandleDataAvailableNotification
			object: self.fileHandle];

//		[[NSNotificationCenter defaultCenter]
//			addObserver:self
//			selector:@selector(incomingDataException:)
//			name:NSFileHandleOperationException
//			object:self.fileHandle];
		
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
	total += [data length];
	
   	if(total == size){
		needWaitData = NO;
//		NSLog([NSString stringWithFormat:@"=0.total: %lld size:%lld rest:%lld",total, size,(filesize - end -1)]);
		[self.server closeHandler:self];
		return;
	}
	if(total < size) {
		[incomingFileHandle waitForDataInBackgroundAndNotify];
		return;
	}
	
	if(end >= filesize) {
		action = @"close";
//		NSLog([NSString stringWithFormat:@"<0.total: %lld size:%lld rest:%lld",total, size,(filesize - end -1)]);
//			needWaitData = NO;
			[self.server closeHandler:self];
//			return;
	}
//		else {
//			if(total != 0 && total <4096){
//				NSLog([NSString stringWithFormat:@"<4096.total: %lld readed:%lld size:%lld rest:%lld",_TOTAL, readed, size,(filesize - end -1)]);
//				[self.server closeHandler:self];
////				return;
//			}

}
-(void) _parseParameters{
	
	NSString *s = self.headerFields[@"coba-file-info"];
	NSDictionary *prms = [self parseQueryString:s];
	
	outputFileName = [self.server redirect:[HTTPServer URLDecode:prms[@"name"]]];
	action = prms[@"action"];
	
	size = [NSString stringWithString:prms[@"size"]].longLongValue;
//	size = [NSString stringWithString:self.headerFields[@"Content-Length"]].longLongValue;
	filesize = [NSString stringWithString:prms[@"filesize"]].longLongValue;
	start = [NSString stringWithString:prms[@"start"]].longLongValue;
	end = [NSString stringWithString:prms[@"end"]].longLongValue;
	
	total = 0;
//	NSLog([NSString stringWithFormat:@"size:%lld total:%lld start:%lld end:%lld fsize:%lld ",
//		   size, total,start, end, filesize ]);
	
	if(size <=0 ){ //|| filesize - end <=0){
		
		action = @"close";
		total = filesize - end;
		[self.server closeHandler:self];
		return;
	}
	
	
	long long rest =(filesize - end - 1);
	
//	NSLog([NSString stringWithFormat:@"rest:%lld total:%lld delta:%lld", rest , total , (end - start) ]);

	if(	 [[self.url path] isEqualToString:@"/open"]){
		[[NSFileManager defaultManager] createFileAtPath:outputFileName contents:nil attributes:nil];
		file = [NSFileHandle fileHandleForWritingAtPath:outputFileName];
	}
	else if([[self.url path] isEqualToString:@"/continue"]){
		file = [NSFileHandle fileHandleForUpdatingAtPath:outputFileName];
	}
	else if([[self.url path] isEqualToString:@"/close"]){
		file = [NSFileHandle fileHandleForUpdatingAtPath:outputFileName];
	}
	
	if (file == nil)
		NSLog(@"Failed to open file");
	
	[file seekToFileOffset: start];

	if(start < 0 || end <= 0){
		NSLog(@"Failed to open file");
	}
}
- (void)startResponseWithBody:(NSData *)body{
	
	[self _parseParameters];
	
	[self _writeData:body];
	if(total <= 0 ){
		[self.server closeHandler:self];
		return;
	}
	
	NSData *data = [self.fileHandle availableData];
	if(data.length > 0){
		[self _writeData:data];
		if(total <= 0 ){
			[self.server closeHandler:self];
			return;
		}
	}

}

- (void)startResponse
{
	
	[self _parseParameters];
	
	NSData *data = [self.fileHandle availableData];
	if(data.length > 0){
		[self _writeData:data];
		if(total <= 0 ){
			[self.server closeHandler:self];
			return;
		}
	}
	
	
}
//- (void)incomingDataException:(NSNotification *)notification{
//	NSLog(@"Exception ...............");
//}
- (void)receiveIncomingDataNotification:(NSNotification *)notification
{
	NSData *data;
	incomingFileHandle = [notification object];
	data = [incomingFileHandle availableData];
	if ([data length] == 0)
	{
		[self.server closeHandler:self];
	}
	else {
		[self _writeData:data];
	}
	if(data != nil) {
	//	CFRelease((__bridge CFTypeRef)data);
	}

}
- (void)endResponse
{

	if(file != nil) {
		[file closeFile];
		file = nil;
	}

	if (self.fileHandle)
	{
		NSString *json =[NSString stringWithFormat:@"{result:'ok',msg:'%@',offset:%lld}", action,end] ;
		[self sendJsonString:json closeConnect:NO];
		
		[[NSNotificationCenter defaultCenter]
			removeObserver:self
			name:NSFileHandleDataAvailableNotification
			object:self.fileHandle];

		[self.fileHandle closeFile];
	    self.fileHandle = nil;
	}
	self.server = nil;
	incomingFileHandle = nil;
	outputFileName = nil;
	action = nil;
}


@end
