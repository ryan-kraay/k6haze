#!/usr/bin/env bash
set -euo pipefail

# Read input from stdin
input=$(cat)

path=$(echo "$input" | yq -r '.input.path')
content=$(echo "$input" | yq -r '.input.content')
content_type=$(echo "$input" | yq -r '.input.type')
age_key=$(echo "$input" | yq -r '.input.age_key')

# Create directory if needed
mkdir -p "$(dirname "$path")"

# Calculate sha256 of unencrypted content
sha256=$(echo -n "$content" | sha256sum | awk '{print $1}')

# Encrypt content directly without writing unencrypted to disk
echo -n "$content" | SOPS_AGE_RECIPIENTS="$age_key" sops --input-type "${content_type}" --output-type "${content_type}" -e /dev/stdin > "$path"

# Return result
echo "{\"id\":\"$path\",\"content_sha256\":\"$sha256\"}"
