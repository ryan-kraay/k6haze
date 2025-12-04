#!/usr/bin/env bash
#shellcheck shell=bash

add() {
  echo "$1 + $2" | bc
}

if [ -z "${SHELLSPEC_ROOT}" ]; then
  echo "running main script"
  sleep 10
fi
