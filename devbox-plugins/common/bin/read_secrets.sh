#!/usr/bin/env bash
# Usage: read_secrets.sh <secrets_dir>
# Outputs shell-sourceable lines for all *.sops.env and *.sops.raw files.
# Intended to be used as: set -a; source <(read_secrets.sh /path/to/secrets); set +a
set -euo pipefail
shopt -s nullglob

dir="${1:?Usage: read_secrets.sh <secrets_dir>}"

for file in "${dir}"/*.sops.env; do
  sops -d "${file}"
done

for file in "${dir}"/*.sops.raw; do
  printf '%s=%q\n' "$(basename "${file}" .sops.raw)" "$(sops -d "${file}")"
done
