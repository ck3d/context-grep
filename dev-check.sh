#!/usr/bin/env bash
set -eux

for script in ./*/dev-check.sh; do
    $script
done
