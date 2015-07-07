//
//  HTTPResponseHandler.h
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

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import <CFNetwork/CFNetwork.h>
#else
#import <Cocoa/Cocoa.h>
#endif

@class HTTPServer;

@interface HTTPResponseHandler : NSObject
{
	CFHTTPMessageRef request;
}

@property (strong , readonly) HTTPServer *server;
@property (strong , readonly) NSString *requestMethod;
@property (strong , readonly) NSDictionary *headerFields;
@property (strong , readonly) NSFileHandle *fileHandle;
@property (strong , readonly) NSURL *url;


+ (NSUInteger)priority;
+ (void)registerHandler:(Class)handlerClass;

+ (HTTPResponseHandler *)handlerForRequest:(CFHTTPMessageRef)aRequest
	fileHandle:(NSFileHandle *)requestFileHandle
	server:(HTTPServer *)aServer;

- (id)initWithRequest:(CFHTTPMessageRef)aRequest
	method:(NSString *)method
	url:(NSURL *)requestURL
	headerFields:(NSDictionary *)requestHeaderFields
	fileHandle:(NSFileHandle *)requestFileHandle
	server:(HTTPServer *)aServer;

- (void)startResponse;


- (void)endResponse;

@end
