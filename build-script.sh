#!/usr/bin/env bash

set -Eeuo pipefail
cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

if ! [[ "${GOCACHE:-}" ]]; then
	GOCACHE=$(go env GOCACHE)
	if ! [[ "${GOCACHE}" ]]; then
		GOCACHE="${SYSTEM_COMMON_CACHE:-/var/cache}/golang"
	fi
fi

if ! [[ "${GOPROXY:-}" ]]; then
	GOPROXY=$(go env GOPROXY)
fi

mkdir -p "$GOCACHE" "${GOCACHE}.mod"

mkdir -p v2ray-source-code result
VOLS=(
	"--volume=$GOCACHE:/GOCACHE"
	"--volume=${GOCACHE}.mod:/GOMODCACHE"
	"--volume=$(pwd)/result:/opt/dist"
	"--volume=$(pwd)/v2ray-source-code:/opt/source"
)

if ! [[ "${GOPATH:-}" ]]; then
	GOPATH=$(go env GOPATH)
fi
mapfile -t GOPATHS < <(echo "$GOPATH" | sed "s/:/\n/g")
PARENT_GO_PATH=""
I=0
for P in "${GOPATHS[@]}"; do
	P=$(realpath --canonicalize-missing "$P")
	if [[ -d "$P/src" ]]; then
		I=$((I + 1))
		VOLS+=("--volume=$P/src:/opt/gopath/$I/src")
		PARENT_GO_PATH+=":/opt/gopath/$I"
	fi
done

ENVS=(
	GOBIN=/opt/dist
	"GOPATH=/opt/source$PARENT_GO_PATH"
	"GOPROXY=$GOPROXY"
	GOCACHE=/GOCACHE
	GOMODCACHE=/GOMODCACHE
	GO111MODULE=auto
	"HTTP_PROXY=${HTTP_PROXY:-}"
	"HTTPS_PROXY=${HTTPS_PROXY:-}"
	"http_proxy=${http_proxy:-}"
	"https_proxy=${https_proxy:-}"
	"NO_PROXY=${NO_PROXY:-}"
	"no_proxy=${no_proxy:-}"
)

ENVS_ARGS=()
for I in "${ENVS[@]}"; do
	ENVS_ARGS+=("--env=$I")
done

function start() {
	CMD=(run "${VOLS[@]}" "${ENVS_ARGS[@]}" --name="build-v2ray-musl" --network=host --rm -d gongt/alpine-cn:edge)
	echo -e "\e[38;5;14m podman \\" >&2
	for I in "${CMD[@]}"; do
		echo "    $I \\"
	done
	echo -e "    sh\e[0m" >&2
	\podman sh
}
function execp() {
	CMD=(podman exec -i "build-v2ray-musl" "$@")
	echo -e "\e[38;5;14m${CMD[*]}\e[0m" >&2
	"${CMD[@]}"
}

if ! podman inspect --type=container build-v2ray-musl >/dev/null; then
	start
fi

execp apk add -U go git bash
execp bash <lib/build-script-content.sh
