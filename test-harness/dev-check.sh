#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
direnv allow .
eval "$(direnv export bash)"

set -x

make check
./test-harness context-grep
