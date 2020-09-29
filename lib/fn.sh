#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

source "./v2config.sh"
source "./base.sh"
source "./create-out.sh"
source "./create-local-dns-config.sh"

cd ..

TMPDIR="$(pwd)/temp"
mkdir -p "$TMPDIR"

function die() {
	echo -e "\e[38;5;9m$*\e[0m" >&2
	exit 1
}
function warn() {
	echo -e "\e[38;5;3m$*\e[0m" >&2
}
function mute() {
	echo -e "\e[2m$*\e[0m" >&2
}
function join_strings() {
	local I
	for I; do
		echo "$I"
	done | jq -nR '[inputs | select(length>0)]'
}
function join() {
	local I LINES=""
	for I; do
		LINES+=$'\n    '
		LINES+="$I,"
	done
	if [[ "$LINES" ]]; then
		echo "${LINES::-1}"
	fi
}

function query() {
	local JSON="$1"
	shift
	echo "$JSON" | jq -c -M "$@"
}

function format_output() {
	local FILE="$TMPDIR/$1"
	local DATA
	DATA=$(cat)

	if ! echo "$DATA" | jq -M --tab > "$FILE"; then
		echo "$DATA" > "$FILE"
		exit 1
	fi
}
