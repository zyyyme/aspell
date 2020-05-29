#!/usr/bin/env bash

set -euo pipefail

docker build -t reitermarkus/aspell "$(dirname "${0}")" &>/dev/null
docker run -i --rm -v "${PWD}:${PWD}" -w "${PWD}" reitermarkus/aspell "${@}"
