#!/usr/bin/env bash

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
set -Eeuo pipefail

function info() {
	echo -e "\e[38;5;14m$*\e[0m" >&2
}
function die() {
	echo -e "\e[38;5;9m$*\e[0m" >&2
	exit 1
}

if [[ ${http_proxy:-} ]]; then
	info "using proxy $http_proxy"
	git config --system --replace-all http.proxy "$http_proxy"
	git config --system --replace-all https.proxy "$http_proxy"
else
	info "not using proxy"
	git config --system --unset-all http.proxy
	git config --system --unset-all https.proxy
fi

mapfile -t EXISTS < <(find /opt -path '*/github.com/v2fly/v2ray-core')
if [[ ${#EXISTS[@]} -eq 0 ]]; then
	info "downloading v2ray-core"
	go get -u -v github.com/v2fly/v2ray-core

	mapfile -t EXISTS < <(find /opt -path '*/github.com/v2fly/v2ray-core')
	if [[ ${#EXISTS[@]} -eq 0 ]]; then
		die "go get not create target in GOPATH"
	fi
	info "using downloaded v2ray-core in ${EXISTS[0]}"
else
	info "using exists v2ray-core in ${EXISTS[0]}"
fi

cd "${EXISTS[0]}"

info "go mod download"
go mod download

info "build v2ray"
CGO_ENABLED=0 go build -o /opt/dist/v2ray -trimpath -ldflags "-s -w -buildid=" ./main
info "build v2ctl"
CGO_ENABLED=0 go build -o /opt/dist/v2ctl -trimpath -ldflags "-s -w -buildid=" -tags confonly ./infra/control/main

/opt/dist/v2ray -version
