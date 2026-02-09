CC ?= gcc
CFLAGS += -I.
LDFLAGS += -lz

all: zlibtest

zlibtest: zlibtest.o compression.o
	$(CC) -o $@ $^ $(LDFLAGS)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f zlibtest *.o
