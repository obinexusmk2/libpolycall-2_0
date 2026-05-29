# polycalld

`polycalld` is the LibPolyCall POSIX protocol daemon. It runs as a foreground
process for development or daemonizes with a PID file and log file for Linux
service deployments.

## Build

```sh
make -C daemon
```

On Linux, macOS, WSL, and Docker this builds the POSIX daemon from
`src/polycalld.c` and `src/daemonize.c`.

On native Windows, the Makefile builds `polycalld.exe` from
`src/polycalld_windows.c`. That binary is an explicit compatibility shim: it
prints usage and explains that the production daemon must run under WSL, Linux,
or Docker until a native Windows service implementation exists.

## Run

```sh
./polycalld --config /etc/polycall/config.polycall --foreground
```

Common options:

```text
-c, --config <path>    Configuration file
-p, --pidfile <path>   PID file path
-s, --socket <path>    Unix socket path
-l, --logfile <path>   Log file path
-f, --foreground       Run in foreground
-v, --verbose          Verbose output
-V, --version          Print version
-h, --help             Show help
```
