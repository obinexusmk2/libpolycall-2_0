# Daemonize:
Usage: daemonize [options]
Options:
        -d <dir>          Change working directory
        -p <file>         Write process ID to file

        -l <file>         Redirect stdout and stderr to file

        -h                Show this help

        -V                Show version

```c
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <unistd.h>
#include <syslog.h>

#include "daemonize.h"

static void sigterm_handler(int signum){
    syslog(LOG_INFO, "SIGTERM received, exiting");
    exit(0);
}

int main()
{
        if (daemonize("/tmp", "/tmp/daemon.pid", "/tmp/daemon.log") != 0)
        {
                perror("daemonize");
                return 1;
        }
        signal(SIGTERM, sigterm_handler);
        syslog(LOG_INFO, "daemon started");
        for(;;)
        {
                syslog(LOG_DEBUG, "main loop");
                sleep(1);
        }
        return 0;
}

```
