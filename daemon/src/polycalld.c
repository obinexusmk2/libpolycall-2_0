/*
 * polycalld.c - LibPolycall V2 Protocol Daemon
 * OBINexus Computing
 *
 * Main entry point for the polycall daemon process.
 * Daemonizes the process, initializes the polycall core library,
 * and listens on a Unix domain socket for incoming protocol requests.
 *
 * Usage:
 *   polycalld --config /etc/polycall/config.polycall
 *   polycalld --config /etc/polycall/config.polycall --foreground
 *   polycalld --help
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <unistd.h>
#include <getopt.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/stat.h>
#include <errno.h>
#include <fcntl.h>

#include "daemonize.h"

#define POLYCALLD_VERSION      "2.0.0"
#define DEFAULT_CONFIG_PATH    "/etc/polycall/config.polycall"
#define DEFAULT_PID_FILE       "/var/run/polycall/polycalld.pid"
#define DEFAULT_SOCKET_PATH    "/var/run/polycall/polycalld.sock"
#define DEFAULT_LOG_FILE       "/var/log/polycall/polycalld.log"
#define LISTEN_BACKLOG         128

static volatile sig_atomic_t g_running = 1;
static volatile sig_atomic_t g_reload  = 0;
static int g_listen_fd = -1;

static struct {
    const char *config_path;
    const char *pid_file;
    const char *socket_path;
    const char *log_file;
    int         foreground;
    int         verbose;
} g_opts = {
    .config_path = DEFAULT_CONFIG_PATH,
    .pid_file    = DEFAULT_PID_FILE,
    .socket_path = DEFAULT_SOCKET_PATH,
    .log_file    = DEFAULT_LOG_FILE,
    .foreground  = 0,
    .verbose     = 0,
};

static void handle_signal(int sig)
{
    switch (sig) {
    case SIGTERM:
    case SIGINT:
        g_running = 0;
        break;
    case SIGHUP:
        g_reload = 1;
        break;
    default:
        break;
    }
}

static void setup_signals(void)
{
    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = handle_signal;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = SA_RESTART;

    sigaction(SIGTERM, &sa, NULL);
    sigaction(SIGINT,  &sa, NULL);
    sigaction(SIGHUP,  &sa, NULL);
    signal(SIGPIPE, SIG_IGN);
}

static int create_unix_socket(const char *path)
{
    struct sockaddr_un addr;
    int fd;

    /* Remove stale socket file */
    unlink(path);

    fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0) {
        perror("polycalld: socket");
        return -1;
    }

    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, path, sizeof(addr.sun_path) - 1);

    if (bind(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        perror("polycalld: bind");
        close(fd);
        return -1;
    }

    /* Set socket permissions: owner + group read/write */
    chmod(path, 0660);

    if (listen(fd, LISTEN_BACKLOG) < 0) {
        perror("polycalld: listen");
        close(fd);
        return -1;
    }

    return fd;
}

static void write_pid_file(const char *path)
{
    FILE *f = fopen(path, "w");
    if (f) {
        fprintf(f, "%d\n", getpid());
        fclose(f);
    }
}

static void cleanup(void)
{
    if (g_listen_fd >= 0) {
        close(g_listen_fd);
        g_listen_fd = -1;
    }
    unlink(g_opts.socket_path);
    unlink(g_opts.pid_file);
}

static void handle_client(int client_fd)
{
    char buf[4096];
    ssize_t n;

    /*
     * Protocol stub: read request, process via polycall core, send response.
     * In production, this integrates with polycall_init_with_config() and
     * the polycall protocol handler to route FFI/micro/edge/telemetry commands.
     */
    n = read(client_fd, buf, sizeof(buf) - 1);
    if (n > 0) {
        buf[n] = '\0';

        /* Echo back with polycall protocol header */
        const char *resp = "HTTP/1.1 200 OK\r\n"
                           "Content-Type: application/json\r\n"
                           "X-Polycall-Version: " POLYCALLD_VERSION "\r\n"
                           "Connection: close\r\n"
                           "\r\n"
                           "{\"status\":\"ok\",\"version\":\"" POLYCALLD_VERSION "\"}\n";
        ssize_t written = write(client_fd, resp, strlen(resp));
        if (written < 0) {
            perror("polycalld: write");
        }
    }
    close(client_fd);
}

