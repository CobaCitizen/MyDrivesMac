//
//  HTTPServer.m
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

#import "HTTPServer.h"
#import "SynthesizeSingleton.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <netdb.h>
#import "HTTPResponseHandler.h"
#import "PList.h"
#import "AppUploader.h"

#define HTTP_SERVER_PORT 8080

NSString * const HTTPServerNotificationStateChanged = @"ServerNotificationStateChanged";

//
// Internal methods and properties:
//	The "lastError" and "state" are only writable by the server itself.
//
@interface HTTPServer ()
@property (nonatomic, readwrite) NSError *lastError;
@property (readwrite, assign) HTTPServerState state;
@end

@implementation HTTPServer
//@property (nonatomic, @synthesize lastError;
@synthesize state;
@synthesize lastError;

//SYNTHESIZE_SINGLETON_FOR_CLASS(HTTPServer);


+(NSString*) MyDrivesFolder{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *directory = [NSString stringWithFormat:@"%@/MyDrivesMac/",[paths objectAtIndex:0]];
	
	
	NSFileManager *fileManager= [NSFileManager defaultManager];
	BOOL isDir;
	if([fileManager fileExistsAtPath:directory isDirectory: &isDir]){
		return directory;
	}
	NSError *error = nil;
	if(![fileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error]) {
		// An error has occurred, do something to handle it
		NSLog(@"Failed to create directory \"%@\". Error: %@", directory, error);
	}
	return  directory;
}
+(NSString*) DocumentFolder{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	return [NSString stringWithFormat:@"%@/",[paths objectAtIndex:0]];
}
+(NSString*) MoviesFolder{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSMoviesDirectory, NSUserDomainMask, YES);
	return [NSString stringWithFormat:@"%@/",[paths objectAtIndex:0]];
}
+(NSString*) MusicFolder{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSMusicDirectory, NSUserDomainMask, YES);
	return [NSString stringWithFormat:@"%@/",[paths objectAtIndex:0]];
}

//
// init
//
// Set the initial state and allocate the responseHandlers and incomingRequests
// collections.
//
// returns the initialized server object.
//
- (id)init
{
	self = [super init];
	if (self != nil)
	{
		self.state = SERVER_STATE_IDLE;
		responseHandlers = [[NSMutableSet alloc] init];
		incomingRequests =
			CFDictionaryCreateMutable(
				kCFAllocatorDefault,
				0,
				&kCFTypeDictionaryKeyCallBacks,
				&kCFTypeDictionaryValueCallBacks);
	}
	return self;
}
-(id) initWithHost:(NSString*) host andPort:(int)port{

	
	self = [super init];
	if (self != nil)
	{
		_host = [NSString stringWithString:host];
		_port = port;
		
		self.state = SERVER_STATE_IDLE;
		responseHandlers = [[NSMutableSet alloc] init];
		incomingRequests =
		CFDictionaryCreateMutable(
								  kCFAllocatorDefault,
								  0,
								  &kCFTypeDictionaryKeyCallBacks,
								  &kCFTypeDictionaryValueCallBacks);
	}
	return self;
}
//
// setLastError:
//
// Custom setter method. Stops the server and 
//
// Parameters:
//    anError - the new error value (nil to clear)
//
- (void)setLastError:(NSError *)anError
{
	//[anError retain];
	//[lastError release];
	lastError = anError;
	
	if (lastError == nil)
	{
		return;
	}
	
	[self stop];
	
	self.state = SERVER_STATE_IDLE;
	//NSLog(@"HTTPServer error: %@", self.lastError);
}


//
// errorWithName:
//
// Stops the server and sets the last error to "errorName", localized using the
// HTTPServerErrors.strings file (if present).
//
// Parameters:
//    errorName - the description used for the error
//
- (void)errorWithName:(NSString *)errorName
{
	self.lastError = [NSError
		errorWithDomain:@"HTTPServerError"
		code:0
		userInfo:
			[NSDictionary dictionaryWithObject:
				NSLocalizedStringFromTable(
					errorName,
					@"",
					@"HTTPServerErrors")
				forKey:NSLocalizedDescriptionKey]];
}

