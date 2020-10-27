#!/usr/bin/env bash

set -Eeuo pipefail
# shellcheck source=lib/fn.sh
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib/fn.sh"

unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY

URL=$(<"URL.txt")
warn "downloading $URL ..."
wget -v --progress=bar -O "$TMPDIR/input.downloading" "$URL" || die "failed download file, is network ok?"

mv "$TMPDIR/input.downloading" "$TMPDIR/input"

bash refresh.sh
