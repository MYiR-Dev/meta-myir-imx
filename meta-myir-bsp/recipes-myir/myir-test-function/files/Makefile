CC ?= gcc
CFLAGS += -I.

TARGETS = watchdog_test uart_test uart watchdog_y6ull ecspi_test

all: $(TARGETS)

watchdog_test: watchdog.o
	$(CC) -o $@ $^ $(LDFLAGS)

uart_test: uart_test.o
	$(CC) -o $@ $^ $(LDFLAGS)

uart: uart.o
	$(CC) -o $@ $^ $(LDFLAGS)

watchdog_y6ull: watchdog_y6ull.o
	$(CC) -o $@ $^ $(LDFLAGS) 

ecspi_test: ecspi_test.o
	$(CC) -o $@ $^ $(LDFLAGS)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(TARGETS) *.o