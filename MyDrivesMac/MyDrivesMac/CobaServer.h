#pragma once

#include "stdafx.h"
#include "sqlite3.h"
#include <assert.h>

extern char *strptime(const char *buf, const char *format, struct tm *timeptr);

namespace coba
{
  
  const int FILE_NAME_SIZE = 1024;

  unsigned long WINAPI main_server_thread(LPVOID lpvParam);
  DWORD WINAPI create_client_main_thread(void *data);
  /////////////////////////////////////////////////////

  int create_child_process(SOCKET sock_client);

  //void message(const char *format, ...);
  wchar_t *uri_decode(char *pSrc);
  void log(const char *format, ...);
  void log(const wchar_t *format, ...);
  //////////////////////////////////////////////////////
  /*
  void *heap_malloc(size_t size);
  void heap_free(void **p);
  */
  /////////////////////////////////////////////////////
  inline bool file_exists(wchar_t *path)
  {
#define COBA_ACCESS_MODE_EXISTS 0
#define COBA_ACCESS_SUCCESS 0
    return _waccess(path, COBA_ACCESS_MODE_EXISTS) == COBA_ACCESS_SUCCESS;
  }
  inline wchar_t* wcdup(wchar_t *ws)
  {
    int len = wcslen(ws);
    wchar_t *p = new wchar_t[len + sizeof(wchar_t)];
    memset(p, 0, len + sizeof(wchar_t));
    wcscpy(p, ws);
    return p;
  }
  inline wchar_t *wcdup(char *s)
  {
    if (s == nullptr || *s == NULL)
    {
      return nullptr;
    }
    size_t size = strlen(s) + 1;
    wchar_t *p = new wchar_t[size];
    mbstowcs(p, s, size);
    return p;
  }
  inline char *wctoc(wchar_t *ws)
  {
    int size = wcslen(ws) + 1;
    char *s = new char[size];
    for (int i = 0; i < size; i++)
    {
      s[i] = (char)ws[i];
    }
    return s;
  }
  inline wchar_t *ctowc(char *s)
  {
    int size = strlen(s) + 1;
    wchar_t *wc = new wchar_t[size];
    memset(wc, 0, size);
    for (int i = 0; i < size; i++)
    {
      wc[i] = s[i];
    }
    return wc;
  }
  inline void wccopy(wchar_t* d, wchar_t *s)
  {
    while (*d++ = *s++);
    *d = *s;
  }
  inline size_t get_file_size(FILE *fp)
  {
    fseek(fp, 0, SEEK_END);
    size_t size = ftell(fp);
    fseek(fp, 0, SEEK_SET);
    return size;
  }
  inline bool contains(char *source,const char *target)
  {
    return (strncmp(source, target, strlen(target)) == 0);
  }
  ////////////////////////////////////////////////////////////////////
  typedef enum
  {
    coba_token_white,
    coba_token_new_line,
    coba_token_word,
    coba_token_term,
    coba_token_number,
    coba_token_eof
  } coba_tokens;

  typedef enum 
  {
    Error = 0L,
    GetVirtualDriveList = 1L,
    GetFileList = 2L,
    AcceptFile = 3L,
    DownloadFile = 4L,
    UploadFileBegin = 5L,
    UploadFileSize = 6L

  } ServerCommandEnum;

  typedef enum
  {
    user_agent_unknown,
    user_agent_NSPlayer,
    user_agent_Mozilla,
    user_agent_QuickTime,
    user_aget_Bookviser
  } coba_user_agent;

  
  class coba_client;
  class coba_server;

  class coba_client_info
  {
  public:

    SOCKET socket;
    wchar_t *site;
    wchar_t *folder_list_file;
    char *http_connect;
    coba_server *server;
    char *remote_ip;

  public:

