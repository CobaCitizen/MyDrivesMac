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
#import "JSONParser.h"



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

	if(  [[requestURL path] isEqualToString:@"/mkdir"]
	   ||[[requestURL path] isEqualToString:@"/get.folder"]
	 //  ||[[requestURL path] isEqualToString:@"/open"]
	 //  ||[[requestURL path] isEqualToString:@"/continue"]
	 //  ||[[requestURL path] isEqualToString:@"/close"]
	   ){
		return YES;
	}

	if([requestURL.path isEqualTo:@"/"]){
		//self.filePath = [NSString stringWithFormat: [server site] ,@"/index.html"];
		return YES;
	}
	if([requestURL.path  characterAtIndex:1] == '~'){
		//NSString *s = [HTTPServer URLDecode:requestURL.path];
		//_filePath = [server redirect:[s substringFromIndex:1]];
		return YES;
	}
	
	//_filePath = [NSString stringWithFormat:[server site],[HTTPServer URLDecode:requestURL.path]];
	
	
//	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:_filePath];
//	if (!exists)
//	{
//		NSLog(@"File not found : %@", _filePath);
//		return  NO;
//	}

	return YES;
}


+(NSString*) getMimeType : (NSString *) filePath{

	NSString *ext = [filePath pathExtension];
	
	
	NSDictionary *dic = @{
		@"ico" : @"image/x-icon",
		@"html" : @"text/html",
		@"js" : @"text/javascript",
		@"css" : @"text/css",
		@"woff" :@"application/octet-stream",
		@"mov" :@"video/quicktime",
		@"mp4" :@"video/quicktime",
		@"pdf" :@"application/pdf",
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

/*
-(NSNumber *) _getFileSize:(NSFileManager*) manager filePath:(NSString*) path{
	NSNumber * size = [NSNumber numberWithUnsignedLongLong:[[ manager attributesOfItemAtPath:path error:nil] fileSize]];
	return size;
}*/
-(void ) _sendFolder{
	
	NSDictionary *dic = [self parseQueryString];

	NSString *folder = dic[@"folder"];
	
	if([folder isEqualTo:@"root"]){
		NSString *json = [JSONParser arrayToJson:[self.server folders]];
		[self sendJsonString:json closeConnect:YES];
		return;
	}
	else{
		
		// TODO use simple string for response
		NSString *decoded =[HTTPServer URLDecode:folder];
		NSString *dir = [self.server redirect: decoded];

		NSFileManager *fileManager = [NSFileManager defaultManager];
		if ([fileManager fileExistsAtPath:dir]) {
			BOOL isDir = NO;
			[fileManager fileExistsAtPath:dir isDirectory:(&isDir)];
			if (isDir == YES) {


				NSMutableArray *data = [NSMutableArray new];
				
				NSArray *contents = [fileManager contentsOfDirectoryAtPath:dir error:nil];
				for (NSString *entity in contents) {
					
					NSString *filePath = [NSString stringWithFormat:@"%@/%@", dir,entity];
				
					NSDictionary *attr = [ fileManager attributesOfItemAtPath:filePath error:nil];
					NSString *type = attr[@"NSFileType"];
					if([type isEqualToString:@"NSFileTypeDirectory"] ){ // file
						NSMutableDictionary *d = [NSMutableDictionary new];
						[d setValue:entity forKey:@"name"];
						[d setValue:[NSNumber numberWithInt:1] forKey:@"d"];
						[d setValue:[NSNumber numberWithFloat:0] forKey:@"size"];
						[data addObject:d];
					}
					else{ //folder
						NSMutableDictionary *d = [NSMutableDictionary new];
						[d setValue:entity forKey:@"name"];
						[d setValue:[NSNumber numberWithInt:0] forKey:@"d"];
						filePath = [NSString stringWithFormat:@"%@%@", dir,entity];
						//[d setValue:[self _getFileSize:fileManager filePath:filePath] forKey:@"size"];
						[d setValue: attr[@"NSFileSize"] forKey:@"size"];
						[data addObject:d];
					}
				}
				NSString *json = [JSONParser arrayToJson:data];
				[self sendJsonString:json closeConnect:YES];

			} else {
				NSLog(@"%@ is not a directory", dir);
			}
		} else {
			NSLog(@"%@ does not exist", dir);
		}
	}
}
-(void) _parseRange:(NSString*)range start:(long long*) start end:(long long*) end chunck:(long long*) chunck fileSize:(unsigned long long) size{
	
	NSString *s =[range stringByReplacingOccurrencesOfString:@"bytes=" withString:@""];
	NSArray *ranges = [s componentsSeparatedByString:@"-"];
	
	NSString *r1 = ranges[0];
	NSString *r2 = ranges[1];
	
	*start = r1.longLongValue;
	*end   = r2.longLongValue;

	if( *end <= 0){
		*end = size -1;
	}
	*chunck = *end - *start +1;
}

-(void) _sendPartialFile:(long long)start chunck:(long long ) chunck{

	FILE *fd = fopen([filePath cStringUsingEncoding:NSUTF8StringEncoding], "rb");
	if(fd == NULL)
		return; // handle error
	
	const int BUFFER_SIZE = 128 * 1024;
	char *buffer = (char*)malloc(BUFFER_SIZE * sizeof(char));
	
	NSData *data;
	
	fseek(fd, start,SEEK_SET);
	
	while (chunck > 0) {
		

		size_t readed = fread(buffer, 1, BUFFER_SIZE, fd);
		if(readed < BUFFER_SIZE)
			break;

		data = [NSData dataWithBytesNoCopy:buffer length:readed];
		@try {
			[self.fileHandle writeData:data];
			chunck -= readed;
		}
		@catch (NSException *exception) {
			chunck = -1;
			break;
		}
		@finally {
			
		}
	}
	free(buffer);
	fclose(fd);
	
}
-(BOOL) _writeData2:(NSData *) data{
	@try {
		[self.fileHandle writeData:data];
		return YES;
	}
	@catch (NSException *exception) {
		return NO;
	}
	@finally {
	}

}
-(void) _sendForNSPlayer:(NSString*) range{

	NSNumber* size = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil][@"NSFileSize"];
	
	long long start,end,chunck;
	[self _parseRange:range start:&start end:&end chunck:&chunck fileSize:size.longLongValue];

	if(end == -1){
		end = size.longLongValue -1;
		chunck = end - start + 1;
	}
		

	NSString *mime = [AppTextFileResponse getMimeType: filePath];
	
	CFHTTPMessageRef response =	CFHTTPMessageCreateResponse(kCFAllocatorDefault, 206, NULL, kCFHTTPVersion1_1);
	CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Content-Type", (__bridge CFStringRef)mime);
	CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Connection", (CFStringRef)@"close");
	CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Content-Length",(__bridge CFStringRef)[NSString stringWithFormat:@"%lld", chunck]);
	CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Accept-Ranges",(CFStringRef)@"bytes");
	CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Content-Range",
									 (__bridge CFStringRef)[NSString stringWithFormat:@"bytes %lld-%lld/%lld",start,end,size.longLongValue]);

	CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"TransferMode.DLNA.ORG",(CFStringRef)@"Streaming");
	CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Access-Control-Allow-Origin",(CFStringRef)@"*");
	CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"File-Size",
									 (__bridge CFStringRef)[NSString stringWithFormat:@"%lld", size.longLongValue]);;
	
	CFDataRef headerData = CFHTTPMessageCopySerializedMessage(response);
	/*
	//[self _sendPartialFile:start chunck:chunck];
	[self.fileHandle writeData:(__bridge NSData *)headerData];

	
	FILE *fd = fopen([filePath cStringUsingEncoding:NSUTF8StringEncoding], "rb");
	if(fd == NULL)
		return; // handle error
	
	const int BUFFER_SIZE = 64 * 1024;
	char buffer[BUFFER_SIZE];
	
	
	fseek(fd, start,SEEK_SET);
	
	@try {
	while (chunck > 0) {
		
		size_t readed = fread(buffer, 1, BUFFER_SIZE, fd);
		if(readed < BUFFER_SIZE)
			break;
		NSData *data = [NSData dataWithBytes:buffer length:readed];
		if(![self _writeData2:data]) break;
		chunck -= readed;
      }
	}
	@catch (NSException *exception) {

	}
	@finally {
		CFRelease(headerData);
		headerData = nil;
		CFRelease(response);
		response = nil;
	}
	
	fclose(fd);

	 

//	CFRelease(headerData);
//	headerData = nil;
//	CFRelease(response);
//	response = nil;
	
	[self.server closeHandler:self];
*/

	NSFileHandle *file;
	//NSData *buffer;
	@try
	{
		[self.fileHandle writeData:(__bridge NSData *)headerData];
		
		file = [NSFileHandle fileHandleForReadingAtPath: filePath ];
		
		if (file == nil)
			NSLog(@"Failed to open file");
		
		[file seekToFileOffset: start];
		
		while (chunck > 0) {
			
			
			NSData *buffer = [file readDataOfLength: 128*1024];
			if (buffer.length > 0) {
				[self.fileHandle writeData:buffer];
			//	[self.fileHandle synchronizeFile];
				chunck -= buffer.length;
			}
			else break;

		
			buffer = nil;
		}
	}
	@catch (NSException *exception)
	{
		// Ignore the exception, it normally just means the client
		// closed the connection from the other end.
	}
	@finally
	{
		CFRelease(headerData);
		headerData = nil;
		CFRelease(response);
		response = nil;
		
//		buffer = nil;
		
		[self.server closeHandler:self];
		[file closeFile];
		file=nil;
	}
}
-(void) _sendForMacRange:(NSString*) range {

	NSNumber* size = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil][@"NSFileSize"];
	long long start,end,chunck;
	[self _parseRange:range start:&start end:&end chunck:&chunck fileSize:size.longLongValue];

	NSString *mime = [AppTextFileResponse getMimeType: filePath];

	CFHTTPMessageRef response =	CFHTTPMessageCreateResponse(kCFAllocatorDefault, 206, NULL, kCFHTTPVersion1_1);
	CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Content-Type", (__bridge CFStringRef)mime);
	CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Connection", (CFStringRef)@"close");
	CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Content-Length",(__bridge CFStringRef)[NSString stringWithFormat:@"%lld", chunck]);
	CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Accept-Ranges",(CFStringRef)@"bytes");
	CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Content-Range",
									 (__bridge CFStringRef)[NSString stringWithFormat:@"bytes %lld-%lld/%lld",start,end,size.longLongValue]);
	
	CFDataRef headerData = CFHTTPMessageCopySerializedMessage(response);

	
	NSFileHandle *file;
