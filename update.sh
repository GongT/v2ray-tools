#!/usr/bin/env bash

set -Eeuo pipefail
cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

mkdir -p test

unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY

URL=$(< "URL.txt")
echo "downloading $URL ..."
wget -v --progress=bar -O test/input "$URL"

bash refresh.sh
