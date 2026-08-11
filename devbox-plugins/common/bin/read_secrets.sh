#!/usr/bin/env bash
# Usage: read_secrets.sh <secrets_dir> [GITHUB_ENV_FILE]
# Outputs shell-sourceable lines for all *.sops.env and *.sops.raw files.
# Intended to be used as: set -a; source <(read_secrets.sh /path/to/secrets); set +a
#
# If GITHUB_ENV_FILE is provided (pass $GITHUB_ENV in GHA), secrets are instead
# written to that file with masking, suitable for use in GitHub Actions.
set -euo pipefail
shopt -s nullglob

dir="${1:?Usage: read_secrets.sh <secrets_dir> [GITHUB_ENV_FILE]}"
if [[ ! -d "${dir}" ]]; then
  echo "read_secrets.sh: directory not found: ${dir}" >&2
  exit 1
fi
github_env="${2:-}"

_emit() {
  local key="$1" value="$2"
  if [[ -n "${github_env}" ]]; then
    echo "::add-mask::${value}"
    printf '%s=%s\n' "${key}" "${value}" >> "${github_env}"
  else
    printf '%s=%s\n' "${key}" "${value}"
  fi
}

for file in "${dir}"/*.sops.env; do
  while IFS= read -r line; do
    [[ -z "${line}" || "${line}" == \#* ]] && continue
    key="${line%%=*}"
    value="${line#*=}"
    _emit "${key}" "${value}"
  done < <(sops -d "${file}")
done

for file in "${dir}"/*.sops.raw; do
  _emit "$(basename "${file}" .sops.raw)" "$(sops -d "${file}")"
done
