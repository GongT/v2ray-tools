#!/usr/bin/env bash

set -Eeuo pipefail
# shellcheck source=lib/fn.sh
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib/fn.sh"

bash parse.sh

mkdir -p result
cd result

cp -f "$TMPDIR/v2ray.config.json" ./config.json

if [[ ${V2RAY_LOCATION_ASSET+found} != found ]]; then
	export V2RAY_LOCATION_ASSET=/data/geoip
fi

v2ray -config ./config.json -test || die "Invalid config file."

if ! [[ -e .git ]]; then
	git init
else
	git diff --color=always | cat
fi

git add config.json
git commit -m "Update at: $(date "+%F %T")" || true

cp config.json /etc/v2ray/
/etc/init.d/v2ray restart

rm -rf "/etc/v2ray/dns_load_balance.old"
[[ -e "/etc/v2ray/dns_load_balance" ]] && mv "/etc/v2ray/dns_load_balance" "/etc/v2ray/dns_load_balance.old"
mv "/etc/v2ray/dns_load_balance.new" "/etc/v2ray/dns_load_balance"

if nginx -t; then
	/etc/init.d/nginx restart
	rm -rf "/etc/v2ray/dns_load_balance.old"
else
	rm -rf "/etc/v2ray/dns_load_balance"
	mv "/etc/v2ray/dns_load_balance.old" "/etc/v2ray/dns_load_balance"
fi

/etc/init.d/dnsmasq-multi-instance reload
