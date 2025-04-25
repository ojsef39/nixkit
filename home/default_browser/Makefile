BIN ?= defaultbrowser

CC ?= gcc
CFLAGS ?= -O2

.PHONY: all clean

all: $(BIN)

$(BIN):
	$(CC) -o $(BIN) $(CFLAGS) -framework Foundation -framework ApplicationServices  src/main.m

clean:
	rm -f $(BIN)
