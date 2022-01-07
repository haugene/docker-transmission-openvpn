#!/bin/bash

DEBUG=${DEBUG:-"false"}
[[ ${DEBUG} != "false" ]] && set -x || true

log() {
  printf "%b\n" "$*" >/dev/stderr
}

fatal_error() {
  printf "\e[41mERROR:\033[0m %b\n" "$*" >&2
  exit 1
}