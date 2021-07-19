#!/usr/bin/env bash

TARGET_SERVERS=(
	208.67.222.222
	1.1.1.1
	8.8.8.8
	9.9.9.9
	64.6.64.6
	74.82.42.42
)

declare -r DNS_FW_PORT=28842

NAMES=()

function createDnsForwarding1() {
	local NAME TARGET="$1" I="$2"
	local V2R_PORT=$((DNS_FW_PORT + I))

	NAME="main-outbound-dns-$V2R_PORT"
	newInbound <<-JSON
		{
			"tag": "$NAME",
			"protocol": "dokodemo-door",
			"listen": "[::1]",
			"port": $V2R_PORT,
			"settings": {"address": "$TARGET", "port": 53, "network": "tcp,udp"}
		}
	JSON

	local LISTEN=$((38800 + I))

	echo "server=::1#$LISTEN" >>"/etc/v2ray/dns_load_balance.new/dnsmasq.conf"

	cat <<NGX >>"/etc/v2ray/dns_load_balance.new/nginx.conf"
upstream dnsstreams$I {
	# server 10.250.250.0:53 weight=1 backup;
	server [::1]:$V2R_PORT weight=5;
}
server {
	listen [::1]:$LISTEN udp;
	listen [::1]:$LISTEN;

	include log/stream_dns.conf;

	proxy_connect_timeout 5s;
	proxy_pass dnsstreams$II;
}
NGX

	NAMES+=("$NAME")
}

function createDnsForwarding() {
	newOutbound < <(create_direct)

	local I
	local -i II=0
	mkdir -p "/etc/v2ray/dns_load_balance.new"
	for I in "${TARGET_SERVERS[@]}"; do
		createDnsForwarding1 "$I" "$II"
		II=$((II + 1))
	done

	generateRoutingRule <<-JSON
		{
			"type": "field",
			"inboundTag": $(join_strings "${NAMES[@]}"),
			"balancerTag": "any"
		}
	JSON
}
