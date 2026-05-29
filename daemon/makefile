# daemon/Makefile - Build polycalld daemon
# Standalone build for the daemon component.
#
# The production daemon is POSIX-oriented: it uses fork(), sigaction(), and
# Unix domain sockets. Native Windows builds produce a small compatibility
# binary that explains how to run the daemon through WSL, Linux, or Docker.

# GNU make has a built-in CC=cc, which fails on common Windows/MinGW installs.
# A normal assignment keeps command-line overrides working: make CC=clang.
CC       = gcc
CFLAGS  ?= -Wall -Wextra -O2
ROOT_INC = ../include

ifeq ($(OS),Windows_NT)
    PLATFORM := Windows
    EXEEXT   := .exe
    SRCS     := src/polycalld_windows.c
    LDLIBS   :=
    RM       := del /f /q
else
    PLATFORM := POSIX
    EXEEXT   :=
    SRCS     := src/polycalld.c src/daemonize.c
    CFLAGS   += -fPIC
    LDLIBS   := -lpthread
    RM       := rm -f
endif

TARGET = polycalld$(EXEEXT)

.PHONY: all clean help

all: $(TARGET)

$(TARGET): $(SRCS)
	$(CC) $(CFLAGS) -I include -I $(ROOT_INC) $(SRCS) $(LDLIBS) -o $(TARGET)

clean:
ifeq ($(OS),Windows_NT)
	-$(RM) polycalld.exe polycalld 2>nul
else
	$(RM) $(TARGET)
endif

help:
	@echo "polycalld daemon build"
	@echo "  make          Build $(TARGET) for $(PLATFORM)"
	@echo "  make clean    Remove daemon build outputs"
	@echo "  make CC=...   Override compiler"