    coba_client_info(SOCKET sc, wchar_t *site_folder, wchar_t *folders_file,char *connect,coba_server *srv, char *ip)
    {
      this->server = srv;
      this->socket = sc;
      this->site = coba::wcdup(site_folder);
      this->folder_list_file = coba::wcdup(folders_file);
      this->http_connect = _strdup(connect);
      this->remote_ip = ip;
    }
    ~coba_client_info()
    {
      this->socket = 0;
      if (this->site)
      {
        delete[] this->site;
        this->site = NULL;
      }
      if (this->folder_list_file)
      {
        delete[] this->folder_list_file;
        this->folder_list_file = NULL;
      }
      this->server = nullptr;
      if (this->remote_ip)
      {
        delete [] this->remote_ip;
        this->remote_ip = nullptr;
      }
    }
  };

  class coba_list_item
  {
  public:

    coba_list_item() { this->next = this->prev = 0; this->data = nullptr; this->wcdata = nullptr; this->client = nullptr; }
    ~coba_list_item() {

    }

    coba_list_item *next;
    coba_list_item *prev;

    //TODO use only wchar_t
    char *data;
    wchar_t *wcdata;
    coba_client *client;
  };

  class coba_list
  {
  private:
    long count;
    std::wstring wcs;
    std::string s;
  public:

    coba_list();
    ~coba_list();

    void clear();

    coba_list_item *first;
    coba_list_item *last;

    //TODO use only wchar_t
    coba_list_item *addf(const char* format , ...);
    coba_list_item *add(const char *value);
    coba_list_item *add(wchar_t* format , ...);
    coba_list_item *add_client(coba_client *value);

    void delete_node(coba_list_item *n);
    char *find_soft(char *target);
    const wchar_t *to_wchttp_header();
    const char *to_http_header();
    const wchar_t *to_json();
    int get_count() { return this->count; }
  };
  //--------------------------------------------

  class coba_client_list_item
  {
  public:


    coba_client_list_item *next;
    coba_client_list_item *prev;

    coba_client *client;

    coba_client_list_item() { this->next = this->prev = 0; this->client = nullptr; }
    ~coba_client_list_item() {

    }

  };

  class coba_client_list
  {
  private:
    long count;
  public:


    void clear();

    coba_client_list_item *first;
    coba_client_list_item *last;

    //TODO use only wchar_t
    coba_client_list_item *add(coba_client *value);

    void delete_node(coba_client_list_item *n);
    
    int get_count() { return this->count; }

    coba_client_list();
    ~coba_client_list();

  };


  //----------------------------------------------
  class coba_parser
  {
  private:

    bool is_white(char c);
    bool is_term(char c);
    bool is_digit(char c);

  public:

    coba_parser();
    ~coba_parser();

    coba_tokens find_token(char *s, int begin, int *len);

    coba_list *parse(char *s);
    coba_list *split(char *s, char *term);
    char * parse_http_get(char *s);
  };

  class coba_client
  {
  private:

    typedef enum
    {
      NO_AVALAIBLE_DATA,
      GET_COMMAND,
      COBA_COMMAND,
      ACTION,
      COBA_NEW_COMMAND,
      UNKNOWN_ERROR

    } COBA_COMMAND_ENUM;



    SOCKET sc;
    wchar_t *site;
    long total_readed;
    long available_size;

    size_t cmd_size;
    char *cmd_buffer;


  private:


    u_long available();

    void set_socket_mode(int timout, bool blocking);

    bool read_command();
    char *read_request(COBA_COMMAND_ENUM *get_result);
    char *read_get_request();
    char *read_new_request();

    bool is_alive();

    void send_no_request();
    void send_http_message(char *message);
    void send_json(char *json);
    void send_file_not_found(wchar_t *file);

    void send_range_header(size_t content_length, size_t range_begin, 
         size_t range_end,size_t file_size,char *session_id);

    void send_header(wchar_t *ext, int content_length, wchar_t *charset = L"utf-8");

    void send_http_header(coba_list *header);

    void send_file(wchar_t *file, bool responce_on_command);
    void send_file_content(wchar_t *file);
    void send_file_content(wchar_t *file, char *range, char *session_id);
    void send_file_partition(FILE *fp, size_t start, size_t end, size_t file_size);

