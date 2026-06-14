#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
direnv allow .
eval "$(direnv export bash)"

set -x

cargo fmt --check

cargo build

cargo clippy -- -D warnings

test-harness target/debug/context-grep
