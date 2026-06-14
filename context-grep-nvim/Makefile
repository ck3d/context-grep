out ?= /usr/local

.PHONY: all install format check dev-check test-harness

all:

install:
	mkdir -p $(out)/bin
	cp context-grep-nvim context-grep-nvim.lua $(out)/bin/

format:
	stylua context-grep-nvim.lua

check:
	stylua --check context-grep-nvim.lua

dev-check:
	@$(MAKE) check test-harness --jobs=2

test-harness:
	test-harness ./context-grep-nvim
