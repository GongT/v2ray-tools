#!/usr/bin/env bash

set -Eeuo pipefail

export V2RAY_LOCATION_ASSET=/data/geoip

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

/usr/bin/v2ray -config "/dev/shm/v2ray-config-temp/v2ray.config.json"