//
// setState:
//
// Changes the server state and posts a notification (if the state changes).
//
// Parameters:
//    newState - the new state for the server
//
- (void)setState:(HTTPServerState)newState
{
	if (state == newState)
	{
		return;
	}

	state = newState;
	
	[[NSNotificationCenter defaultCenter]
		postNotificationName:HTTPServerNotificationStateChanged
		object:self];
}

-(bool)getHostAddress:(NSString*)hostname sockAddressIn:(struct sockaddr_in*)result {
	struct addrinfo hints, *res, *iterateRes;
	int retval;
	
	memset (&hints, 0, sizeof (struct addrinfo));
	hints.ai_family = PF_UNSPEC;
	hints.ai_socktype = SOCK_STREAM;
	hints.ai_flags |= AI_CANONNAME;
	
	unsigned long maxLength = [hostname length]+1;
	const char hostNameC[maxLength];
	struct in_addr *inAddr;
	bool foundAddress = NO;
	
	if (hostNameC[0] != 0) {
		[hostname getCString:(void*)&hostNameC maxLength:maxLength encoding:NSASCIIStringEncoding];
		
		retval = getaddrinfo (hostNameC, NULL, &hints, &res);
		if (retval == 0) {
			
			iterateRes = res;
			while (iterateRes && !foundAddress) {
				switch (iterateRes->ai_family)
				{
					case AF_INET:
						inAddr = &((struct sockaddr_in *) iterateRes->ai_addr)->sin_addr;
						memcpy(&(result->sin_addr), inAddr, sizeof(struct in_addr));
						foundAddress = YES;
				}
				iterateRes = iterateRes->ai_next;
			}
		}
		
		freeaddrinfo (res);
	}
	
	return foundAddress;
}

+(NSMutableDictionary*) loadServerSettings
{
	
	NSMutableDictionary *list = nil;
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *fileName = [NSString stringWithFormat:@"%@/folders.plist",[HTTPServer MyDrivesFolder]];
	BOOL isDir;
	
	if([fileManager fileExistsAtPath:fileName isDirectory: &isDir]){
		list = [NSMutableDictionary dictionaryWithContentsOfFile:fileName];
		return list;
	}

	//Main Container
	NSDictionary * dict =[NSMutableDictionary new];
 
	NSNumber * port = [NSNumber numberWithInt:3030];
	NSString * site =  @"/Users/maximbukshovan/MyDrivesMac/MyDrivesMac%@";
 
	//NSString * dataString =@"My Photo";
	//NSData * photo = [dataString dataUsingEncoding:NSUTF8StringEncoding];
 
	NSMutableArray * folders =[NSMutableArray new];
 
	NSMutableDictionary * folder =[NSMutableDictionary new];
	[folder setValue: @"~Documents" forKey:@"name"];
	[folder setValue: [HTTPServer DocumentFolder] forKey:@"path"];
	[folder setValue: [NSNumber numberWithInt:1] forKey:@"d"];
	[folders addObject:folder];

	folder =[NSMutableDictionary new];
	[folder setValue: @"~Movies" forKey:@"name"];
	[folder setValue: [HTTPServer MoviesFolder] forKey:@"path"];
	[folder setValue: [NSNumber numberWithInt:1] forKey:@"d"];
	[folders addObject:folder];

	folder =[NSMutableDictionary new];
	[folder setValue: @"~Music" forKey:@"name"];
	[folder setValue: [HTTPServer MusicFolder] forKey:@"path"];
	[folder setValue: [NSNumber numberWithInt:1] forKey:@"d"];
	[folders addObject:folder];

	[dict setValue:@"192.168.0.1" forKey:@"host"];
	[dict setValue:port forKey:@"port"];
	[dict setValue:site forKey:@"site"];
	[dict setValue:folders forKey:@"folders"];
 
	NSString * plist = [PList objToPlistAsString:dict];
 
	list = [PList plistToObjectFromString:plist];
	NSLog(@"Plist =%@",plist);
	
	[list writeToFile:fileName atomically:YES];
	
	return list;
}
//
// start
//
// Creates the socket and starts listening for connections on it.
//
- (void)start
{
//	NSString *docFolder = [self _getMyDrivesFolder];
	NSMutableDictionary *dic = [HTTPServer loadServerSettings];
	
//	_port = [dic[@"port"] intValue];
//	_host = dic[@"host"];
	
	_folders = dic[@"folders"];
	
	self.lastError = nil;
	self.state = SERVER_STATE_STARTING;

	socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM,
		IPPROTO_TCP, 0, NULL, NULL);
	if (!socket)
	{
		[self errorWithName:@"Unable to create socket."];
		return;
	}

	int reuse = true;
	int fileDescriptor = CFSocketGetNative(socket);
	if (setsockopt(fileDescriptor, SOL_SOCKET, SO_REUSEADDR,
		(void *)&reuse, sizeof(int)) != 0)
	{
		[self errorWithName:@"Unable to set socket options."];
		return;
	}

	struct sockaddr_in address;
	memset(&address, 0, sizeof(address));
	address.sin_len = sizeof(address);
	address.sin_family = AF_INET;