//	NSData *buffer;
	@try
	{
	//if([self writeResponseData:(__bridge NSData *)headerData]) {
		[self.fileHandle writeData:(__bridge NSData *)headerData];
	
		file = [NSFileHandle fileHandleForReadingAtPath: filePath];
		
		if (file == nil)
			NSLog(@"Failed to open file");
		
		[file seekToFileOffset: start];
		
		
		while (chunck > 0) {
	
			NSData *buffer = [file readDataOfLength: 64*1024 ];
			if (buffer.length > 0) {
				[self.fileHandle writeData:buffer];
			//	[self.fileHandle synchronizeFile];
				chunck -= buffer.length;
			}
			else break;
			
			buffer = nil;
	//	}
	}
	}
	@catch (NSException *exception)
	{
		// Ignore the exception, it normally just means the client
		// closed the connection from the other end.
	}
	@finally
	{
		CFRelease(headerData);
		headerData = nil;
		CFRelease(response);
		response = nil;
		
//		buffer = nil;
		
		[self.server closeHandler:self];
		[file closeFile];
		file=nil;
	}
}
-(void) _createDirectory{

	NSDictionary *prms = [self parseQueryString];
	
	NSString *folder = prms[@"folder"];
	folder = [self.server redirect: [HTTPServer URLDecode:folder]];
	
	NSString *subfolder = [HTTPServer URLDecode:prms[@"name"]];
	NSString *directory = [NSString stringWithFormat:@"%@/%@" , folder, subfolder];
	NSError *error = nil;
	if(![ [ NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error]) {
		
		[self sendJsonString:[NSString stringWithFormat:@"{result:false,msg:\'Failed to create directory %@. Error: %@\'}", directory, error]
		 closeConnect:YES];
		return;
	}
	
	[self sendJsonString:@"{result:true,msg:'created'}" closeConnect:YES];
}

-(NSString *) makeFilePath:(NSString *)url {
	NSString* fileName = [[url lastPathComponent] stringByDeletingPathExtension];
	NSString* extension = [url pathExtension];
	return [[NSBundle mainBundle] pathForResource:fileName ofType:extension];
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
	if([[self.url path] isEqualToString:@"/mkdir"]){
		[self _createDirectory];
		return;
	}
	
	if([[self.url path] isEqualTo:@"/"]){
		filePath = [NSString stringWithString: [self makeFilePath:@"/index.html"]];
	}
	else if([[self.url path]  characterAtIndex:1] == '~'){
		NSString *s = [HTTPServer URLDecode:[self.url path]];
		filePath = [self.server redirect:[s substringFromIndex:1]];
	}
	else {
		filePath = [self makeFilePath:[self.url path]];
	}
	
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
	if (!exists)
	{
		NSLog(@"File not found : %@", filePath);
	}
	
	CFDataRef headerData;
	
	NSString *range = self.headerFields[@"Range"];
	if(range != nil){
		[self _sendForMacRange:range];
		return;
	}
	NSString *userAgent = self.headerFields[@"User-Agent"];
	
	if ([userAgent containsString:@"NSPlayer/"]) {
		[self _sendForNSPlayer:range];
		return;
	}
	
	NSString *mime = [AppTextFileResponse getMimeType: filePath];

	NSData *fileData =	[NSData dataWithContentsOfFile: filePath];
	
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
		CFRelease(response);
		fileData = nil;
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
/*
+ (NSString *)pathForFile
{
//	NSString *path =
//		[NSSearchPathForDirectoriesInDomains(
//				NSApplicationSupportDirectory,
//				NSUserDomainMask,
//				YES)
//			objectAtIndex:0];
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
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
*/
@end
