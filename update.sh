#!/usr/bin/env bash

set -Eeuo pipefail
# shellcheck source=lib/fn.sh
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib/fn.sh"

unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY

mkdir -p "$TMPDIR/inputs"

mapfile -t URLS <"URL.txt"
for LINE in "${URLS[@]}"; do
	[[ $LINE ]] || continue

	TAG=${LINE##*#}
	URL=${LINE%%#*}

	[[ $TAG ]] || die "input line invalid (no tag): $LINE"
	[[ $URL ]] || die "input line invalid (no url): $LINE"

	warn "[$TAG] downloading $URL ..."
	wget -v --progress=bar -O "$TMPDIR/inputs/.downloading" "$URL" || die "failed download file, is network ok?"

	mv "$TMPDIR/inputs/.downloading" "$TMPDIR/inputs/$TAG"
done

bash refresh.sh