    void send_file_for_nsplayer(wchar_t* file, coba_list *header);
    void send_file_for_mozilla(wchar_t* file, coba_list *header);
    void send_file_for_quicktime(wchar_t* file, coba_list *header);

    void send_relative_file(wchar_t *wcfile);
    void send_absolute_file(wchar_t *wcfile);
    void send_virtual_driver_list();
    bool send_command(__int64 cmd, __int64 data_size);
    int  send_file_list(wchar_t *folder, bool need_send_command);
    int  send_data(byte *data, size_t size);
    void send_bad_request();

    void upload_file(wchar_t *wcfile);
    void upload_file_partial(coba_list *prms);


    void execute_get(char *request, coba_client_info *info);
    void execute_coba_command(char *request);
    void execute_coba_new_command(char *request,coba_client_info *info);
    void execute_action(char *request);
    void create_folder(wchar_t *wcfolder, bool need_send_command);
    void remove_folder(wchar_t *wcfolder);

    int send_folder_content(wchar_t *folder);

  public:

    wchar_t *folder_list_file;
    bool is_uploader;
    bool keep_alive;
    bool is_client_winsocket;

  public:
    coba_client();
    ~coba_client();

    bool execute(coba_client_info *info);
    char *read_action();

    bool need_stop_server;
    coba_client_info *client_info;

  };

  typedef struct coba_sqllight coba_sqllight;
  struct coba_sqllight
  {
    sqlite3 *db;    /* The database */
    const wchar_t *db_name;    /* name of the database file */
  };


  class coba_server
  {

  private:

    //CRITICAL_SECTION section;
    volatile HANDLE h_main_thread;
    bool is_running;

    coba_client_list *clients_for_upload;
    coba_sqllight sqlite_info;

  private:

    volatile void lock();
    volatile void unlock();

    bool wait_main_thread_terminated();
    char *file_read_all(const wchar_t *file);
    
    wchar_t *extract_folder(wchar_t *file);

    
    bool chat_database_open();
    void chat_database_close();

  public:

    SOCKET sc;
    int   port;
    char *host;

    wchar_t *site;
    wchar_t *app_folder;
    wchar_t *folder_list_file;

    std::string log_file;

    HWND hwnd_main_window;

  public:

    coba_server();
    ~coba_server();

    bool print_socket_error();
    bool load_settings();

    bool init();
    bool init(char *host, int nport);
    bool start();
    bool stop();

    bool empty_socket();
    void log(char *);
    void log(int);

    bool create_client_thread(SOCKET soc,char *remote_ip);
    volatile bool is_working();
    volatile void add_upload(coba_client *client);
//    volatile void add_download(coba_client *client);
    volatile void execute_upload();

    void set_main_thread_handle(HANDLE handle);

    wchar_t *sql_execute_select(wchar_t *sql);
    int sql_execute(wchar_t *sql);
    sqlite3 * get_db() { return this->sqlite_info.db; }
    void send_message_close();
    volatile void register_server();
    volatile void unregister_server();
  };


  /////////////////////////////////////////////////////////////

  coba_user_agent get_user_agent(coba_list *list);
  wchar_t *get_file_extention(wchar_t *s);
  wchar_t *get_content_type(wchar_t *ext);

  void get_current_time(wchar_t *s);
  void get_current_time(char *s);

  int parse_range(char *range, size_t *begin, size_t *end);
  /////////////////////////
  bool sql_open_db(coba_sqllight *p);
  wchar_t *sql_select(sqlite3 *db, wchar_t *sql);
  int sql_execute(sqlite3 *db, wchar_t *sql);
  

  std::string handshake(const char *key);
  std::string base64_encode(unsigned char const* bytes_to_encode, unsigned int in_len);
  std::string base64_decode(std::string const& encoded_string);
  // ---------------- socket -----------------------
  int socket_connect(char *host, int port, int *error);
}