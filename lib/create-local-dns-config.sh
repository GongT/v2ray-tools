#!/usr/bin/env bash

TARGET_SERVERS=(
	208.67.222.222
	1.1.1.1
	8.8.8.8
	9.9.9.9
	64.6.64.6
	74.82.42.42
)

declare -i DNS_FW_PORT=28842

NAMES=()

function createDnsForwarding1() {
	local NAME TARGET="$1"
	NAME="main-outbound-dns-$DNS_FW_PORT"
	newInbound <<- JSON
		{
			"tag": "$NAME",
			"protocol": "dokodemo-door",
			"port": $DNS_FW_PORT,
			"settings": {"address": "$TARGET", "port": 53, "network": "tcp,udp"}
		}
	JSON
	NAMES+=("$NAME")
	DNS_FW_PORT="$DNS_FW_PORT + 1"
}

function createDnsForwarding() {
	local I
	for I in "${TARGET_SERVERS[@]}"; do
		createDnsForwarding1 "$I"
	done

	generateRoutingRule <<- JSON
		{
			"type": "field",
			"inboundTag": $(join_strings "${NAMES[@]}"),
			"balancerTag": "DEFAULT_BALANCER_NAME"
		}
	JSON
}
