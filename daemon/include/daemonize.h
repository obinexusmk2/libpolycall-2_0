/*
 * daemonize.h - Unix daemon process helper
 * OBINexus Computing - LibPolycall V2
 *
 * Provides daemonize() for double-fork daemon creation.
 */

#ifndef DAEMONIZE_H
#define DAEMONIZE_H

/**
 * Daemonize the current process using double-fork.
 *
 * @param dir     Working directory (NULL to keep current)
 * @param pidfile PID file path (NULL to skip)
 * @param logfd   Log file descriptor for stdout/stderr (-1 for /dev/null)
 * @return 0 on success, -1 on failure
 */
int daemonize(const char *dir, const char *pidfile, int logfd);

#endif /* DAEMONIZE_H */
