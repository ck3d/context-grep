out ?= /usr/local

.PHONY: all check test-harness dev-check install

all:

check:
	shellcheck test-harness

test-harness:
	./test-harness context-grep

dev-check:
	@$(MAKE) check test-harness --jobs=3

install:
	mkdir -p $(out)/bin $(out)/share/test-harness
	cp test-harness $(out)/bin/
	cp sample-data/* $(out)/share/test-harness
