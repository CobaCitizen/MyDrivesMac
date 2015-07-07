#include "stdafx.h"
#include "CobaServer.h"

//wsock32.lib
#pragma comment(lib, "Ws2_32.lib")

namespace coba
{

  WSADATA WSAData;

  std::mutex mtx;
  std::mutex sqlight_mtx;

  ///////////////////////////////////////////////////////////////  
  /*
  void message(const char *format, ...)
  {
    mtx.lock();

    va_list argp;
    va_start(argp, format);
    vprintf(format,argp);
    va_end(argp);
    
    mtx.unlock();
  }
  */
  static char server_log_file_name[1024];

  void log(const char *format, ...)
  {
    mtx.lock();

    FILE *fp = fopen(server_log_file_name, "a+");


    time_t rawtime = 0;
    time(&rawtime);

    char *s = ctime(&rawtime);
    char *p = s;
    while (*p)
    {
      if (*p == '\n' || *p == '\r') *p = 0;
      p++;
    }
    fprintf(fp, "%s:  ",s);
    

    va_list argp;
    va_start(argp, format);
    vfprintf(fp,format, argp);
    va_end(argp);

    fclose(fp);
    mtx.unlock();
  }
  void log(const wchar_t *format, ...)
  {
    mtx.lock();

    FILE *fp = fopen(server_log_file_name, "a+");


    time_t rawtime = 0;
    time(&rawtime);

    char *s = ctime(&rawtime);
    char *p = s;
    while (*p)
    {
      if (*p == '\n' || *p == '\r') *p = 0;
      p++;
    }
    fprintf(fp, "%s:  ", s);


    va_list argp;
    va_start(argp, format);
    vfwprintf(fp, format, argp);
    va_end(argp);

    fclose(fp);
    mtx.unlock();
  }
  ///////////////////////////////////////////////////////////////
  coba_server::coba_server()
  {
    //   InitializeCriticalSection(&this->section);
    this->sc = 0;
    this->app_folder = nullptr;
    this->folder_list_file = nullptr;
    this->host = nullptr;
    this->port = 0;
    this->site = nullptr;
    this->h_main_thread = nullptr;
    this->clients_for_upload = new coba_client_list();
//    this->clients_for_download = new coba_client_list();
  }
  ///////////////////////////////////////////////////////////////
  coba_server::~coba_server()
  {
    this->stop();

    if (this->app_folder)
    {
      delete[] this->app_folder;
      this->app_folder = nullptr;
    }
    if (this->folder_list_file)
    {
      delete[] this->folder_list_file;
      this->folder_list_file = nullptr;
    }
    if (this->host)
    {
      delete[] this->host;
      this->host = nullptr;
    }
    if (this->site)
    {
      delete[] this->site;
      this->site = nullptr;
    }
    delete this->clients_for_upload;
    this->clients_for_upload = nullptr;
//    delete this->clients_for_download;
//    this->clients_for_download = nullptr;
    return;
  }
  ///////////////////////////////////////////////////////////////
  static __int64 coba_lock_count = 0L;
  volatile void coba_server::lock()
  {
    mtx.lock();
    coba_lock_count++;
  }
  ///////////////////////////////////////////////////////////////
  volatile void coba_server::unlock()
  {
    coba_lock_count--;
    if (coba_lock_count < 0)
    {
      throw "ERROR mutex lock ! count < 0";
    }
    mtx.unlock();
  }
  ///////////////////////////////////////////////////////////////
  bool coba_server::empty_socket()
  {
    SOCKET sc_tmp;
    unsigned long ulAddress;
    struct hostent *pHost;
    SOCKADDR_IN sin;
    DWORD dwRes;

    ulAddress = inet_addr(this->host);
    if (INADDR_NONE == ulAddress)
    {
      pHost = gethostbyname(this->host);
      if (NULL == pHost)
      {
        dwRes = GetLastError();
        return false;
      }
      memcpy((char FAR *)&ulAddress, pHost->h_addr, pHost->h_length);
    }

    sc_tmp = socket(PF_INET, SOCK_STREAM, 0);
    if (INVALID_SOCKET == sc_tmp)
    {
      return false;
    }

    sin.sin_family = AF_INET;
    sin.sin_addr.s_addr = ulAddress;
    sin.sin_port = htons(this->port);

    connect(sc_tmp, (LPSOCKADDR)&sin, sizeof(sin));
    shutdown(sc_tmp, 2);
    closesocket(sc_tmp);
    return true;
  }
  ////////////////////////////////////////////////////////////
  bool coba_server::init()
  {
    if (this->load_settings())
    {
      strcpy(server_log_file_name, this->log_file.c_str());

      return this->init(this->host, this->port);
    }
    return false;
  }
  /////////////////////////////////////////////////////////
  bool coba_server::init(char *host, int nport)
  {

    this->host = _strdup(host);
    this->port = nport;
#ifdef _DEBUG
    coba::log("Server %s on port %d started. **********\n", this->host, this->port);
#endif

    char  sStackDescription[WSADESCRIPTION_LEN + 1];
    int  iMaxSockets = 0, iMaxUDPSize = 0;

    int dw_error;
    try
    {
      dw_error = 0;
      if (WSAStartup(MAKEWORD(2, 2), &WSAData) != 0)
      {
#ifdef _DEBUG
        coba::log("Error in WSAStartup : error %d\r\n", WSAGetLastError());
#endif
        return false;
      }
      iMaxSockets = WSAData.iMaxSockets;
      iMaxUDPSize = WSAData.iMaxUdpDg;
      strcpy_s(sStackDescription, WSADESCRIPTION_LEN, WSAData.szDescription);
    }
    catch (...)
    {
#ifdef _DEBUG
      coba::log("Exception int server.init()");
#endif
      return false;
    }

    return true;
  }
  bool coba_server::chat_database_open()
  {
    sqlight_mtx.lock();

    this->sqlite_info.db = 0;

    wchar_t db_path[1024];
    wsprintf(db_path, L"%scoba_chat.db", this->app_folder);
    this->sqlite_info.db_name = db_path;
    bool result = coba::sql_open_db(&this->sqlite_info);

    sqlight_mtx.unlock();


    /*
    int rc = this->sql_execute("INSERT INTO CHAT (MESSAGE) VALUES('1 who kon wsdlfk sdglk')");
    rc = this->sql_execute("INSERT INTO CHAT (MESSAGE) VALUES('2 who kon wsdlfk sdglk')");
    rc = this->sql_execute("INSERT INTO CHAT (MESSAGE) VALUES('3 who kon wsdlfk sdglk')");

    wchar_t *json = this->sql_execute_select("SELECT * FROM CHAT");

    if (json)
    {
      delete[] json;
    }
    */
    return result;
  }
  void coba_server::chat_database_close()
  {
    sqlight_mtx.lock();

    this->sqlite_info.db = 0;
    sqlite3_close(this->sqlite_info.db);

    sqlight_mtx.unlock();
  }
  wchar_t *coba_server::sql_execute_select(wchar_t *sql)
  {
    wchar_t *result = nullptr;
    sqlight_mtx.lock();
    result = coba::sql_select(this->sqlite_info.db, sql);
    sqlight_mtx.unlock();
    return result;
  }
  int coba_server::sql_execute(wchar_t *sql)
  {
    sqlight_mtx.lock();
    int result = coba::sql_execute(this->sqlite_info.db, sql);
    sqlight_mtx.unlock();
    return result;

  }
  ///////////////////////////////////////////////////////////////
  bool coba_server::start()
  {
    
  //  this->chat_database_open();
    

    if ((this->sc = socket(AF_INET, SOCK_STREAM, 0)) == INVALID_SOCKET)
    {
      coba::log("error socket server %s %d error:%d\n", this->host, this->port, WSAGetLastError());
      return false;
    }

    int one = 1;
    int result = setsockopt(sc, SOL_SOCKET, SO_REUSEADDR, (char*)&one, sizeof(one));

    SOCKADDR_IN server_address;
    memset(&server_address, 0, sizeof(server_address));
 
    server_address.sin_family = AF_INET;
    server_address.sin_port = htons(this->port);
    server_address.sin_addr.s_addr = inet_addr(this->host);// inet_addr("127.0.0.1");


    if (bind(this->sc, (struct sockaddr *) &server_address, sizeof(server_address)) == SOCKET_ERROR)
    {
      closesocket(this->sc);
      coba::log("error bind server %s %d error:%d\n", this->host, this->port, WSAGetLastError());
      return false;
    }
    //SOMAXCONN
    if (listen(this->sc, 1024) == SOCKET_ERROR)
    {
      closesocket(this->sc);
      coba::log("error listen server %s %d error:%d\n", this->host, this->port, WSAGetLastError());
      return false;
    }
    this->is_running = true;

    unsigned long ThId = 0;
    HANDLE handle = CreateThread(NULL, 0, main_server_thread, this, CREATE_SUSPENDED, &ThId);
    this->set_main_thread_handle(handle);
    Sleep(100);
    ResumeThread(handle);

    return true;
  }
  void coba_server::send_message_close()
  {
    PostMessage(this->hwnd_main_window, WM_CLOSE, 0, 0);
  }
  ///////////////////////////////////////////////////////////////
  bool coba_server::stop()
  {
    this->lock();
    this->is_running = false;
  //  this->chat_database_close();
    this->unlock();



    //this->empty_socket();

    if (this->sc > 0)
    {
      shutdown(this->sc, 2);
      closesocket(this->sc);
      this->sc = 0;
    }

    this->wait_main_thread_terminated();
    return true;
  }
  ///////////////////////////////////////////////////////////////
  volatile bool coba_server::is_working()
  {
    this->lock();
    bool result = this->is_running;
    this->unlock();
    return result;
  }
  volatile void coba_server::add_upload(coba_client *client)
  {
    this->lock();
    this->clients_for_upload->add(client);
    this->unlock();
  }

