#!/usr/bin/env bash

function readBaseJson() {
	local JSON JSON_LINES I IFS=$'\n'
	JSON=$(< "./base.json")

	mapfile -t JSON_LINES < <(query "$JSON" -r '.inbounds[] // ""' 2> /dev/null)
	for I in "${JSON_LINES[@]}"; do
		newInbound "$I"
	done

	mapfile -t JSON_LINES < <(query "$JSON" -r '.outbounds[] // ""' 2> /dev/null)
	for I in "${JSON_LINES[@]}"; do
		newOutbound "$I"
	done

	mapfile -t JSON_LINES < <(query "$JSON" -r '.routing.balancers[] // ""' 2> /dev/null)
	for I in "${JSON_LINES[@]}"; do
		newLoadBalancer "$I"
	done
	mapfile -t JSON_LINES < <(query "$JSON" -r '.routing.rules[] // ""' 2> /dev/null)
	for I in "${JSON_LINES[@]}"; do
		newRoutingRule "$I"
	done
}
