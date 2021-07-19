#!/usr/bin/env bash

function generateTcp() {
	local DATA NAME

	pushBalancerElement

	newOutbound <<-JSON
		{
			"!title": "$ps",
			"tag": "${NAME}",
			"protocol": "vmess",
			"settings": {"vnext": [$(createVnext)]},
			"mux": {"enabled": false},
			"streamSettings": {"network": "tcp"}
		}
	JSON
}

function generateWs() {
	local DATA NAME

	pushBalancerElement

	newOutbound <<-JSON
		{
			"!title": "$ps",
			"tag": "${NAME}",
			"protocol": "vmess",
			"settings": {"vnext": [$(createVnext)]},
			"mux": {"enabled": false},
			"streamSettings": {"network": "ws", "security": "tls", "wsSettings": {"path": "/v2"}}
		}
	JSON
}

function createVnext() {
	cat <<-JSON
		{
			"address": "$add",
			"port": $port,
			"users": [{
				"id": "$id",
				"alterId": $aid
			}]
		}
	JSON
}

function create_direct() {
	cat <<-JSON
		{
			"tag": "direct",
			"protocol": "freedom",
			"settings": {}
		}
	JSON
}

function parseVMESS() {
	local EXEC JSON="$1"

	local -r QUERY='to_entries[] | .key + "=" + (.value|tostring) + ""'
	while read -r EXEC; do
		local -r "$EXEC"
	done < <(echo "$JSON" | jq -r "$QUERY")

	case "$net" in
	tcp)
		generateTcp
		;;
	ws)
		generateWs
		;;
	*)
		warn "unknown vmess transform: $JSON"
		;;
	esac
}
function parseSS() {
	local EXEC ARGS="$1"
	local URL=${ARGS%#*} PARAM=${ARGS#*#}
	URL=$(echo "$URL" | base64 -d)

	echo "format SS: $URL | $PARAM"

	newOutbound <<-JSON
		{
			"!title": "$ps",
			"tag": "${NAME}",
			"protocol": "vmess",
			"settings": {"vnext": [$(createVnext)]},
			"mux": {"enabled": false},
			"streamSettings": {"network": "tcp"}
		}
	JSON
}

function parseInput() {
	local DATA="$1" URLS URL JSON

	if [[ $DATA == vmess://* ]]; then
		mapfile -t URLS < <(echo "$DATA")
	else
		mapfile -t URLS < <(echo "$DATA" | base64 -d)
	fi

	for URL in "${URLS[@]}"; do
		if [[ $URL == vmess://* ]]; then
			JSON=$(echo "${URL:8}" | base64 -d)
			parseVMESS "$JSON"
		# elif [[ $URL == ss://* ]]; then
		# 	parseSS "${URL:5}"
		else
			mute "found unknown protocol: $URL"
		fi
	done
}