//	address.sin_addr.s_addr = htonl(INADDR_ANY); 
	//address.sin_addr.s_addr = inet_addr([_host UTF8String]);
	[self getHostAddress:_host sockAddressIn:&address];

//	address.sin_port = htons(HTTP_SERVER_PORT);
	address.sin_port = htons(_port);
	
	CFDataRef addressData =	CFDataCreate(NULL, (const UInt8 *)&address, sizeof(address));
//	[(id)(addressData) autorelease];
	
	if (CFSocketSetAddress(socket, addressData) != kCFSocketSuccess)
	{
		CFRelease(addressData);
		[self errorWithName:@"Unable to bind socket to address."];
		return;
	}

	listeningHandle = [[NSFileHandle alloc]	initWithFileDescriptor:fileDescriptor closeOnDealloc:YES];

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(receiveIncomingConnectionNotification:)
		name:NSFileHandleConnectionAcceptedNotification
		object:nil];
	[listeningHandle acceptConnectionInBackgroundAndNotify];

	CFRelease(addressData);
	
	self.state = SERVER_STATE_RUNNING;
//	self.site = @"/Users/maximbukshovan/MyDrivesMac/MyDrivesMac%@";
}

//
// stopReceivingForFileHandle:close:
//
// If a file handle is accumulating the header for a new connection, this
// method will close the handle, stop listening to it and release the
// accumulated memory.
//
// Parameters:
//    incomingFileHandle - the file handle for the incoming request
//    closeFileHandle - if YES, the file handle will be closed, if no it is
//		assumed that an HTTPResponseHandler will close it when done.
//
- (void)stopReceivingForFileHandle:(NSFileHandle *)incomingFileHandle
	close:(BOOL)closeFileHandle
{
	if (closeFileHandle)
	{
		[incomingFileHandle closeFile];
	}
	
	[[NSNotificationCenter defaultCenter]
		removeObserver:self
		name:NSFileHandleDataAvailableNotification
		object:incomingFileHandle];
	
	CFDictionaryRemoveValue(incomingRequests, (__bridge const void *)(incomingFileHandle));
}

//
// stop
//
// Stops the server.
//
- (void)stop
{
	self.state = SERVER_STATE_STOPPING;

	[[NSNotificationCenter defaultCenter]
		removeObserver:self
		name:NSFileHandleConnectionAcceptedNotification
		object:nil];

	[responseHandlers removeAllObjects];

	[listeningHandle closeFile];
	//[listeningHandle release];
	listeningHandle = nil;
	
	for (NSFileHandle *incomingFileHandle in
		[(__bridge NSDictionary *)incomingRequests copy] )
	{
		[self stopReceivingForFileHandle:incomingFileHandle close:YES];
	}
	
	if (socket)
	{
		CFSocketInvalidate(socket);
		CFRelease(socket);
		socket = nil;
	}

	self.state = SERVER_STATE_IDLE;
}

