.PHONY: all install test

all: schema.json

schema.json:
	./generate > $@

install: schema.json
	rmdir $(out)
	cat schema.json > $(out)
