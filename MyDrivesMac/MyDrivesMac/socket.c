//
//  socket.c
//  MyDrivesMac
//
//  Created by Vasyl Bukshovan on 15/07/15.
//  Copyright (c) 2015 cobasoft. All rights reserved.
//
//#include <stdio.h>
//#include <stdlib.h>
#include <netdb.h>
#include <netinet/in.h>
#include <string.h>
//#include <malloc/malloc.h>
#include "socket.h"

void*start_server(void*);

void*client_thread(void*data);

int start_socket_server(){
	
	
	pthread_t thread;
	
	int	rc = pthread_create(&thread, NULL,	start_server, (void *)0);
	if (rc){
			exit(-1);
		}
	return 1;
}


//void *start_server(void *p){

//	
//	if ((this->sc = socket(AF_INET, SOCK_STREAM, 0)) == INVALID_SOCKET)
//	{
//		coba::log("error socket server %s %d error:%d\n", this->host, this->port, WSAGetLastError());
//		return false;
//	}
//	
//	int one = 1;
//	int result = setsockopt(sc, SOL_SOCKET, SO_REUSEADDR, (char*)&one, sizeof(one));
//	
//	SOCKADDR_IN server_address;
//	memset(&server_address, 0, sizeof(server_address));
// 
//	server_address.sin_family = AF_INET;
//	server_address.sin_port = htons(this->port);
//	server_address.sin_addr.s_addr = inet_addr(this->host);// inet_addr("127.0.0.1");
//	
//	
//	if (bind(this->sc, (struct sockaddr *) &server_address, sizeof(server_address)) == SOCKET_ERROR)
//	{
//		closesocket(this->sc);
//		coba::log("error bind server %s %d error:%d\n", this->host, this->port, WSAGetLastError());
//		return false;
//	}
//	//SOMAXCONN
//	if (listen(this->sc, 1024) == SOCKET_ERROR)
//	{
//		closesocket(this->sc);
//		coba::log("error listen server %s %d error:%d\n", this->host, this->port, WSAGetLastError());
//		return false;
//	}
//	this->is_running = true;
//	
//	unsigned long ThId = 0;
//	HANDLE handle = CreateThread(NULL, 0, main_server_thread, this, CREATE_SUSPENDED, &ThId);
//	this->set_main_thread_handle(handle);
//	Sleep(100);
//	ResumeThread(handle);
//	
//	return true;
//
//	if ((this->sc = socket(AF_INET, SOCK_STREAM, 0)) == INVALID_SOCKET)
//	{
//		coba::log("error socket server %s %d error:%d\n", this->host, this->port, WSAGetLastError());
//		return false;
//	}
//	
//	int one = 1;
//	int result = setsockopt(sc, SOL_SOCKET, SO_REUSEADDR, (char*)&one, sizeof(one));
//	
//	SOCKADDR_IN server_address;
//	memset(&server_address, 0, sizeof(server_address));
// 
//	server_address.sin_family = AF_INET;
//	server_address.sin_port = htons(this->port);
//	server_address.sin_addr.s_addr = inet_addr(this->host);// inet_addr("127.0.0.1");
//	
//	
//	if (bind(this->sc, (struct sockaddr *) &server_address, sizeof(server_address)) == SOCKET_ERROR)
//	{
//		closesocket(this->sc);
//		coba::log("error bind server %s %d error:%d\n", this->host, this->port, WSAGetLastError());
//		return false;
//	}
//	//SOMAXCONN
//	if (listen(this->sc, 1024) == SOCKET_ERROR)
//	{
//		closesocket(this->sc);
//		coba::log("error listen server %s %d error:%d\n", this->host, this->port, WSAGetLastError());
//		return false;
//	}
//	this->is_running = true;
//	
//	unsigned long ThId = 0;
//	HANDLE handle = CreateThread(NULL, 0, main_server_thread, this, CREATE_SUSPENDED, &ThId);
//	this->set_main_thread_handle(handle);
//	Sleep(100);
//	ResumeThread(handle);
//	
//	return true;

//}
void* start_server(void*p)
{
	int sockfd, *newsockfd, portno;
	char buffer[256];
	struct sockaddr_in serv_addr;
//	int  n, pid;
	
	/* First call to socket() function */
	sockfd = socket(AF_INET, SOCK_STREAM, 0);
	
	if (sockfd < 0)
	{
		perror("ERROR opening socket");
		exit(1);
	}
	
//	int one = 1;
//	int result = setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, (char*)&one, sizeof(one));

	struct hostent *host = gethostbyname("192.168.0.103");
	/* Initialize socket structure */
	bzero((char *) &serv_addr, sizeof(serv_addr));
	portno = 5001;
	
	serv_addr.sin_family = AF_INET;
//	serv_addr.sin_addr.s_addr = INADDR_ANY;
	serv_addr.sin_port = htons(portno);
	serv_addr.sin_addr = // inet_pton("192.168.0.103");// inet_addr("127.0.0.1");
         *((struct in_addr *) *host->h_addr_list);
	
	/* Now bind the host address using bind() call.*/
	if (bind(sockfd, (struct sockaddr *) &serv_addr, sizeof(serv_addr)) < 0)
	{
		closesocket(sockfd);
		perror("ERROR on binding");
		exit(1);
	}
	
	/* Now start listening for the clients, here
	 * process will go in sleep mode and will wait
	 * for the incoming connection
	 */
	
	listen(sockfd,5);
	struct sockaddr_in cli_addr;
	socklen_t clilen = sizeof(struct sockaddr_in);
	bzero((char *) &cli_addr, sizeof(cli_addr));
	
	while (1)
	{
		
		
		*newsockfd = accept(sockfd, (struct sockaddr *) &cli_addr, &clilen);
		
		
		if (newsockfd < 0)
		{
			perror("ERROR on accept");
		}
		else{
			pthread_t thread;
			
			int	rc = pthread_create(&thread, NULL,	client_thread, (void *)newsockfd);
			if (rc){
			}
		}
	} /* end of while */
}
void* client_thread(void*data){
	

	int sc = (int)data;
	size_t sz =sizeof(char) * 1024;
	char *p = (char*) malloc(sz);
	memset(p, 0, sz);

	long readed;
	char *s = p;
	
	while (1)
	{
		if ((readed = recv(sc, s, 1, 0)) <= 0) break;
		
		if (*s == '\n')
		{
			if (*(s - 1) == '\n' || *(s - 2) == '\n')
			{
				break;
			}
		}
		s++;
	}
	//free(p);
	return p;
}