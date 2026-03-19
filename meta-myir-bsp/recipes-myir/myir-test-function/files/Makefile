CC ?= gcc
CFLAGS += -I.

TARGETS = watchdog_test uart_test

all: $(TARGETS)

watchdog_test: watchdog.o
	$(CC) -o $@ $^ $(LDFLAGS)

uart_test: uart_test.o
	$(CC) -o $@ $^ $(LDFLAGS)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(TARGETS) *.o
