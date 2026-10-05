/* SPDX-License-Identifier: GPL-3.0-or-later */
#include <fcntl.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main(void) {
    char input[512] = {0};
    if (read(STDIN_FILENO, input, sizeof(input) - 1) <= 0) return 1;
    if (strstr(input, "crash")) {
        write(STDOUT_FILENO, "partial", 7);
        raise(SIGKILL);
    } else if (strstr(input, "oversize")) {
        char block[8192] = {0};
        for (;;) if (write(STDOUT_FILENO, block, sizeof(block)) <= 0) return 1;
    } else {
        extern char **environ;
        if (*environ) return 1;
        for (int fd = 3; fd < 1024; fd++) if (fcntl(fd, F_GETFD) != -1) return 1;
        write(STDOUT_FILENO, "clean", 5);
    }
    return 0;
}
