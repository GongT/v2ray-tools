#!/usr/bin/env bash

set -Eeuo pipefail
cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

mkdir -p test

unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY

URL=$(< "URL.txt")
echo "downloading $URL ..."
wget -v --progress=bar -O test/input "$URL"
bash parse.sh test/input

mkdir -p result
cd result

cp -f ../temp/v2ray.config.json ./config.json
if ! [[ -e .git ]]; then
	git init
else
	git diff
fi

git add config.json
git commit -m "Update at: $(date "+%F %T")" || true

cp config.json /etc/v2ray/
