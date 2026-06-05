#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

set -x

eval "$(direnv export bash)"

./test-harness ..#context-grep-rs-wrapped
./test-harness ..#context-grep-nvim
