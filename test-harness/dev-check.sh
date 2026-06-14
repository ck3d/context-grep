#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

set -x

eval "$(direnv export bash)"

make check
nix build ..#context-grep-rs-wrapped
./test-harness ./result/bin/*
nix build ..#context-grep-nvim
./test-harness ./result/bin/*
