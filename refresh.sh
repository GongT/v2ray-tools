#!/usr/bin/env bash

set -Eeuo pipefail
cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

bash parse.sh test/input

mkdir -p result
cd result

cp -f ../temp/v2ray.config.json ./config.json
if ! [[ -e .git ]]; then
	git init
else
	git diff --color=always | cat
fi

git add config.json
git commit -m "Update at: $(date "+%F %T")" || true

cp config.json /etc/v2ray/
/etc/init.d/v2ray restart