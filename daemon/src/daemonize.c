#include "daemonize.h"

#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

int daemonize(const char *dir, const char *pidfile, int logfd)
{
    pid_t pid;
    int fd;

    pid = fork();
    if (pid < 0) {
        return -1;
    }
    if (pid > 0) {
        _exit(0);
    }

    if (setsid() < 0) {
        return -1;
    }

    pid = fork();
    if (pid < 0) {
        return -1;
    }
    if (pid > 0) {
        _exit(0);
    }

    if (dir && chdir(dir) != 0) {
        return -1;
    }

    if (logfd == -1) {
        fd = open("/dev/null", O_RDWR);
        if (fd < 0) {
            return -1;
        }
        if (dup2(fd, STDOUT_FILENO) < 0 || dup2(fd, STDERR_FILENO) < 0) {
            close(fd);
            return -1;
        }
    } else {
        if (dup2(logfd, STDOUT_FILENO) < 0 || dup2(logfd, STDERR_FILENO) < 0) {
            close(logfd);
            return -1;
        }
        fd = logfd;
    }

    if (dup2(fd, STDIN_FILENO) < 0) {
        close(fd);
        return -1;
    }

    if (fd > STDERR_FILENO) {
        close(fd);
    }

    if (pidfile) {
        int pidfd = open(pidfile, O_WRONLY | O_CREAT | O_TRUNC, 0644);
        if (pidfd < 0) {
            return -1;
        }
        char pidbuf[32];
        int len = snprintf(pidbuf, sizeof(pidbuf), "%d\n", (int)getpid());
        if (len < 0 || write(pidfd, pidbuf, (size_t)len) < 0) {
            close(pidfd);
            return -1;
        }
        close(pidfd);
    }

    return 0;
}
