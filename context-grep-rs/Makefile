out ?= /usr/local

.PHONY: all install check clippy dev-check test-harness

all:
	cargo build

install:
	mkdir -p $(out)/bin
	cp context-grep-nvim context-grep-nvim.lua $(out)/bin/

check:
	cargo fmt --check

clippy:
	cargo clippy -- -D warnings

dev-check:
	@$(MAKE) check clippy test-harness --jobs=3

test-harness: all
	test-harness target/debug/context-grep
