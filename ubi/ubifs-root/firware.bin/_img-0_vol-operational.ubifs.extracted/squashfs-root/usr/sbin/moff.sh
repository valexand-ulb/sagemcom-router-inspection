#!/bin/ash
# shellcheck shell=dash
#
# Copyright (C) 2016 Tessares SA <http://www.tessares.net>
#
# Unauthorized copying of this file, via any medium, is strictly prohibited.
#
# See the AUTHORS file for a list of contributors.

[ ${#} -lt 1 ] && echo "Usage: ${0} EVENT" >&2 && exit 1
EVENT="${1}"

##################
# MOFF Variables #
##################
# Can be set via environement variables in order to overwrite the default ones
# Location of the library file libmoff.sh
MOFF_LIBRARY_FILE=${MOFF_LIBRARY_FILE:-"$(dirname "$0")/../lib/moff/libmoff.sh"}
# Location of the script file backup.sh
MOFF_BACKUP_FILE=${MOFF_BACKUP_FILE:-"/usr/sbin/moff_backup.sh"}
# Location of the temporary file where we store rules to applied in order to
# cleanup the installed ones for the bonding.
MOFF_CLEANUP_FILE=${MOFF_CLEANUP_BACKUP_FILE:-"/tmp/moff_cleanup_file"}
# Debug variable
MOFF_DEBUG=${MOFF_DEBUG:-0}
# Number of the mark that will be used on packets for routing purpose
IP_MARK=${MOFF_IP_MARK:-"43"}
# Number of the lookup table for the previous mark (we use the same)
IP_TABLE=${MOFF_IP_TABLE:-"43"}
# Location of a temporary file used in order to maintain the state of the backup.
# This file will be used only by this script.
MOFF_BACKUP_STATE_FILE=${MOFF_BACKUP_STATE_FILE:-"/tmp/moff_backup_on"}
# Enable IPv4
ENABLE_IPv4=${MOFF_ENABLE_IPV4:-1}
# Enable IPv6
ENABLE_IPv6=${MOFF_ENABLE_IPV6:-1}
# Optional flags for iptables
IPTABLES_FLAGS=${MOFF_IPTABLES_FLAGS:-"-w"}
# Optional flags for ebtables
EBTABLES_FLAGS=${MOFF_EBTABLES_FLAGS:-"--concurrent"}
# Size of the subnet given by the ISP (DHCPv6-DP)
DHCP_V6_DP_SIZE=${MOFF_DHCPV6_DELEGATE_PREFIX_SIZE:-56}
# set to 1 if ebtables version works with "! --match x" instead
# of "--match ! x"
BUG_EBTABLES=${MOFF_BUG_EBTABLES:-}
# Priority to use when setting up the ip rules lookup table in IPv4. Should be
# the same number or higher of the local table in ``ip rules`` such that the
# installed lookup table by moff.sh is just after the local one.
# Can be set to "-1" to not use priority (if not supported, not recommanded).
IP_RU_PRIO_V4=${MOFF_IP_RU_PRIO_V4:-0}
# Same as previous but for IPv6
IP_RU_PRIO_V6=${MOFF_IP_RU_PRIO_V6:-0}
# Command to use to launch ebtables
EBTABLES=${MOFF_EBTABLES:-ebtables}
# Command to use to launch iptables
IPTABLES=${MOFF_IPTABLES:-iptables}
# Command to use to launch ip6tables
IP6TABLES=${MOFF_IP6TABLES:-ip6tables}
# Command to use to launch ip
CMD_IP=${MOFF_IP:-ip}
# Command to use to launch ping
# shellcheck disable=SC2034
CMD_PING=${MOFF_PING:-ping}
# Command to use to launch ping6
# shellcheck disable=SC2034
CMD_PING6=${MOFF_PING6:-ping6}
# Use another chain than FORWARD to force QUIC using TCP
FORWARD_CHAIN=${MOFF_FORWARD_CHAIN:-"FORWARD"}
# Do Not enable hairpin feature to bridge packets back to the same port
BYPASS_HAIRPIN=${MOFF_BYPASS_HAIRPIN:-0}
# Guest LAN bridge for "Guest WiFi" in case it should benefit from bonding too
GUEST_BR_LAN_IFACE=${MOFF_GUEST_BR_LAN_IFACE:-}
# IPv4 prefix of the interface of the bridge (e.g. 192.168.1.0/24)
DSL_BR_PREFIX=${MOFF_DSL_BR_PREFIX:-}
# IPv6 prefix of the interface of the bridge (e.g. 2001:2:1::0/64)
DSL_BR_PREFIX6=${MOFF_DSL_BR_PREFIX6:-}
# Interface name of the bridge
DSL_BR_LAN_IFACE=${MOFF_DSL_BR_LAN_IFACE:-}
# Mac address of the interface of the bridge
DSL_BR_MAC=${MOFF_DSL_BR_MAC:-}
# Interface name of the wan
DSL_WAN_IFACE=${MOFF_DSL_WAN_IFACE:-}
# If non null, do not divert TCP/ICMP/UDP:443 traffic from internet towards MProxy
SKIP_ROUTING_WAN_LTE=${MOFF_SKIP_ROUTING_WAN_LTE:-}
# If non null, the latest status is printed into the specified file.
MOFF_STATUS_FILE=${MOFF_STATUS_FILE:-}

###################
# Given Variables #
###################
# Should be set (provided) by moff binary
LTE_BR_MAC=${MOFF_LTE_BR_MAC}
LTE_BR_IP=${MOFF_LTE_BR_IP}
LTE_BR_IP6=${MOFF_LTE_BR_IP6}
QUIC_TO_TCP=${MOFF_QUIC_TO_TCP:-1}
MPROXY_RA_PROTO_VERSION=${MOFF_MPROXY_RA_PROTO_VERSION}
BACKUP_ENABLED=${MOFF_BACKUP_ENABLED:-0}
BACKUP_DNS_ENABLED=${MOFF_BACKUP_DNS_ENABLED:-1}
BACKUP_DNS_PRIMARY=${MOFF_BACKUP_DNS_PRIMARY:-}
BACKUP_DNS_SECONDARY=${MOFF_BACKUP_DNS_SECONDARY:-}
# not used, could be used for blacklisting (possible improvement)
TRANSPARENT=${MOFF_TRANSPARENT}
PREVIOUS_PID=${MOFF_PID_PREVIOUS}
MOFF_OWN_PID=${MOFF_OWN_PID}

#############
# FUNCTIONS #
#############

# Import network functions
if test -f /lib/functions/network.sh; then
	# shellcheck disable=SC1091
	. /lib/functions/network.sh
fi

# Import MOff Library functions
if [ ! -f "${MOFF_LIBRARY_FILE}" ]; then
	echo "ERROR: Moff Library file cannot be found at ${MOFF_LIBRARY_FILE}," >&2
	echo "please change the MOFF_LIBRARY_FILE variable in ${0}, exiting" >&2
	exit 1
else
	# shellcheck source=libmoff.sh
	. "${MOFF_LIBRARY_FILE}"
fi

# Check backup script exists
if [ "${BACKUP_ENABLED}" = "1" ] && [ ! -f "${MOFF_BACKUP_FILE}" ]; then
	echo "WARNING: Moff backup file cannot be found at ${MOFF_BACKUP_FILE}," >&2
	echo "Please change the MOFF_BACKUP_FILE variable in ${0}." >&2
	echo "Continuing, backup mode will not work." >&2
fi

get_v4_net_settings() {
	libmoff_is_ipv4_enabled || return 0
	DSL_BR_PREFIX=${DSL_BR_PREFIX:-$(ip addr show dev "${DSL_BR_LAN_IFACE}" \
	                                 | grep "inet " | awk -F" " '{print $2}' \
	                                 | sed -e 's/\.[[:digit:]]\+\//.0\//')}
}

get_v6_net_settings() {
	libmoff_is_ipv6_enabled || return 0
	# IPv6 of the bridge without the prefix (e.g 2001:41d0:52:e00::525)
	DSL_BR_IP6=$(echo "${DSL_BR_PREFIX6:-$(ip -6 addr show dev "${DSL_BR_LAN_IFACE}" scope global \
	                                       | grep "inet6" \
	                                       | awk -F" " '{print $2}')}" \
	            | awk -F'/' '{ print $1 }') # trim prefix

	# The IPv6 with the prefix (e.g 2001:41d0:52:e00::525/64)
	DSL_BR_LARGE_SUBNET6="${DSL_BR_IP6}/${DHCP_V6_DP_SIZE}"
}

NET_SETTINGS_LOADED=0
get_net_settings() {
	[ "${NET_SETTINGS_LOADED}" = "1" ] && return 0

	# Sample working on openWRT
	DSL_BR_LAN_IFACE=${DSL_BR_LAN_IFACE:-$(uci -P/var/state get network.lan.ifname)}
	DSL_BR_MAC=${DSL_BR_MAC:-$(ifconfig "${DSL_BR_LAN_IFACE}" \
	                           | grep HWaddr | awk '{ print $5 }')}
	DSL_WAN_IFACE=${DSL_WAN_IFACE:-$(uci -P/var/state get network.wan.ifname)}
	# Interface name where the MProxy agent is connected
	LTE_BR_IFACE=$(libmoff_br_get_iface_from_mac "${DSL_BR_LAN_IFACE}" "${LTE_BR_MAC}")
	# Note: also available in /sys/devices/virtual/net/${LTE_BR_IFACE}
	# The sys-path to the hairpin_mode (e.g.
	#                     "/sys/class/net/${LTE_BR_IFACE}/brport/hairpin_mode")
	HAIRPIN_MODE_PATH="/sys/class/net/${LTE_BR_IFACE}/brport/hairpin_mode"

	get_v4_net_settings
	get_v6_net_settings

	# Mark settings as loaded
	NET_SETTINGS_LOADED=1
}

moff_backup() {
	# Get network settings
	get_net_settings

	# Export needed variables
	export \
		BACKUP_DNS_ENABLED \
		BACKUP_DNS_PRIMARY \
		BACKUP_DNS_SECONDARY \
		BUG_EBTABLES \
		CMD_IP \
		DSL_BR_LAN_IFACE \
		DSL_BR_LARGE_SUBNET6 \
		DSL_BR_MAC \
		DSL_BR_PREFIX \
		EBTABLES \
		EBTABLES_FLAGS \
		ENABLE_IPv4 \
		ENABLE_IPv6 \
		IP6TABLES \
		IPTABLES \
		IPTABLES_FLAGS \
		LTE_BR_IP \
		LTE_BR_IP6 \
		LTE_BR_MAC \
		MOFF_DEBUG \
		MOFF_CLEANUP_FILE

	# Launch backup script
	${MOFF_BACKUP_FILE} "$1"
}

# $1: ip version (4 or 6); $2: IP(6) proto; [ $3: src port ]
_internet_redirect_to_mproxy() { local IP_VERSION IP_PROTO SRC_PORT
	IP_VERSION=${1}
	IP_PROTO=${2}
	SRC_PORT=${3:-}
	"libmoff_is_ipv${IP_VERSION}_enabled" || return 0
	"libmoff_ip${IP_VERSION}tables_run" mangle PREROUTING \
		-i "${DSL_WAN_IFACE}" \
		-p "${IP_PROTO}" \
		${SRC_PORT:+--sport ${SRC_PORT}} \
		-j MARK --set-mark "${IP_MARK}/${IP_MARK}"
}

# Redirector function (see libmoff_setup_redirected_traffic)
# $1: IP proto ; [ $2: src port ]
internet_redirect_v4_to_mproxy() {
	_internet_redirect_to_mproxy 4 "${@}"
}

# Redirector function (see libmoff_setup_redirected_traffic)
# $1: IP6 proto ; [ $2: src port ]
internet_redirect_v6_to_mproxy() {
	_internet_redirect_to_mproxy 6 "${@}"
}

# Redirector function (see libmoff_setup_redirected_traffic)
# $1: IP proto ; [ $2: src port ]
guest_lan_redirect_v4_to_mproxy() { local IP_PROTO DEST_PORT
	libmoff_is_ipv4_enabled || return 0
	IP_PROTO=${1}
	DEST_PORT=${2:-}
	libmoff_ip4tables_run mangle PREROUTING \
		-i "${GUEST_BR_LAN_IFACE}" \
		-p "${IP_PROTO}" \
		! -d "${DSL_BR_PREFIX}" \
		${DEST_PORT:+--dport ${DEST_PORT}} \
		-j MARK --set-mark "${IP_MARK}/${IP_MARK}"
}

# Redirector function (see libmoff_setup_redirected_traffic)
# $1: IP6 proto ; [ $2 src port ]
guest_lan_redirect_v6_to_mproxy() { local IP6_PROTO DEST_PORT
	libmoff_is_ipv6_enabled || return 0
	IP6_PROTO=${1}
	DEST_PORT=${2:-}
	libmoff_ip6tables_run mangle PREROUTING \
		-i "${GUEST_BR_LAN_IFACE}" \
		-p "${IP6_PROTO}" \
		! -d "${DSL_BR_LARGE_SUBNET6}" \
		${DEST_PORT:+--dport ${DEST_PORT}} \
		-j MARK --set-mark "${IP_MARK}/${IP_MARK}"
}

# Builds redirector function (see libmoff_setup_redirected_traffic)
build_lan_redirect_v4_to_mproxy() {
	# In case IPv4 is disabled, DSL_BR_PREFIX would not be defined and Bash
	# would trigger an error (set -nounset). We thus default to empty since the
	# underlying function will anyway return immediately.
	echo "libmoff_redirect_v4_to_device ${DSL_BR_MAC} ${LTE_BR_MAC} \
	                                    ${DSL_BR_LAN_IFACE} \
	                                    ${DSL_BR_PREFIX:-}"
}

# Builds redirector function (see libmoff_setup_redirected_traffic)
build_lan_redirect_v6_to_mproxy() {
	# In case IPv6 is disabled, DSL_BR_LARGE_SUBNET6 would not be defined and
	# Bash would trigger an error (set -nounset). We thus default to empty
	# since the underlying function will anyway return immediately.
	echo "libmoff_redirect_v6_to_device ${DSL_BR_MAC} ${LTE_BR_MAC} \
	                                    ${DSL_BR_LAN_IFACE} \
	                                    ${DSL_BR_LARGE_SUBNET6:-}"
}

setup_lan_redirection_to_mproxy() {
	# See libmoff to learn about the "redirected traffic".
	#
	# As clients have their default gateway set to the DSLbox, the destination
	# MAC of frames belonging to the "redirected traffic" will be the MAC of
	# the DSLbox. For clients connected behind the DSLbox, or in-between the
	# DSLbox and the LTEbox, we must redirect these frames as they arrive by
	# changing the destination MAC. The LTEbox will then route these flows.
	#
	# In order not to confuse a switch that could be present between both
	# gateways, the source MAC address is also changed to the local one.
	# Otherwise the switch would possibly see the same source MAC on different
	# ports (where client device is connected and where MOff is connected) and
	# would start sending packets destined for the client to MOff.
	libmoff_setup_redirected_traffic ebtables \
	                                 "$(build_lan_redirect_v4_to_mproxy)" \
	                                 "$(build_lan_redirect_v6_to_mproxy)"

	if [ -n "${GUEST_BR_LAN_IFACE}" ]; then
		# If we want to provide bonding for a Guest WiFi, we force the
		# routing of the redireced traffic from the Guest bridge to MProxy by
		# setting the same mark as is used for routing return traffic from the
		# internet back to MProxy (see setup_internet_redirection_to_mproxy).
		libmoff_setup_redirected_traffic iptables \
		                                 guest_lan_redirect_v4_to_mproxy \
		                                 guest_lan_redirect_v6_to_mproxy
	fi
}

setup_internet_redirection_to_mproxy() {
	# See libmoff to learn about the "redirected traffic".
	#
	# The "redirected traffic" coming back from the internet should also be
	# redirected towards the DSLbox.
	libmoff_setup_redirected_traffic iptables \
	                                 internet_redirect_v4_to_mproxy \
	                                 internet_redirect_v6_to_mproxy

	if [ "${IP_RU_PRIO_V4}" != "-1" ]; then
		IP_RU_PRIO_V4_RULE="priority ${IP_RU_PRIO_V4}"
	else
		unset IP_RU_PRIO_V4_RULE
	fi

	if [ "${IP_RU_PRIO_V6}" != "-1" ]; then
		IP_RU_PRIO_V6_RULE="priority ${IP_RU_PRIO_V6}"
	else
		unset IP_RU_PRIO_V6_RULE
	fi

	libmoff_ip_rule "${IP_RU_PRIO_V4_RULE}" fwmark "${IP_MARK}/${IP_MARK}" lookup "${IP_TABLE}"
	libmoff_ip_run route "${LTE_BR_IP}/32" table "${IP_TABLE}" dev "${DSL_BR_LAN_IFACE}"
	libmoff_ip_run route default via "${LTE_BR_IP}" dev "${DSL_BR_LAN_IFACE}" table "${IP_TABLE}"
	libmoff_ip6_rule "${IP_RU_PRIO_V6_RULE}" fwmark "${IP_MARK}/${IP_MARK}" lookup "${IP_TABLE}"
	libmoff_ip6_run route "${LTE_BR_IP6}/128" table "${IP_TABLE}" dev "${DSL_BR_LAN_IFACE}"
	libmoff_ip6_run route default via "${LTE_BR_IP6}" dev "${DSL_BR_LAN_IFACE}" table "${IP_TABLE}"
}

setup_bonding_redirection() {
	# Get network settings
	get_net_settings

	# Check parameters
	test -z "${LTE_BR_MAC}" && \
		echo "No MAC address for the LTE bridge" >&2 && exit 1
	test "${TRANSPARENT}" = "1" -a -z "${LTE_BR_IP}" && \
		echo "No IP address for the LTE bridge" >&2 && exit 1

	setup_lan_redirection_to_mproxy

	if [ "${BYPASS_HAIRPIN}" = "1" ]; then
		echo "Bridge's hairpin feature is NOT enable"
	elif [ -f "${HAIRPIN_MODE_PATH}" ]; then
		# Avoid forwarding Multicast frame back to the same port, needed for Hairpin
		libmoff_ebtables_run filter FORWARD \
			-i" ${LTE_BR_IFACE}" \
			-o "${LTE_BR_IFACE}" \
			-d Multicast \
			-j DROP

		# Allow forwarding frames back out through the port the frame was received on
		libmoff_write_file "${HAIRPIN_MODE_PATH}" "1" "0"
	else
		echo "WARNING: Hairpin mode is not supported, kernel older than v2.6.31?"
		echo "It will not be possible to bridge packets back to the same port."
		echo "If you don't want to support this, please set MOFF_BYPASS_HAIRPIN=1"
		exit 1
	fi

	if [ -z "${SKIP_ROUTING_WAN_LTE}" ]; then
		setup_internet_redirection_to_mproxy
	fi

	# If MPROXY is running the old QUIC fallback method (with iptables rules on
	# both moff and mproxy), then QUIC traffic originating from a client connected
	# to the LTE box would NOT be forced to fallback. Such traffic would be bridged
	# by mproxy to the moff, as per the old method it was the responsibility of the
	# moff to respond with an icmp-port-unreachable. The moff must thus take care
	# of forcing the fallback. In such configuration, any UDP:443 will be forced to
	# fallback.
	if [ "${QUIC_TO_TCP}" = "1" ] && [ "${MPROXY_RA_PROTO_VERSION}" = "1" ]; then
		libmoff_ip4tables_run filter "${FORWARD_CHAIN}" \
			-p udp \
			-m udp --dport "${QUIC_DEST_PORT}" \
			-j REJECT --reject-with icmp-port-unreachable
		libmoff_ip6tables_run filter "${FORWARD_CHAIN}" \
			-p udp \
			-m udp --dport "${QUIC_DEST_PORT}" \
			-j REJECT --reject-with icmp6-port-unreachable
	fi
}

abort_if_bridge_calls_iptables() {
	# Better not to use netfilter for L2 packages
	# sysctl -w net.bridge.bridge-nf-call-iptables=0
	if [ "$(cat /proc/sys/net/bridge/bridge-nf-call-iptables 2>/dev/null)" = "1" ]; then
		echo "ERROR: please disable bridge-nf-call-iptables" >&2
		exit 1
	fi
}

##########
# EVENTS #
##########

on_connected() {
	# To be sure that rules are cleared
	libmoff_cleanup_rules_silent

	# To be sure that the script does not consider us in backup mode
	rm -f "${MOFF_BACKUP_STATE_FILE}"
}

on_disconnected() {
	# Remove bonding redirection
	# Cleanup file might not exist if moff was not previously/yet connected
	libmoff_cleanup_rules || true

	# Remove backup redirection
	if [ "${BACKUP_ENABLED}" = "1" ]; then
		rm -f "${MOFF_BACKUP_STATE_FILE}" && moff_backup "OFF"
	fi
}

on_dsl_up() {
	# Remove backup redirection if activated
	if [ "${BACKUP_ENABLED}" = "1" ] && [ -f "${MOFF_BACKUP_STATE_FILE}" ]; then
		rm -f "${MOFF_BACKUP_STATE_FILE}" && moff_backup "OFF"
	fi

	setup_bonding_redirection
}

on_dsl_down() {
	# Remove bonding redirection
	libmoff_cleanup_rules_silent

	# Install backup redirection if enabled
	if [ "${BACKUP_ENABLED}" = "1" ]; then
		touch "${MOFF_BACKUP_STATE_FILE}" && moff_backup "ON"
	fi
}

#######
# RUN #
#######

abort_if_bridge_calls_iptables

[ "${MOFF_DEBUG}" = "1" ] && echo "Received event: ${EVENT}"

libmoff_wait_previous_or_suicide "${PREVIOUS_PID}" "${MOFF_OWN_PID}" "RA (MOff)"

# Different case depending of the event
case ${EVENT} in
	"CONNECTED")
		echo "MProxy agent connected"
		on_connected
		;;
	"DISCONNECTED")
		echo "MProxy agent disconnected"
		on_disconnected
		;;
	"DSL_UP")
		echo "DSL line UP"
		on_dsl_up
		;;
	"DSL_DOWN")
		echo "DSL line DOWN"
		on_dsl_down
		;;
	*)
		echo "Event ${EVENT} is not supported" >&2 && exit 1
		;;
esac

[ "${MOFF_DEBUG}" = "1" ] && echo "End of actions for event: ${EVENT}"
[ -n "${MOFF_STATUS_FILE}" ] && echo "${EVENT}" > "${MOFF_STATUS_FILE}"
exit 0
