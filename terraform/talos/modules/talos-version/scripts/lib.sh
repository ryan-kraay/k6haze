#!/usr/bin/env bash

# Wrapper for talosctl that suppresses non-critical warnings while preserving other stderr
_talosctl() {
  command talosctl "$@" 2> >(grep -v "server version.*is older than client version" >&2)
}

talos_version() {
  # Check if talosctl is installed
  if ! command -v talosctl &> /dev/null; then
    >&2 echo "Error: talosctl command not found. Please install talosctl."
    exit 1
  fi
  
  # Run talosctl and capture output and exit code
  version=$(_talosctl get version -o jsonpath='{.spec.version}' 2>&1)
  exit_code=$?
  
  # Check if command failed
  if [ $exit_code -ne 0 ]; then
    >&2 echo "Error: talosctl command failed (exit code: $exit_code)"
    >&2 echo "Details: $version"
    exit 1
  fi
  
  # Check if version is empty
  if [ -z "$version" ]; then
    >&2 echo "Error: No version returned from talosctl. Check connection or configuration."
    exit 1
  fi
  
  # Output valid JSON with string value for Terraform
  yq -n -o json ".version = \"$version\""
}

k8s_version() {
  if ! command -v talosctl &> /dev/null; then
    >&2 echo "Error: talosctl command not found. Please install talosctl."
    exit 1
  fi
  
  version=$(_talosctl get kubeletconfig -o jsonpath='{.spec.image}' 2>&1)
  exit_code=$?
  
  if [ $exit_code -ne 0 ]; then
    >&2 echo "Error: talosctl command failed (exit code: $exit_code)"
    >&2 echo "Details: $version"
    exit 1
  fi
  
  if [ -z "$version" ]; then
    >&2 echo "Error: No kubelet image returned from talosctl."
    exit 1
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

# When running via the cli, run this
if [ -z "${SHELLSPEC_ROOT}" ]; then
  # Execute function based on script name or first argument                                                                                           
  case "${1:-$(basename "$0")}" in                                                                                                                    
    "talos_version"|"talos_version.sh") talos_version ;;                                                                                              
    "k8s_version"|"k8s_version.sh") k8s_version ;;
    "compare_versions"|"compare_versions.sh") compare_versions "$2" "$3" ;;                                                                                                    
  esac
fi
