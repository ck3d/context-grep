out ?= /usr/local

.PHONY: all install format

all:

install:
	mkdir -p $(out)/bin
	cp context-grep-nvim context-grep-nvim.lua $(out)/bin/

format:
	stylua context-grep-nvim.lua

check:
	stylua --check context-grep-nvim.lua
