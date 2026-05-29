/*
 * polycalld_windows.c - native Windows compatibility entry point.
 *
 * The full polycalld daemon uses POSIX daemon primitives and Unix domain
 * sockets. Keeping this as a small, explicit binary avoids a misleading native
 * Windows compile failure while preserving the real daemon for Linux/WSL/Docker.
 */

#include <stdio.h>
#include <string.h>

#define POLYCALLD_VERSION "2.0.0"

static void print_usage(const char *prog)
{
    fprintf(stderr,
            "Usage: %s [--help] [--version]\n"
            "\n"
            "polycalld %s\n"
            "\n"
            "Native Windows service mode is not implemented yet. The production\n"
            "daemon requires POSIX process control and Unix domain sockets.\n"
            "\n"
            "Run polycalld from WSL, Linux, or the Docker development image:\n"
            "  docker build -t libpolycall-dev --target development .\n"
            "  docker run -it --rm -v %%cd%%:/libpolycall libpolycall-dev /bin/bash\n",
            prog, POLYCALLD_VERSION);
}

int main(int argc, char **argv)
{
    if (argc > 1) {
        if (strcmp(argv[1], "--version") == 0 || strcmp(argv[1], "-V") == 0) {
            printf("polycalld %s\n", POLYCALLD_VERSION);
            return 0;
        }
        if (strcmp(argv[1], "--help") == 0 || strcmp(argv[1], "-h") == 0) {
            print_usage(argv[0]);
            return 0;
        }
    }

    print_usage(argv[0]);
    return 1;
}
