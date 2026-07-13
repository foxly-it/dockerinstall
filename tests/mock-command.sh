#!/usr/bin/env bash
set -Eeuo pipefail

command_name=""
command_name="$(basename "$0")"
printf '%s %s\n' "$command_name" "$*" >> "${MOCK_LOG:?MOCK_LOG is required}"

case "$command_name" in
  apt-get)
    exit 0
    ;;
  curl)
    output=""
    while [ "$#" -gt 0 ]; do
      case "$1" in
        -o)
          shift
          output="${1:-}"
          ;;
      esac
      shift
    done
    [ -n "$output" ] || exit 2
    printf '%s\n' 'mock docker signing key' > "$output"
    ;;
  dpkg)
    [ "${1:-}" = "--print-architecture" ] || exit 2
    printf '%s\n' "${MOCK_ARCH:-amd64}"
    ;;
  dpkg-query)
    package="${*: -1}"
    case " ${MOCK_INSTALLED_PACKAGES:-} " in
      *" $package "*) printf 'ii '\''\n' ;;
      *) exit 1 ;;
    esac
    ;;
  systemctl)
    if [ "${1:-}" = "is-active" ]; then
      [ "${MOCK_DOCKER_RUNNING:-1}" = "1" ]
    fi
    ;;
  docker)
    case "${1:-}" in
      --version) printf '%s\n' 'Docker version 29.0.0, build mock' ;;
      compose) printf '%s\n' 'Docker Compose version v2.mock' ;;
      buildx) printf '%s\n' 'github.com/docker/buildx v0.mock' ;;
      info) exit 0 ;;
      run) printf '%s\n' 'Hello from Docker!' ;;
      *) exit 2 ;;
    esac
    ;;
  usermod)
    exit 0
    ;;
  *)
    printf 'Unsupported mock command: %s\n' "$command_name" >&2
    exit 2
    ;;
esac
