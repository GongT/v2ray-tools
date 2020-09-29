#!/usr/bin/env bash

set -Eeuo pipefail

# shellcheck source=lib/fn.sh
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib/fn.sh"

if [[ "$#" -eq 0 ]]; then
	CONTENT=$(cat)
else
	CONTENT=$(< "$1")
fi
declare -r CONTENT="$CONTENT"

readBaseJson
parseInput "$CONTENT"
createDnsForwarding
makeConfig
