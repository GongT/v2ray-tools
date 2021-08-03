#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

export INPUTS_DIR="$(pwd)/../inputs"
export RESULTS_DIR="$(pwd)/../result"

source "./v2config.sh"
source "./base.sh"
source "./create-out.sh"
source "./create-local-dns-config.sh"

cd ..

TMPDIR="/dev/shm/v2ray-config-temp"
mkdir -p "$TMPDIR"

trap 'rm -rf $TMPDIR' EXIT

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
	done | jq -cnR '[inputs | select(length>0)]'
}
function join() {
	local I LINES=""
	for I; do
		LINES+=$'\n    '
		LINES+="${PAD:-}"
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

	if ! echo "$DATA" | jq -M --tab >"$FILE"; then
		echo "$DATA" >"$FILE"
		die "Failed format JSON, check file: $FILE"
	fi
}

function callstack() {
	local -i SKIP=${1-1}
	local -i i
	for i in $(seq $SKIP $((${#FUNCNAME[@]} - 1))); do
		if [[ ${BASH_SOURCE[$((i + 1))]+found} == "found" ]]; then
			echo "  $i: ${BASH_SOURCE[$((i + 1))]}:${BASH_LINENO[$i]} ${FUNCNAME[$i]}()"
		else
			echo "  $i: ${FUNCNAME[$i]}()"
		fi
	done
}

function _exit_handle() {
	RET=$?
	set +xe
	echo -ne "\e[0m"
	if [[ $RET -ne 0 ]]; then
		callstack 1
	fi
	exit $RET
}
trap _exit_handle EXIT
