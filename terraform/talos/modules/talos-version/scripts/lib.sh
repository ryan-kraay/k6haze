#!/usr/bin/env bash

# Wrapper for talosctl that suppresses non-critical warnings while preserving other stderr
_talosctl() {
  command talosctl "$@" 2> >(grep -v "server version.*is older than client version" >&2)
}

talos_version() {
  # Check if talosctl is installed
  if ! command -v talosctl &> /dev/null; then
    >&2 echo "Error: talosctl command not found. Please install talosctl."
    return 1
  fi
  
  # Run talosctl and capture output and exit code
  version=$(_talosctl get version -o jsonpath='{.spec.version}' 2>&1)
  exit_code=$?
  
  # Check if command failed
  if [ $exit_code -ne 0 ]; then
    >&2 echo "Error: talosctl command failed (exit code: $exit_code)"
    >&2 echo "Details: $version"
    return 1
  fi
  
  # Check if version is empty
  if [ -z "$version" ]; then
    >&2 echo "Error: No version returned from talosctl. Check connection or configuration."
    return 1
  fi
  
  # Output valid JSON with string value for Terraform
  yq -n -o json ".version = \"$version\""
}

k8s_version() {
  if ! command -v talosctl &> /dev/null; then
    >&2 echo "Error: talosctl command not found. Please install talosctl."
    return 1
  fi
  
  version=$(_talosctl get kubeletconfig -o jsonpath='{.spec.image}' 2>&1)
  exit_code=$?
  
  if [ $exit_code -ne 0 ]; then
    >&2 echo "Error: talosctl command failed (exit code: $exit_code)"
    >&2 echo "Details: $version"
    return 1
  fi
  
  if [ -z "$version" ]; then
    >&2 echo "Error: No kubelet image returned from talosctl."
    return 1
  fi
  
  # Extract version from image path (everything after last ':')
  k8s_ver="${version##*:}"
  yq -n -o json ".version = \"$k8s_ver\""
}

compare_versions() {
  local current="$1"
  local desired="$2"
  
  if [ -z "$current" ] || [ -z "$desired" ]; then
    >&2 echo "Error: Both current and desired versions must be provided"
    return 1
  fi
  
  # Use sort -V for version comparison
  local older=$(printf '%s\n%s\n' "$current" "$desired" | sort -V | head -n1)
  
  if [ "$current" = "$desired" ]; then
    yq -n -o json ".comparison = \"equal\""
  elif [ "$older" = "$current" ]; then
    yq -n -o json ".comparison = \"upgrade\""
  else
    yq -n -o json ".comparison = \"downgrade\""
  fi
}

# Wrapper for rclone with Cloudflare R2 configuration
_rclone() {
  local cmd="${1}"
  local path="${2:-/}"
  local bucket="${TF_VAR_terraform_statefile_bucket}"
  local account_id="${TF_VAR_cloudflare_account_id}"
  
  if [ -z "${cmd}" ]; then
    >&2 echo "Error: rclone command must be provided (e.g., cat, tree, delete)"
    return 1
  fi
  
  if [ -z "${bucket}" ]; then
    >&2 echo "Error: TF_VAR_terraform_statefile_bucket not set"
    return 1
  fi
  
  if [ -z "${account_id}" ]; then
    >&2 echo "Error: TF_VAR_cloudflare_account_id not set"
    return 1
  fi
  
  rclone --log-level ERROR "${cmd}" ":s3,provider=Cloudflare,env_auth=true,endpoint=${account_id}.r2.cloudflarestorage.com:${bucket}${path}" "${@:3}"
}

get_last_wipe_state() {
  # Retrieves the timestamp when a filesystem wipe last occurred, stored on S3.
  # Used to determine if a downgrade requires wiping ephemeral storage and re-bootstrapping.
  local path="${1}"
  
  if [ -z "${path}" ]; then
    >&2 echo "Error: Path must be provided"
    return 1
  fi
  
  if [ -z "${AWS_ACCESS_KEY_ID}" ] || [ -z "${AWS_SECRET_ACCESS_KEY}" ]; then
    >&2 echo "Error: AWS credentials not set"
    return 1
  fi
  
  local content
  content=$(_rclone cat "${path}")
  
  # rclone cat returns exit code 0 even for non-existent files, but outputs empty content
  # So we check if content is empty and return our default JSON in that case
  if [ -z "${content}" ]; then
    echo -n '{"last_wipe_at": "1970-01-01T00:00:00Z"}'
  else
    echo -n "${content}"
  fi
}

# When running via the cli, run this
if [ -z "${SHELLSPEC_ROOT}" ]; then
  # Execute function based on script name or first argument                                                                                           
  case "${1:-$(basename "$0")}" in                                                                                                                    
    "talos_version"|"talos_version.sh") talos_version ;;                                                                                              
    "k8s_version"|"k8s_version.sh") k8s_version ;;
    "compare_versions"|"compare_versions.sh") compare_versions "$2" "$3" ;;
    "get_last_wipe_state"|"get_last_wipe_state.sh") get_last_wipe_state "$2" ;;                                                                                                    
  esac
fi