  volatile void coba_server::execute_upload()
  {
    while (this->is_working())
    {
      this->lock();
      coba_client_list_item *tmp = this->clients_for_upload->first;
      while (tmp)
      {
        try
        {

          coba_client* client = tmp->client;
          client->read_action();
          this->clients_for_upload->delete_node(tmp);
          delete client;
          tmp = this->clients_for_upload->first;

        }
        catch (...)
        {
          continue;
        }
      }
      this->unlock();
      Sleep(100);
    }
    coba::log("server_upload_thread normal stopped.\n");
  }

  ///////////////////////////////////////////////////////////////
  bool coba_server::create_client_thread(SOCKET soc,char* remote_ip)
  {
    if (soc <= 0)
    {
      return false;
    }
    this->lock();
    char http_connect[256];
    sprintf(http_connect, "/http://%s:%d/", this->host, this->port);
    coba_client_info *info = new coba_client_info(soc, this->site, this->folder_list_file, http_connect,this,remote_ip);
    this->unlock();

    unsigned long ThId;
    HANDLE handle = (HANDLE)CreateThread(NULL, 0, create_client_main_thread, (void*)info, NULL/*CREATE_SUSPENDED*/, &ThId);
    //Sleep(10);
    //ResumeThread(handle);
    return true;
  }
  ///////////////////////////////////////////////////////////////
  void coba_server::set_main_thread_handle(HANDLE handle)
  {
    _ASSERT(handle);

    this->lock();
    this->h_main_thread = handle;
    this->unlock();

    if (this->h_main_thread == NULL)
    {
      printf("Error create server main thread!\r\n");
      throw "Error create main thread!";
    }
  }
  ///////////////////////////////////////////////////////////////
  bool coba_server::wait_main_thread_terminated()
  {
    try
    {
      if (this->h_main_thread != nullptr)
      {
        WaitForSingleObject(this->h_main_thread, INFINITE);
        TerminateThread(this->h_main_thread, 0);
        if (this->h_main_thread)
        {
          CloseHandle(this->h_main_thread);
        }
        this->h_main_thread = nullptr;
      }
      WSACleanup();
    }
    catch (...)
    {
    }
    return true;
  }
  ///////////////////////////////////////////////////////////////
  wchar_t *coba_server::extract_folder(wchar_t *file)
  {
    size_t size = lstrlen(file);
    wchar_t *p = file + size;
    while (p > file && *p != L'/' && *p != L'\\') p--;

    if (*p == L'/' || *p == L'\\')
    {
      size_t size = p - file + 2;
      wchar_t *folder = new wchar_t[size];
      wcsncpy(folder, file, size-1);
      folder[size - 1] = L'\0';
      return folder;
    }

    return nullptr;
  }
  //////////////////////////////////////////////////////////////
  bool coba_server::load_settings()
  {

    LPTSTR command_line = GetCommandLine();

    LPTSTR cmdline = (command_line[0] == '\"' ? command_line + 1 : command_line);


    std::wstring spath(cmdline);
    this->app_folder = this->extract_folder(cmdline);

    std::wstring file = this->app_folder;
    file += L"server.txt";

    char *s = this->file_read_all(file.c_str());
    if (s == nullptr)
    {
      return false;
    }
    bool result = false;

    coba_parser parser;
    coba_list *list = parser.split(s, "\r\n");
    if (list)
    {
      this->host = _strdup(list->find_soft("host :"));
      this->port = atol(list->find_soft("port :"));
      this->site = coba::ctowc(list->find_soft("site :"));
      this->folder_list_file = coba::ctowc(list->find_soft("folders :"));
      this->log_file = list->find_soft("log :");

      delete list;

      result = true;
    }
    delete[] s;
    return result;
  }
  ///////////////////////////////////////////////////////////////
  char *coba_server::file_read_all(const wchar_t *file)
  {
    FILE *fp = _wfopen(file, L"rb");

    if (fp == NULL)
    {
#ifdef _DEBUG
      coba::log("Error open file %ls \r\n", file);
#endif
      return nullptr;
    }

    fseek(fp, 0, SEEK_END);
    size_t size = ftell(fp);
    fseek(fp, 0, SEEK_SET);

    char *p = new char[size+2];
    memset(p, 0, size+2);

    setbuf(fp, p);

    size_t readed = fread(p, (int)1, size, fp);
   
    fclose(fp);
    return p;
  }

