#!/usr/bin/env bash

OUTBOUNDS=()
ROUTING_RULES=()
GENERATE_ROUTING_RULES=()
INBOUNDS=()
BALANCERS=()
BALANCER_NAMES=()
declare -i LB_INDEX=0
LB_NAME=""
ROOT_FIELDS=()

declare -r LEVEL3='            '
declare -r LEVEL2='        '

function _in1() {
	if [[ "${1:-}" ]]; then
		echo "$1"
	else
		cat
	fi
}
function newJsonRootItem() {
	local IN
	IN="$(_in1 "${1:-}")"
	if [[ "$IN" ]]; then
		ROOT_FIELDS+=("$IN")
	fi
}
function newOutbound() {
	OUTBOUNDS+=("$(_in1 "${1:-}")")
}
function newInbound() {
	INBOUNDS+=("$(_in1 "${1:-}")")
}
function newRoutingRule() {
	ROUTING_RULES+=("$(_in1 "${1:-}")")
}
function generateRoutingRule() {
	GENERATE_ROUTING_RULES+=("$(_in1 "${1:-}")")
}
function newLoadBalancer() {
	DATA="$(_in1 "${1:-}")"
	# echo "$DATA" | jq '.tag'
	BALANCERS+=("$DATA")
}
function flushBalancer() {
	if [[ $LB_INDEX -gt 0 ]]; then
		BALANCER_NAMES+=("$LB_NAME")
		newLoadBalancer <<-JSON
			{
				"tag": "$LB_NAME",
				"selector": ["${LB_NAME}_"]
			}
		JSON
	fi
	LB_NAME=""
	LB_INDEX=0
}
function switchOutputTag() {
	LB_NAME="${1}"
	LB_INDEX=0
}

function pushBalancerElement() {
	LB_INDEX=$((LB_INDEX + 1))
	NAME="${LB_NAME}_${LB_INDEX}"
}

function makeConfig() {
	local -a RR=()
	local I GENERATE_FOUND=""
	for I in "${ROUTING_RULES[@]}"; do
		if [[ $I == "@" ]]; then
			if [[ "$GENERATE_FOUND" ]]; then
				die "multiple '@' rule in base.json"
			fi
			GENERATE_FOUND=yes
			RR+=("${GENERATE_ROUTING_RULES[@]}")
		else
			RR+=("$I")
		fi
	done
	if [[ ! $GENERATE_FOUND ]]; then
		RR+=("${GENERATE_ROUTING_RULES[@]}")
	fi
	HASRR=""
	if [[ ${#RR[@]} -gt 0 ]]; then
		HASRR=$',\n'
		HASRR+=
	fi

	format_output "created.json" <<-JSON
		{
			"outbounds": [ $(join "${OUTBOUNDS[@]}")
			],
			"inbounds": [ $(join "${INBOUNDS[@]}")
			],
			"routing": {
				"domainStrategy": "IPIfNonMatch",
				"balancers": [$(join "${BALANCERS[@]}")],
				"rules": [$(join "${RR[@]}")${HASRR}$(finalRoutes)
				]
			}
		}
	JSON

	ANY_LB=$(jq '.routing.balancers[].tag' "$TMPDIR/created.json" | jq -c --slurp '[{"tag":"any","selector":.}]')

	jq -M --tab -s '.[0] * .[1] | .routing.balancers+=$ANY_LB' "base.json" "$TMPDIR/created.json" --argjson ANY_LB "$ANY_LB" >"$TMPDIR/v2ray.config.json"
	echo "result save to $TMPDIR/v2ray.config.json"

	mkdir -p "$RESULTS_DIR"
	cp "$TMPDIR/v2ray.config.json" "$RESULTS_DIR/config.json"

	mapfile -t SERVER_DOMAINS < <(
		cat "$TMPDIR/v2ray.config.json" \
			| jq -r '.outbounds[] | select(.protocol=="vmess") |
		  .settings.vnext[].address?' \
			| grep -oE '[^.]+\.[^.]+$' \
			| sort | uniq \
			| grep -vP '^\d+\.\d+$'
	)
	for I in "${SERVER_DOMAINS[@]}"; do
		echo "server=/.$I/119.29.29.29" >>"/etc/v2ray/dns_load_balance.new/dnsmasq.conf"
		echo "server=/.$I/223.5.5.5" >>"/etc/v2ray/dns_load_balance.new/dnsmasq.conf"
	done
}

function finalRoutes() {
	echo "$(
		jq -M -c <<-JSON
			{
				"type": "field",
				"inboundTag": ["force-proxy"],
				"balancerTag": "any"
			}
		JSON
	),"
	echo "$(
		jq -M -c <<-JSON
			{
				"type": "field",
				"outboundTag": "direct",
				"ip": [ "geoip:private", "geoip:cn" ]
			}
		JSON
	),"

	echo -n ""
	jq -M -c <<-JSON
		{
			"type": "field",
			"network": "tcp,udp",
			"balancerTag": "any"
		}
	JSON
}
