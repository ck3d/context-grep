.PHONY: all check clippy dev-check test-harness

all:
	cargo build

check:
	cargo fmt --check

clippy:
	cargo clippy -- -D warnings

dev-check:
	@$(MAKE) check clippy test-harness --jobs=3

test-harness: all
	test-harness target/debug/context-grep