  int hostname_to_ip2(char * hostname, char* ip)
  {
    struct hostent *he;
    struct in_addr **addr_list;
    int i;

    if ((he = gethostbyname(hostname)) == NULL)
    {
      return 1;
    }

    addr_list = (struct in_addr **) he->h_addr_list;

    for (i = 0; addr_list[i] != NULL; i++)
    {
      //Return the first one;
      strcpy(ip, inet_ntoa(*addr_list[i]));
      return 0;
    }

    return 1;
  }
//#include <winsock2.h>
  static int establish_proxy_connection(int fd, char *host, int port)
  {
    char buffer[1024];
    char *cp;

    sprintf(buffer, "CONNECT %s:%d HTTP/1.0\r\n\r\n", host, port);
    int sended = send(fd, buffer, strlen(buffer), 0);

    if (sended <= 0) 
    {
      return -1;
    }
    
    for (cp = buffer; cp < &buffer[sizeof(buffer) - 1]; cp++) 
    {
      if ( recv(fd, cp, 1, 0) != 1) 
      {
        return -1;
      }
      if (*cp == '\n')
        break;
    }

    if (*cp != '\n')
      cp++;
    *cp-- = '\0';
    if (*cp == '\r')
      *cp = '\0';
    if (strncmp(buffer, "HTTP/", 5) != 0) 
    {
      //rprintf(FERROR, "bad response from proxy - %s\n",  buffer);
      return -1;
    }
    for (cp = &buffer[5]; isdigit(*(unsigned char *)cp) || (*cp == '.'); cp++)
      ;
    while (*cp == ' ')
      cp++;
    if (*cp != '2') 
    {
      //rprintf(FERROR, "bad response from proxy - %s\n",  buffer);
      return -1;
    }
    // throw away the rest of the HTTP header 
    while (1) 
    {
      for (cp = buffer; cp < &buffer[sizeof(buffer) - 1];cp++) 
      {
        if (recv(fd, cp, 1,0) != 1) 
        {
          //rprintf(FERROR, "failed to read from proxy: %s\n",      strerror(errno));
          return -1;
        }
        if (*cp == '\n')
          break;
      }
      if ((cp > buffer) && (*cp == '\n'))
        cp--;
      if ((cp == buffer) && ((*cp == '\n') || (*cp == '\r')))
        break;
    }
    
    return 0;
  }
  /*
  Winhttp.lib

#include <Winhttp.h>

  void socket_proxy_connect(wchar_t *host,wchar_t *proxy)
  {
    DWORD dwSize = 0;
    DWORD dwDownloaded = 0;
    LPSTR pszOutBuffer;
    BOOL  bResults = FALSE;
    HINTERNET  hSession = NULL,
      hConnect = NULL,
      hRequest = NULL;

    // Use WinHttpOpen to obtain a session handle.
    hSession = WinHttpOpen( L"WinHTTP Example/1.0",
      WINHTTP_ACCESS_TYPE_AUTOMATIC_PROXY,//WINHTTP_ACCESS_TYPE_DEFAULT_PROXY,
      proxy,//WINHTTP_NO_PROXY_NAME,  // Replace this with L"10.10.10.1:80" (i.e. proxy ip:port)
      L"", //WINHTTP_NO_PROXY_BYPASS,  // Replace with WINHTTP_ACCESS_TYPE_NAMED_PROXY
      0);

    // Specify an HTTP server.
    if (hSession)
      hConnect = WinHttpConnect(hSession, host, //L"www.microsoft.com",
      INTERNET_DEFAULT_HTTP_PORT, 0);

    // Create an HTTP request handle.
    if (hConnect)
      hRequest = WinHttpOpenRequest(hConnect, L"GET",L"srvlist.php HTTP/1.0\n\n", 
      NULL, WINHTTP_NO_REFERER,
      WINHTTP_DEFAULT_ACCEPT_TYPES,
      NULL);//WINHTTP_FLAG_SECURE);

    // Send a request.
    if (hRequest)
      bResults = WinHttpSendRequest(hRequest,
      WINHTTP_NO_ADDITIONAL_HEADERS,
      0, WINHTTP_NO_REQUEST_DATA, 0,
      0, 0);


    // End the request.
    if (bResults)
      bResults = WinHttpReceiveResponse(hRequest, NULL);

    // Keep checking for data until there is nothing left.
    if (bResults)
      do
      {

        // Check for available data.
        dwSize = 0;
        if (!WinHttpQueryDataAvailable(hRequest, &dwSize))
          printf("Error %u in WinHttpQueryDataAvailable.\n",
          GetLastError());

        // Allocate space for the buffer.
        pszOutBuffer = new char[dwSize + 1];
        if (!pszOutBuffer)
        {
          printf("Out of memory\n");
          dwSize = 0;
        }
        else
        {
          // Read the Data.
          ZeroMemory(pszOutBuffer, dwSize + 1);

          if (!WinHttpReadData(hRequest, (LPVOID)pszOutBuffer,
            dwSize, &dwDownloaded))
            printf("Error %u in WinHttpReadData.\n",
            GetLastError());
          else
            printf("%s", pszOutBuffer);

          // Free the memory allocated to the buffer.
          delete[] pszOutBuffer;
        }

      } while (dwSize>0);


      // Report any errors.
      if (!bResults)
        printf("Error %d has occurred.\n", GetLastError());

      // Close any open handles.
      if (hRequest) WinHttpCloseHandle(hRequest);
      if (hConnect) WinHttpCloseHandle(hConnect);
      if (hSession) WinHttpCloseHandle(hSession);
  }
  */
  volatile void coba_server::register_server()
  {
    return;
    unsigned long ulAddress;
    struct hostent *pHost;
    SOCKADDR_IN sin;
    DWORD dwRes;
    //http://maxbuk.com/regsrv.php?name=qwert&port=12345
    char *maxbuk = "www.maxbuk.com";

 //   socket_proxy_connect(L"www.maxbuk.com", L"web183.default-host.net");// L"web272.default-host.net");

  //  maxbuk = "web272.default-host.net";// "web183.default-host.net";// "601066.maxbuk.web.hosting-test.net";
   // maxbuk = "web183.default-host.net";
    int error;

    maxbuk = "601066.maxbuk.web.hosting-test.net";
    
    SOCKET  soc = socket_connect(maxbuk, 80, &error);
//    establish_proxy_connection(soc, "www.maxbuk.com", 80);


    char *query = "GET /regsrv.php?name=ww&port=13035 HTTP/1.0\n\n";

    std::string s =
      "GET /regsrv.php?name=ww&port=13035 HTTP/1.0\n";
    
    s += "Host: ww:3035\n";
    s += "Connection: keep-alive\n";
    s += "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8\n";
    s += "User-Agent: Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.89 Safari/537.36\n";
    s += "Accept-Encoding: gzip, deflate, sdch\n";
    s += "Accept-Language: en-US,en;q=0.8,ru;q=0.6\n";
    
    s += "\n";

    
    int sended = send(soc, s.c_str(), strlen(s.c_str()), 0);
    char buffer[10240];
    int recieved = recv(soc, buffer, 10240, 0);
    buffer[recieved] = 0;
    shutdown(soc, 2);
    closesocket(soc);
  }
  volatile void coba_server::unregister_server()
  {

  }

  ///////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////
}