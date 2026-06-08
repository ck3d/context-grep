out ?= /usr/local

.PHONY: all install format

all:

install:
	mkdir -p $(out)/bin
	cp context-grep-nvim context-grep-nvim.lua $(out)/bin/

format:
	stylua context-grep-nvim.lua