//
// receiveIncomingConnectionNotification:
//
// Receive the notification for a new incoming request. This method starts
// receiving data from the incoming request's file handle and creates a
// new CFHTTPMessageRef to store the incoming data..
//
// Parameters:
//    notification - the new connection notification
//
- (void)receiveIncomingConnectionNotification:(NSNotification *)notification
{
	NSDictionary *userInfo = [notification userInfo];
	NSFileHandle *incomingFileHandle =	[userInfo objectForKey:NSFileHandleNotificationFileHandleItem];

    if(incomingFileHandle)
	{
		CFDictionaryAddValue(
			incomingRequests,
			(__bridge const void *)(incomingFileHandle),
			(__bridge const void *)((__bridge id)CFHTTPMessageCreateEmpty(kCFAllocatorDefault, TRUE) ));
		
		[[NSNotificationCenter defaultCenter]
			addObserver:self
			selector:@selector(receiveIncomingDataNotification:)
			name:NSFileHandleDataAvailableNotification
			object:incomingFileHandle];
		
//				[[NSNotificationCenter defaultCenter]
//					addObserver:self
//					selector:@selector(incomingDataException:)
//					name:NSFileHandleOperationException
//					object:incomingFileHandle];

        [incomingFileHandle waitForDataInBackgroundAndNotify];
    }

	[listeningHandle acceptConnectionInBackgroundAndNotify];
}
//- (void)incomingDataException:(NSNotification *)notification{
//	NSLog(@"Exception ...............");
//}

//
// receiveIncomingDataNotification:
//
// Receive new data for an incoming connection.
//
// Once enough data is received to fully parse the HTTP headers,
// a HTTPResponseHandler will be spawned to generate a response.
//
// Parameters:
//    notification - data received notification
//
- (void)receiveIncomingDataNotification:(NSNotification *)notification
{
	NSFileHandle *incomingFileHandle = [notification object];
	NSData *data = [incomingFileHandle availableData];
	if ([data length] == 0)
	{
		[self stopReceivingForFileHandle:incomingFileHandle close:NO];
		return;
	}

	CFHTTPMessageRef incomingRequest =
		(CFHTTPMessageRef)CFDictionaryGetValue(incomingRequests, (__bridge const void *)(incomingFileHandle));
	if (!incomingRequest)
	{
		[self stopReceivingForFileHandle:incomingFileHandle close:YES];
		return;
	}
	
	if (!CFHTTPMessageAppendBytes(
		incomingRequest,
		[data bytes],
		[data length]))
	{
		[self stopReceivingForFileHandle:incomingFileHandle close:YES];
		return;
	}

	if(CFHTTPMessageIsHeaderComplete(incomingRequest))
	{
		
		HTTPResponseHandler *handler =
			[HTTPResponseHandler
				handlerForRequest:incomingRequest
				fileHandle:incomingFileHandle
				server:self];
		
		[responseHandlers addObject:handler];
		[self stopReceivingForFileHandle:incomingFileHandle close:NO];

		NSData *body = (__bridge NSData *)(CFHTTPMessageCopyBody(incomingRequest));
		if(body != nil && [body length] > 0){
			[handler startResponseWithBody:body];
		}
		else {
			[handler startResponse ];
		}
		CFRelease((__bridge CFTypeRef)(body));
		return;
	}

	[incomingFileHandle waitForDataInBackgroundAndNotify];
}

//
// closeHandler:
//
// Shuts down a response handler and removes it from the set of handlers.
//
// Parameters:
//    aHandler - the handler to shut down.
//
- (void)closeHandler:(HTTPResponseHandler *)aHandler
{
	[aHandler endResponse];
	[responseHandlers removeObject:aHandler];
}
-(NSString *) redirect:(NSString *) folder{
	
	
	NSArray *lines = [folder componentsSeparatedByString: @"/"];
	NSString *target = lines[0];
	
	NSString *result ;
	for(int i = 0; i < _folders.count;i++){
		NSDictionary *item = _folders[i];
		NSString *fname = item[@"name"];
		if([target isEqualToString:fname]){
			NSString *path = item[@"path"];
			result = [folder stringByReplacingOccurrencesOfString:fname withString:path];
			return result;
		}
	}
	return result;
}

+ (NSString *)URLDecode:(NSString *)stringToDecode
{
	NSString *result = [stringToDecode stringByReplacingOccurrencesOfString:@"+" withString:@" "];
	result = [result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	return result;
}

@end