static void event_loop(void)
{
    fd_set readfds;
    struct timeval tv;
    int client_fd;

    fprintf(stderr, "polycalld: listening on %s\n", g_opts.socket_path);

    while (g_running) {
        if (g_reload) {
            fprintf(stderr, "polycalld: reloading configuration from %s\n",
                    g_opts.config_path);
            /* TODO: re-parse config.polycall and reinitialize core */
            g_reload = 0;
        }

        FD_ZERO(&readfds);
        FD_SET(g_listen_fd, &readfds);
        tv.tv_sec = 1;
        tv.tv_usec = 0;

        int ret = select(g_listen_fd + 1, &readfds, NULL, NULL, &tv);
        if (ret < 0) {
            if (errno == EINTR)
                continue;
            perror("polycalld: select");
            break;
        }

        if (ret > 0 && FD_ISSET(g_listen_fd, &readfds)) {
            client_fd = accept(g_listen_fd, NULL, NULL);
            if (client_fd < 0) {
                if (errno == EINTR)
                    continue;
                perror("polycalld: accept");
                continue;
            }
            handle_client(client_fd);
        }
    }
}

static void print_usage(const char *prog)
{
    fprintf(stderr,
        "Usage: %s [OPTIONS]\n"
        "\n"
        "LibPolycall V2 Protocol Daemon\n"
        "\n"
        "Options:\n"
        "  -c, --config <path>    Configuration file (default: %s)\n"
        "  -p, --pidfile <path>   PID file path (default: %s)\n"
        "  -s, --socket <path>    Unix socket path (default: %s)\n"
        "  -l, --logfile <path>   Log file path (default: %s)\n"
        "  -f, --foreground       Run in foreground (do not daemonize)\n"
        "  -v, --verbose          Verbose output\n"
        "  -V, --version          Print version and exit\n"
        "  -h, --help             Show this help\n"
        "\n"
        "Signals:\n"
        "  SIGHUP   Reload configuration\n"
        "  SIGTERM   Graceful shutdown\n",
        prog, DEFAULT_CONFIG_PATH, DEFAULT_PID_FILE,
        DEFAULT_SOCKET_PATH, DEFAULT_LOG_FILE);
}

int main(int argc, char *argv[])
{
    static struct option long_opts[] = {
        {"config",     required_argument, NULL, 'c'},
        {"pidfile",    required_argument, NULL, 'p'},
        {"socket",     required_argument, NULL, 's'},
        {"logfile",    required_argument, NULL, 'l'},
        {"foreground", no_argument,       NULL, 'f'},
        {"verbose",    no_argument,       NULL, 'v'},
        {"version",    no_argument,       NULL, 'V'},
        {"help",       no_argument,       NULL, 'h'},
        {NULL, 0, NULL, 0}
    };

    int opt;
    while ((opt = getopt_long(argc, argv, "c:p:s:l:fvVh", long_opts, NULL)) != -1) {
        switch (opt) {
        case 'c': g_opts.config_path = optarg; break;
        case 'p': g_opts.pid_file    = optarg; break;
        case 's': g_opts.socket_path = optarg; break;
        case 'l': g_opts.log_file    = optarg; break;
        case 'f': g_opts.foreground  = 1;      break;
        case 'v': g_opts.verbose     = 1;      break;
        case 'V':
            printf("polycalld %s\n", POLYCALLD_VERSION);
            return 0;
        case 'h':
        default:
            print_usage(argv[0]);
            return (opt == 'h') ? 0 : 1;
        }
    }

    /* Validate config file exists */
    if (access(g_opts.config_path, R_OK) != 0) {
        fprintf(stderr, "polycalld: cannot read config file: %s\n",
                g_opts.config_path);
        return 1;
    }

    setup_signals();

    /* Daemonize unless --foreground */
    if (!g_opts.foreground) {
        int logfd = -1;
        if (g_opts.log_file) {
            logfd = open(g_opts.log_file,
                         O_WRONLY | O_CREAT | O_APPEND, 0644);
        }
        if (daemonize("/", g_opts.pid_file, logfd) < 0) {
            fprintf(stderr, "polycalld: failed to daemonize\n");
            return 1;
        }
    } else {
        write_pid_file(g_opts.pid_file);
    }

    /* Create listening socket */
    g_listen_fd = create_unix_socket(g_opts.socket_path);
    if (g_listen_fd < 0) {
        fprintf(stderr, "polycalld: failed to create socket at %s\n",
                g_opts.socket_path);
        return 1;
    }

    if (g_opts.verbose) {
        fprintf(stderr, "polycalld: version %s\n", POLYCALLD_VERSION);
        fprintf(stderr, "polycalld: config  %s\n", g_opts.config_path);
        fprintf(stderr, "polycalld: socket  %s\n", g_opts.socket_path);
        fprintf(stderr, "polycalld: pid     %s\n", g_opts.pid_file);
    }

    /* Main event loop */
    event_loop();

    /* Cleanup */
    cleanup();
    fprintf(stderr, "polycalld: shutdown complete\n");

    return 0;
}
