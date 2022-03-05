#!/usr/bin/env bash

set -euo pipefail

docker build -t ghcr.io/reitermarkus/aspell:main "$(dirname "${0}")"
docker run -it --rm -v "${PWD}:${PWD}" -w "${PWD}" reitermarkus/aspell "${@}"
