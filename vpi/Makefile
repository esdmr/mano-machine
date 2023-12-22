all: io.vpi
clean:
	rm io.o io.vpi

.PHONY: all clean

io.vpi: io.c
	iverilog-vpi io.c

compile_commands.json:
	bear iverilog-vpi io.c
