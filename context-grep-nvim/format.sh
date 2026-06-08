#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

set -x

eval "$(direnv export bash)"

stylua context-grep-nvim.lua
