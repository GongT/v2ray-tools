#!/usr/bin/env bash

declare -r DEFAULT_BALANCER_NAME="default_load_balancer"

OUTBOUNDS=()
ROUTING_RULES=()
GENERATE_ROUTING_RULES=()
INBOUNDS=()
BALANCERS=()
DEFAULT_LB=()
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
	ROUTING_RULES+=("$(_in1 "${1:-}" | sed "s/DEFAULT_BALANCER_NAME/$DEFAULT_BALANCER_NAME/g")")
}
function generateRoutingRule() {
	GENERATE_ROUTING_RULES+=("$(_in1 "${1:-}" | sed "s/DEFAULT_BALANCER_NAME/$DEFAULT_BALANCER_NAME/g")")
}
function newLoadBalancer() {
	BALANCERS+=("$(_in1 "${1:-}")")
}
function pushDefaultBalancer() {
	DEFAULT_LB+=("$@")
}

function makeConfig() {
	newLoadBalancer <<-JSON
		{
			"tag": "$DEFAULT_BALANCER_NAME",
			"selector": $(join_strings "${DEFAULT_LB[@]}")
		}
	JSON

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

	jq -M --tab -s '.[0] * .[1]' "base.json" "$TMPDIR/created.json" >"$TMPDIR/v2ray.config.json"
}

function finalRoutes() {
	echo "$(
		jq -M -c <<-JSON
			{
				"type": "field",
				"inboundTag": ["force-proxy"],
				"balancerTag": "$DEFAULT_BALANCER_NAME"
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
			"balancerTag": "$DEFAULT_BALANCER_NAME"
		}
	JSON
}
