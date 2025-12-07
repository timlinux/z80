# Makefile for Z80 screen draw program

# Default target
all: run

# Compile the assembly file
compile: screen_draw.asm
	sjasmplus screen_draw.asm

# Run the compiled program
run: screen_draw.sna
	@echo "Running screen_draw.sna in zesarux..."
	zesarux screen_draw.sna

# Clean compiled files
clean:
	rm -f screen_draw.sna

# Force rebuild
rebuild: clean all

.PHONY: all compile run clean rebuild
