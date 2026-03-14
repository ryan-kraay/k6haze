#!/usr/bin/env bash
set -euo pipefail

yq -o=json -I=0 '{
  "id": .id,
  "public": .output.public,
  "private": .output.private
}'
