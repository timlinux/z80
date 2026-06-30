# Makefile for screen-draw
NAME = screen_draw
ASM = screen_draw.asm

all: compile

compile: $(ASM)
	sjasmplus --fullpath --sld=$(NAME).sld $(ASM)

run: compile
	fuse --full-screen --graphics-filter 4x --auto-load --tape $(NAME).tap

debug: compile
	zesarux --noconfigfile --machine 48k \
		--enable-remoteprotocol \
		--disable-autoframeskip \
		--tape $(NAME).tap

clean:
	rm -f *.tap *.sna *.sld *.lst

.PHONY: all compile run debug clean
