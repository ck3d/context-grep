.PHONY: all install test

all: schema.json

schema.json:
	./generate > $@

test: schema.json
	diff -u context-grep.schema.json schema.json

install: schema.json
	rmdir $(out)
	cat schema.json > $(out)
