#!/usr/bin/env bash

set -Eeuo pipefail

# shellcheck source=lib/fn.sh
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib/fn.sh"

readBaseJson

mapfile -t FILES < <(find "$INPUTS_DIR" -type f)
for FPATH in "${FILES[@]}"; do
	CONTENT=$(<"$FPATH")

	switchOutputTag "$(basename "${FPATH}")"
	parseInput "$CONTENT"
	flushBalancer
done
createDnsForwarding
makeConfig
