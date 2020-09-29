#!/usr/bin/env bash

declare -r DEFAULT_BALANCER_NAME="default_load_balancer"

OUTBOUNDS=()
ROUTING_RULES=()
INBOUNDS=()
BALANCERS=()
DEFAULT_LB=()
ROOT_FIELDS=()

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
	ROUTING_RULES+=("$(_in1 "${1:-}" | sed "s/DEFAULT_BALANCER_NAME/$DEFAULT_BALANCER_NAME/g")")
}
function newLoadBalancer() {
	BALANCERS+=("$(_in1 "${1:-}")")
}
function pushDefaultBalancer() {
	DEFAULT_LB+=("$@")
}

function makeConfig() {
	newLoadBalancer <<- JSON
		{
			"tag": "$DEFAULT_BALANCER_NAME",
			"selector": $(join_strings "${DEFAULT_LB[@]}")
		}
	JSON

	format_output "created.json" <<- JSON
		{
			"outbounds": [ $(join "${OUTBOUNDS[@]}")
			],
			"inbounds": [ $(join "${INBOUNDS[@]}")
			],
			"routing": {
				"domainStrategy": "IPIfNonMatch",
				"balancers": [ $(join "${BALANCERS[@]}")
				],
				"rules": [ $(join "${ROUTING_RULES[@]}")
				]
			}
		}
	JSON

	jq -M --tab -s '.[0] * .[1]' "base.json" "$TMPDIR/created.json" > "$TMPDIR/v2ray.config.json"
}

newRoutingRule <<- JSON
	{
		"type": "field",
		"network": "tcp,udp",
		"balancerTag": "$DEFAULT_BALANCER_NAME"
	}
JSON

newRoutingRule <<- JSON
	{
		"type": "field",
		"outboundTag": "direct",
		"ip": [ "geoip:private", "geoip:cn" ]
	}
JSON

newRoutingRule <<- JSON
	{
		"type": "field",
		"inboundTag": ["force-proxy"],
		"balancerTag": "$DEFAULT_BALANCER_NAME"
	}
JSON
