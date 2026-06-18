#!/usr/bin/env bash
set -eux

for script in ./*/dev-check.sh; do
    nix develop .#dev-check --unset PATH --command "$script"
done
nix fmt -- --fail-on-change
