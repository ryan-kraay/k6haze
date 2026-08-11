#!/usr/bin/env bash
set -euo pipefail

output=$(age-keygen 2>&1)
created=$(echo "$output" | grep "created:" | awk '{print $3}')
public=$(echo "$output" | grep "public key:" | awk '{print $4}')
private=$(echo "$output" | grep "AGE-SECRET-KEY")

echo "{\"id\":\"$created\",\"public\":\"$public\",\"private\":\"$private\"}"
