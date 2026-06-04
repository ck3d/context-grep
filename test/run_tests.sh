#!/usr/bin/env bash

# Test script for context-grep using jaq

set -e

# run_test NAME QUERY FILES ASSERTION
#   Runs context-grep and checks ASSERTION (a jaq boolean filter) against the
#   JSON output. Prints the output and exits on failure.
run_test() {
  local name="$1" query="$2" files="$3" assertion="$4"
  echo "Testing: $name"
  local output
  output=$(nix run . -- "$query" $files)
  if echo "$output" | jaq -e "$assertion" > /dev/null; then
    echo "✓ Success: $name"
  else
    echo "✗ Failure: $name"
    echo "$output" | jaq .
    exit 1
  fi
}

run_test "match this" "match this" "test/sample.lua" \
  '(.[0].target.text | contains("local function bar()")) and .[0].file == "test/sample.lua"'

run_test "inner comment" "inner comment" "test/sample.lua" \
  '.[0].target.text == "return x"'

run_test "trailing comment" "trailing" "test/sample.lua" \
  '.[0].target.text == "local y = 1"'

run_test "multiple files" "TODO" "test/sample.lua test/sample2.lua" \
  'length >= 4'
