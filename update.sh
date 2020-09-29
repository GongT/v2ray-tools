#!/usr/bin/env bash

set -Eeuo pipefail
cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY

URL=$(< "URL.txt")
echo "downloading $URL ..."
wget -v --progress=bar -O "$TMPDIR/input.downloading" "$URL" || die "failed download file, is network ok?"

mv "$TMPDIR/input.downloading" "$TMPDIR/input"

bash refresh.sh
