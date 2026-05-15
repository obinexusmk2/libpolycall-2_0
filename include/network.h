#ifndef NETWORK_H
#define NETWORK_H

/* ================================================================
   INCLUDES - polycall_export.h MUST BE FIRST
   ================================================================ */

#include "polycall_export.h"

#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>

#ifdef _WIN32
    #include <winsock2.h>
    #include <ws2tcpip.h>
    #include <windows.h>
#else
    #include <sys/socket.h>
    #include <netinet/in.h>
    #include <arpa/inet.h>
#endif

#include <string.h>
#include <stdio.h>
#include <errno.h>
#include <fcntl.h>

/* ================================================================
   PLATFORM-SPECIFIC THREADING SUPPORT
   ================================================================ */

#ifdef _WIN32
    /* Windows: Use native synchronization primitives from windows.h */
    /* CRITICAL_SECTION is defined in windows.h (already included above) */
    typedef CRITICAL_SECTION net_mutex_t;

    #define NET_MUTEX_INIT(m) InitializeCriticalSection(m)
    #define NET_MUTEX_LOCK(m) EnterCriticalSection(m)
    #define NET_MUTEX_UNLOCK(m) LeaveCriticalSection(m)
    #define NET_MUTEX_DESTROY(m) DeleteCriticalSection(m)

    #define sleep(x) Sleep(x * 1000)
    #define usleep(x) Sleep(x / 1000)
    typedef int socklen_t;
    #define close closesocket
#else
    /* POSIX: Use pthread mutexes */
    #include <pthread.h>
    #include <unistd.h>

    typedef pthread_mutex_t net_mutex_t;

    #define NET_MUTEX_INIT(m) pthread_mutex_init(m, NULL)
    #define NET_MUTEX_LOCK(m) pthread_mutex_lock(m)
    #define NET_MUTEX_UNLOCK(m) pthread_mutex_unlock(m)
    #define NET_MUTEX_DESTROY(m) pthread_mutex_destroy(m)
#endif


// Network Constants
#define NET_MAX_CLIENTS 10
#define NET_BUFFER_SIZE 1024
#define NET_MAX_BACKLOG 5
#define NET_TIMEOUT_SEC 1
#define NET_TIMEOUT_USEC 0

// Network Error Codes
typedef enum {
    NET_SUCCESS = 0,
    NET_ERROR_SOCKET = -1,
    NET_ERROR_BIND = -2,
    NET_ERROR_LISTEN = -3,
    NET_ERROR_ACCEPT = -4,
    NET_ERROR_SEND = -5,
    NET_ERROR_RECEIVE = -6,
    NET_ERROR_MEMORY = -7,
    NET_ERROR_INVALID = -8
} NetworkError;

// Network Protocol Types
typedef enum {
    NET_TCP,            // TCP protocol
    NET_UDP,            // UDP protocol
    NET_RAW,           // Raw sockets
    NET_PROTOCOL_MAX   // Protocol count
} NetworkProtocol;

// Network Role Types
typedef enum {
    NET_CLIENT,        // Client role
    NET_SERVER,        // Server role
    NET_PEER,         // Peer-to-peer role
    NET_ROLE_MAX      // Role count
} NetworkRole;

// Forward declaration
typedef struct PhantomDaemon PhantomDaemon;

// Client Connection State
typedef struct {
    net_mutex_t lock;           // State mutex
    bool is_active;                 // Active flag
    int socket_fd;                  // Socket descriptor
    struct sockaddr_in addr;        // Client address
} ClientState;

// Network Endpoint
typedef struct {
    net_mutex_t lock;           // Endpoint mutex
    char address[INET_ADDRSTRLEN];  // IP address
    uint16_t port;                  // Port number
    NetworkProtocol protocol;       // Protocol type
    NetworkRole role;               // Endpoint role
    int socket_fd;                  // Socket descriptor
    struct sockaddr_in addr;        // Socket address
    PhantomDaemon* phantom;         // Phantom daemon reference
    void* user_data;               // Added user data field
} NetworkEndpoint;

// Network Packet
typedef struct {
    void* data;                     // Packet data
    size_t size;                    // Data size
    uint32_t flags;                 // Packet flags
} NetworkPacket;

// Network Program
typedef struct {
    NetworkEndpoint* endpoints;      // Endpoint array
    size_t count;                   // Endpoint count
    ClientState clients[NET_MAX_CLIENTS]; // Client states
    net_mutex_t clients_lock;    // Clients mutex
    volatile bool running;           // Running flag
    struct {
        void (*on_receive)(NetworkEndpoint*, NetworkPacket*);  // Data handler
        void (*on_connect)(NetworkEndpoint*);                  // Connect handler
        void (*on_disconnect)(NetworkEndpoint*);               // Disconnect handler
    } handlers;
    PhantomDaemon* phantom;         // Phantom daemon reference
} NetworkProgram;

/* ================================================================
   PUBLIC API FUNCTION DECLARATIONS (Exported to DLL/shared library)
   ================================================================ */

POLYCALL_C_BEGIN

// Core Network Functions
POLYCALL_EXPORT bool POLYCALL_CALL net_init(NetworkEndpoint* endpoint);
POLYCALL_EXPORT void POLYCALL_CALL net_close(NetworkEndpoint* endpoint);
POLYCALL_EXPORT ssize_t POLYCALL_CALL net_send(NetworkEndpoint* endpoint, NetworkPacket* packet);
POLYCALL_EXPORT ssize_t POLYCALL_CALL net_receive(NetworkEndpoint* endpoint, NetworkPacket* packet);
POLYCALL_EXPORT void POLYCALL_CALL net_run(NetworkProgram* program);

// Utility Functions
POLYCALL_EXPORT bool POLYCALL_CALL net_is_port_in_use(uint16_t port);
POLYCALL_EXPORT bool POLYCALL_CALL net_release_port(uint16_t port);
POLYCALL_EXPORT void POLYCALL_CALL net_init_client_state(ClientState* state);
POLYCALL_EXPORT void POLYCALL_CALL net_cleanup_client_state(ClientState* state);
POLYCALL_EXPORT void POLYCALL_CALL net_init_program(NetworkProgram* program);
POLYCALL_EXPORT void POLYCALL_CALL net_cleanup_program(NetworkProgram* program);

POLYCALL_C_END

#endif // NETWORK_H