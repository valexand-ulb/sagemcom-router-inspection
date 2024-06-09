#!/bin/ash
# shellcheck shell=dash

DSL_WAN_IFACE=${MOFF_DSL_WAN_IFACE:-"$(uci -P/var/state get network.wan.ifname)"}
ENABLE_IPv4=${MOFF_ENABLE_IPV4:-1}
ENABLE_IPv6=${MOFF_ENABLE_IPV6:-1}

is_ipv4_enabled() {
	[ "${ENABLE_IPv4}" = 1 ]
}

is_ipv6_enabled() {
	[ "${ENABLE_IPv6}" = 1 ]
}

is_dsl_up() {
	# Use 'ifconfig ${DSL_WAN_IFACE}' if ip missing
	ip addr show "${DSL_WAN_IFACE}" 2>/dev/null | grep -q "UP"
}

has_ipv4() {
	ip addr show "${DSL_WAN_IFACE}" 2>/dev/null | grep -q "inet "
}

has_ipv6() {
	ip addr show "${DSL_WAN_IFACE}" 2>/dev/null | grep "global" | grep -q "inet6"
}

# Line 1: Return whether DSL interface is up (0=Down 1=Up)
IS_DSL_UP=false

if is_dsl_up; then
	if is_ipv4_enabled && is_ipv6_enabled; then
		{ has_ipv4 || has_ipv6 ; } && IS_DSL_UP=true
	elif is_ipv4_enabled; then
		has_ipv4 && IS_DSL_UP=true
	elif is_ipv6_enabled; then
		has_ipv6 && IS_DSL_UP=true
	fi
fi

if ${IS_DSL_UP}; then
	echo 1
else
	echo 0
fi

# Line 2 & 3: Return DSL Up and Down speeds (in Kbps)
# Beware that xdslctl could return multiple 'bearer', adjust the awk command if needed
xdslctl info | grep Bearer | awk 'NR==1 { print $6"\n"$11 }' || exit 1
