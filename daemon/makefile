# daemon/Makefile - Build polycalld daemon
# Standalone build for the daemon component.
# Normally invoked via the top-level Makefile.

CC       ?= gcc
CFLAGS   ?= -Wall -Wextra -O2 -fPIC
LDFLAGS  ?= -lpthread

CORE_INC  = ../core/include
CORE_LIB  = ../build/core/lib

SRCS = src/polycalld.c src/daemonize.c
TARGET = polycalld

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(SRCS)
	$(CC) $(CFLAGS) -I include -I $(CORE_INC) -I $(CORE_INC)/libpolycall \
		$(SRCS) \
		-L $(CORE_LIB) $(LDFLAGS) \
		-o $(TARGET)

clean:
	rm -f $(TARGET)
