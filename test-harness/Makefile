out ?= /usr/local

.PHONY: all check install

all:

check:
	shellcheck test-harness

install:
	mkdir -p $(out)/bin $(out)/share/test-harness
	cp test-harness $(out)/bin/test-harness
	cp sample-data/* $(out)/share/test-harness/
