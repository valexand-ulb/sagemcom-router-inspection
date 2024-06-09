#!/bin/ash
# shellcheck shell=dash
#
# Copyright (C) 2017 Tessares SA <http://www.tessares.net>
#
# Unauthorized copying of this file, via any medium, is strictly prohibited.
#
# See the AUTHORS file for a list of contributors.

# These variables should be set any script that sources libmoff.sh.
: "${CMD_IP:?}"
: "${EBTABLES:?}"
: "${EBTABLES_FLAGS:?}"
: "${ENABLE_IPv4:?}"
: "${ENABLE_IPv6:?}"
: "${IP6TABLES:?}"
: "${IPTABLES:?}"
: "${IPTABLES_FLAGS:?}"
: "${MOFF_CLEANUP_FILE:?}"

# Static variables
# We could use 'tcp' and 'icmp' but the file '/etc/ethertypes' or
# '/etc/protocols' could be missing
export IP_PROTO_ICMP6=58
export IP_PROTO_ICMP=1
export IP_PROTO_TCP=6
export IP_PROTO_UDP=17
export ICMP6_DESTINATION_UNREACHABLE=1
export ICMP6_PACKET_TOO_BIG=2
export ICMP6_TIME_EXCEEDED=3
export ICMP6_PARAMETER_PROBLEM=4
export ICMP6_INTERCEPTED_RANGE="${ICMP6_DESTINATION_UNREACHABLE}:${ICMP6_PARAMETER_PROBLEM}"
export ICMP6_ECHO_REQUEST=128
export ICMP6_ECHO_REPLY=129
export ICMP6_ECHO_RANGE="${ICMP6_ECHO_REQUEST}:${ICMP6_ECHO_REPLY}"
export ICMP6_NDP_MLD_RANGE="130:137"
export IPV6_LINK_LOCAL_RANGE="fe80::/10"
export QUIC_DEST_PORT=443

# Find if sleep .1 works
CMD_SLEEP_FAST=0
# Time to wait for fct libmoff_wait_pid
SLEEP_TIME=30

# Force the cleanup of existing rules
libmoff_cleanup_rules_silent() {
	[ ! -f "${MOFF_CLEANUP_FILE}" ] && return 0
	while read -r RULE; do
		eval "${RULE}" || echo "Command ${RULE} exited with ${?}" >&2
	done <"${MOFF_CLEANUP_FILE}"
	rm -f "${MOFF_CLEANUP_FILE}"
}

# cleanup rules (soft)
libmoff_cleanup_rules() {
	if [ ! -f "${MOFF_CLEANUP_FILE}" ]; then
		echo "Tried to clean rules but ${MOFF_CLEANUP_FILE} does not exist" >&2 && return 1
	fi
	libmoff_cleanup_rules_silent
}

# launch a command and track the "remove rule" associated
_cmd_launch() {
	ADD_CMD=$1
	DEL_CMD=$2
	[ "${MOFF_DEBUG}" = "1" ] && { echo "Running: ${ADD_CMD}"; }
	eval "${ADD_CMD}" || { echo "ERROR with: ${ADD_CMD}" >&2; return 1; }
	[ "${MOFF_DEBUG}" = "1" ] && { echo "Saving in ${MOFF_CLEANUP_FILE}: ${DEL_CMD}"; }
	echo "${DEL_CMD}" >> "${MOFF_CLEANUP_FILE}"
}

# Run ebtables rule
libmoff_ebtables_run() {
	TABLE=$1
	shift
	_cmd_launch "${EBTABLES} ${EBTABLES_FLAGS} -t ${TABLE} -A ${*}" \
	            "${EBTABLES} ${EBTABLES_FLAGS} -t ${TABLE} -D ${*}"
}

# Run ebtables rule v4
libmoff_ebtables4_run() {
	# shellcheck disable=SC2154
	libmoff_is_ipv4_enabled || return 0
	libmoff_ebtables_run "${@}" "-p IPv4"
}

# Run ebtables rule v6
libmoff_ebtables6_run() {
	# shellcheck disable=SC2154
	libmoff_is_ipv6_enabled || return 0
	libmoff_ebtables_run "${@}" "-p IPv6"
}

# Run iptables rule v4
libmoff_ip4tables_run() {
	libmoff_is_ipv4_enabled || return 0
	TABLE=$1
	shift
	_cmd_launch "${IPTABLES} ${IPTABLES_FLAGS} -t ${TABLE} -A ${*}" \
	            "${IPTABLES} ${IPTABLES_FLAGS} -t ${TABLE} -D ${*}"
}

# Run iptables rule v6
libmoff_ip6tables_run() {
	libmoff_is_ipv6_enabled || return 0
	TABLE=$1
	shift
	_cmd_launch "${IP6TABLES} ${IPTABLES_FLAGS} -t ${TABLE} -A ${*}" \
	            "${IP6TABLES} ${IPTABLES_FLAGS} -t ${TABLE} -D ${*}"
}

# Run iptables rules v4 and v6
libmoff_iptables_run() {
	libmoff_ip4tables_run "${@}"
	libmoff_ip6tables_run "${@}"
}

# run ip command v4
libmoff_ip_run() {
	libmoff_is_ipv4_enabled || return 0
	TYPE=$1
	shift
	_cmd_launch "${CMD_IP} ${TYPE} add ${*}" \
	            "${CMD_IP} ${TYPE} del ${*}"
}

# run ip command v6
libmoff_ip6_run() {
	libmoff_is_ipv6_enabled || return 0
	TYPE=$1
	shift
	_cmd_launch "${CMD_IP} -6 ${TYPE} add ${*}" \
	            "${CMD_IP} -6 ${TYPE} del ${*}"
}

# run ip rule command v4
libmoff_ip_rule() {
	libmoff_is_ipv4_enabled || return 0
	PRIORITY=${1}
	shift
	_cmd_launch "${CMD_IP} rule add ${*} ${PRIORITY}" \
	            "${CMD_IP} rule del ${*}"
}

# run ip rule command v6
libmoff_ip6_rule() {
	libmoff_is_ipv6_enabled || return 0
	PRIORITY=${1}
	shift
	_cmd_launch "${CMD_IP} -6 rule add ${*} ${PRIORITY}" \
	            "${CMD_IP} -6 rule del ${*}"
}

# return 0 (true) if ENABLE_IPv4
libmoff_is_ipv4_enabled(){
	[ "${ENABLE_IPv4}" = "1" ]
}

# return 0 (true) if ENABLE_IPv6
libmoff_is_ipv6_enabled(){
	[ "${ENABLE_IPv6}" = "1" ]
}

# Check if sleep .1 is supported
libmoff_check_sleep_mod() {
	if sleep .001 2>/dev/null; then
		CMD_SLEEP_FAST=1
		SLEEP_TIME=300
	fi
}

# Sleep 1 or .1 depending of support
libmoff_mproxy_sleep() {
	if [ "${CMD_SLEEP_FAST}" -eq 1 ]; then
		sleep .1
	else
		sleep 1
	fi
}

# Print a message each second
# $1: iteration; $2: message
libmoff_echo_wait() {
	if [ "${CMD_SLEEP_FAST}" -eq 1 ]; then
		# $((arith)) unsupported on somes boxes (need busybox CONFIG_FEATURE_SH_MATH=y)
		# shellcheck disable=SC2003
		if [ "$(expr "${1}" % 10)" -ne 0 ]; then
			return
		fi
	fi
	echo "${2}"
}

# Wait after the execution of a PID during 60 sec. It is required
# to run libmoff_check_sleep_mod function before.
# $1: PID to wait
libmoff_wait_pid() {
	PREVIOUS_PID=${1}
	if test -n "${PREVIOUS_PID}" && \
	   grep -q "${0}" "/proc/${PREVIOUS_PID}/cmdline"; then
		[ "${MOFF_DEBUG}" = "1" ] && echo "Wait for the end of PID: ${PREVIOUS_PID}"
		# $((arith)) unsupported on somes boxes (need busybox CONFIG_FEATURE_SH_MATH=y)
		# shellcheck disable=SC2003
		for i in $(seq "$(expr ${SLEEP_TIME} "*" 2)"); do
			if [ ! -d "/proc/${PREVIOUS_PID}" ]; then
				break;
			fi
			[ "${MOFF_DEBUG}" = "1" ] && libmoff_echo_wait "${i}" 'Previous process still running, waiting 1 second'
			libmoff_mproxy_sleep
		done

		if [ -d "/proc/${PREVIOUS_PID}" ]; then
			return 1
		fi

		[ "${MOFF_DEBUG}" = "1" ] && echo "PID ${PREVIOUS_PID} is no longer running"
		return 0
	fi
}

# Due to a bug in ebtables, some versions use rules where the
# negation mark (!) is needed before some IP6 options
_check_ebtables_ip6_bug() {
	libmoff_is_ipv6_enabled || return 0
	export BUG_EBTABLES=1

	# shellcheck disable=SC2086
	if "${EBTABLES}" ${EBTABLES_FLAGS} -t nat -A PREROUTING \
		-p IPv6 \
		-s 99:99:99:99:99:99 \
		-d 99:99:99:99:99:99 \
		--ip6-protocol "${IP_PROTO_ICMP6}" ! --ip6-destination ::/0 \
		-j DROP > /dev/null 2>&1; \
	then
		"${EBTABLES}" ${EBTABLES_FLAGS} -t nat -D PREROUTING \
			-p IPv6 \
			-s 99:99:99:99:99:99 \
			-d 99:99:99:99:99:99 \
			--ip6-protocol "${IP_PROTO_ICMP6}" ! --ip6-destination ::/0 \
			-j DROP
	else
		BUG_EBTABLES=0
	fi
}

_set_ebtables_ip6_fixing_vars() {
	libmoff_is_ipv6_enabled || return 0
	[ -z "${BUG_EBTABLES}" ] && _check_ebtables_ip6_bug
	export NOT_PRE_EBT NOT_SUF_EBT
	if [ "${BUG_EBTABLES}" -eq 1 ]; then
		NOT_PRE_EBT="!"
		NOT_SUF_EBT=""
	else
		NOT_PRE_EBT=""
		NOT_SUF_EBT="!"
	fi
}

# $1: name of the bridge ; $2: MAC address
_br_get_port_from_mac() {
	# inspired by: https://lists.openwrt.org/pipermail/openwrt-devel/2014-September/028231.html
	hexdump -v -e '5/1 "%02x:" /1 "%02x" /1 " %x" /1 " %x" 1/4 " %i" 1/4 "\n"' \
		"/sys/class/net/${1}/brforward" | \
			grep "${2}" | \
			awk '{ printf "0x%x",$2 }'
}

# $1: name of the bridge ; $2: Port ID in hexa (0x\x)
_br_get_iface_from_port() {
	PREV_PWD=${PWD}
	cd "/sys/class/net/${1}/brif/" || return 1

	for iface in *; do
		[ "$(cat "${iface}/port_no")" = "${2}" ] && echo "${iface}" && break
	done

	cd "${PREV_PWD}" || return 1
}

# $1: name of the bridge ; $2: MAC address
libmoff_br_get_iface_from_mac() {
	_br_get_iface_from_port "${1}" "$(_br_get_port_from_mac "${1}" "${2}")"
}

# $1 : IPv4/IPv6 addr to reach ; $2 : device
libmoff_get_gateway() { local ADDR DEV
	ADDR=${1}
	DEV=${2}
	${CMD_IP} route get "${ADDR}" dev "${DEV}" | head -n1 | \
	    sed 's/.*via[[:blank:]]\([a-fA-F0-9:\.]\+\)[[:blank:]].*/\1/' | \
	    grep '^[a-fA-F0-9:\.]\+$'
}

# $1: file ; $2 new value ; $3 old value
libmoff_write_file() {
	_cmd_launch "echo ${2} > ${1}" \
	            "echo ${3} > ${1}"
}

# $1: my MAC ; $2 other MAC ; $3 input iface ; $4 dest IP to exclude ; [ $5 ip proto ; [ $6 dest port ]]
_pre_redirect_v4_to_device() { local MY_MAC OTHER_MAC IN_IFACE DEST_IP IP_PROTO DEST_PORT
	MY_MAC=${1}
	OTHER_MAC=${2}
	IN_IFACE=${3}
	DEST_IP=${4}
	IP_PROTO=${5:-}
	DEST_PORT=${6:-}
	libmoff_ebtables4_run nat "PREROUTING \
		-s ! ${OTHER_MAC} -d ${MY_MAC} --logical-in ${IN_IFACE} \
		${IP_PROTO:+--ip-proto ${IP_PROTO}} \
		${DEST_PORT:+--ip-destination-port ${DEST_PORT}} \
		--ip-destination ! ${DEST_IP} \
		-j dnat --to-destination ${OTHER_MAC} --dnat-target CONTINUE"
}

# $1: my MAC ; $2 other MAC ; $3 input iface ; $4 dest IPv6 to exclude ; [ $5 ip6 proto ; [ $6 dest port ]]
_pre_redirect_v6_to_device() { local MY_MAC OTHER_MAC IN_IFACE DEST_IP6 IP6_PROTO DEST_PORT
	MY_MAC=${1}
	OTHER_MAC=${2}
	IN_IFACE=${3}
	DEST_IP6=${4}
	IP6_PROTO=${5:-}
	DEST_PORT=${6:-}
	libmoff_ebtables6_run nat "PREROUTING \
		-s ! ${OTHER_MAC} -d ${MY_MAC} --logical-in ${IN_IFACE} \
		${IP6_PROTO:+--ip6-proto ${IP6_PROTO}} \
		${DEST_PORT:+--ip6-destination-port ${DEST_PORT}} \
		${NOT_PRE_EBT} --ip6-source ${NOT_SUF_EBT} ${IPV6_LINK_LOCAL_RANGE} \
		${NOT_PRE_EBT} --ip6-destination ${NOT_SUF_EBT} ${DEST_IP6} \
		-j dnat --to-destination ${OTHER_MAC} --dnat-target CONTINUE"
	# --ip6-source -> Never redirect link-local traffic.
}

# $1: my MAC ; $2 other MAC ; $3 input iface (UNUSED) ; $4 dest IP to exclude ; [ $5 ip proto ; [ $6 dest port ]]
_post_redirect_v4_to_device() { local MY_MAC OTHER_MAC IN_IFACE DEST_IP IP_PROTO DEST_PORT
	MY_MAC=${1}
	OTHER_MAC=${2}
	IN_IFACE=${3}   # UNUSED but kept for common signature with the _pre_redirect functions
	DEST_IP=${4}
	IP_PROTO=${5:-}
	DEST_PORT=${6:-}
	libmoff_ebtables4_run nat "POSTROUTING \
		-d ${OTHER_MAC} \
		${IP_PROTO:+--ip-proto ${IP_PROTO}} \
		${DEST_PORT:+--ip-destination-port ${DEST_PORT}} \
		--ip-destination ! ${DEST_IP} \
		-j snat --to-source ${MY_MAC} --snat-target CONTINUE"
}

# $1: my MAC ; $2 other MAC ; $3 input iface (UNUSED) ; $4 dest IPv6 to exclude ; [ $5 ip6 proto ; [ $6 dest port ]]
_post_redirect_v6_to_device() { local MY_MAC OTHER_MAC IN_IFACE DEST_IP6 IP6_PROTO DEST_PORT
	MY_MAC=${1}
	OTHER_MAC=${2}
	IN_IFACE=${3}   # UNUSED but kept for common signature with the _pre_redirect functions
	DEST_IP6=${4}
	IP6_PROTO=${5:-}
	DEST_PORT=${6:-}
	libmoff_ebtables6_run nat "POSTROUTING \
		-d ${OTHER_MAC} \
		${IP6_PROTO:+--ip6-proto ${IP6_PROTO}} \
		${DEST_PORT:+--ip6-destination-port ${DEST_PORT}} \
		${NOT_PRE_EBT} --ip6-source ${NOT_SUF_EBT} ${IPV6_LINK_LOCAL_RANGE} \
		${NOT_PRE_EBT} --ip6-destination ${NOT_SUF_EBT} ${DEST_IP6} \
		-j snat --to-source ${MY_MAC} --snat-target CONTINUE"
	# --ip6-source -> Never redirect link-local traffic.
}

# $1: my MAC ; $2 other MAC ; $3 input iface ; $4 dest IP to exclude ; [ $5 ip proto ; [ $6 dest port ]]
libmoff_redirect_v4_to_device() {
	libmoff_is_ipv4_enabled || return 0
	_pre_redirect_v4_to_device "${@}"
	_post_redirect_v4_to_device "${@}"
}

# $1: my MAC ; $2 other MAC ; $3 input iface ; $4 dest IPv6 to exclude ; [ $5 ip6 proto ; [ $6 dest port ]]
libmoff_redirect_v6_to_device() {
	libmoff_is_ipv6_enabled || return 0
	_pre_redirect_v6_to_device "${@}"
	_post_redirect_v6_to_device "${@}"
}

# $1: Redirector utility (iptables or ebtables)
# $2: IPv4 redirector function
# $3: IPv6 redirector function
# A redirector function MUST accept the following args: $1 ip(6) ; [ $2 dest port ]
libmoff_setup_redirected_traffic() { local REDIRECTOR_UTILITY \
		IPV4_REDIRECTOR_FUNC IPV6_REDIRECTOR_FUNC ICMP6_TYPE_OPTION
	REDIRECTOR_UTILITY=${1}
	IPV4_REDIRECTOR_FUNC=${2}
	IPV6_REDIRECTOR_FUNC=${3}
	# In a MOFF setup, some flows sent by the clients and with destination IP
	# on the internet MUST be ROUTED (layer 3) by the BA on the LTE box. These
	# flows compose the "redirected traffic":
	#  - TCP flows, to allow interception and provide bonding with MPTCP.
	#  - ICMP packets needed by the TCP/IP stack to function properly such as
	#    those linked to TCP sessions (i.e "Packet too big").
	#  - UDP:443 flows, to inspect these packets and force a fallback to TCP in
	#    case of QUIC traffic. This redirection limits the need to support
	#    iptables BPF filtering on the LTEbox box only.
	#
	# Different actions, implemented by a redirector function, must be taken on
	# both the BA and the RA to ensure that this "redirected traffic" is always
	# routed by the RA:
	# - On the RA, we must redirect traffic from clients connected on the LAN
	#   behind the RA towards the BA. Since the default gateway for these
	#   clients is the RA, the BA would otherwise not route it.
	# - Still on the RA, we must redirect traffic coming back from the Internet
	#   towards the BA. Since we are transparent and reuse the client's IP, the
	#   RA would otherwise route these to the client directly, bypassing the BA.
	# - On the BA, we broute traffic originating from clients connected behind
	#   the BA to avoid an unecessary round-trip via the RA.
	${IPV4_REDIRECTOR_FUNC} "${IP_PROTO_TCP}"
	${IPV6_REDIRECTOR_FUNC} "${IP_PROTO_TCP}"

	# See XWiki for discussion of ICMPs that we must redirect.
	# https://xwiki.tessares.net/xwiki/bin/view/dev/ICMPs%20brouting%20redirection/
	case "${REDIRECTOR_UTILITY}" in
		iptables)
			ICMP6_TYPE_OPTION=--icmpv6-type
			;;
		ebtables)
			ICMP6_TYPE_OPTION=--ip6-icmp-type
			;;
		*)
			echo "ERROR: unsupported redirector utility" >&2 && exit 1
			;;
	esac

	# 4 things to note:
	#  - While ip(6) tables supports filtering on ICMPv4 type, ebtables does not.
	#    Compared to ICMPv6 this should not be an issue to redirect all ICMPv4
	#    as functions such as NDP and MLD functions are performed by other
	#    protocols in IPv4 (ARP and IGMP respectively).
	#  - While we could redirect ICMP subtypes with iptables, we want to be
	#    consistent and always redirect the exact same traffic in all
	#    directions, be it with ip(6)tables or ebtables. We thus always
	#    redirect all of ICMPv4, regardless of the redirector utility.
	#  - While ebtables supports ICMP type ranges, ip(6)tables does not.
	#  - While it is not needed to redirect ICMPv6 echo requests/replies, we
	#    chose to redirect them as well in IPv6 such that pings behave the same
	#    way in IPv4 and IPv6.
	${IPV4_REDIRECTOR_FUNC} "${IP_PROTO_ICMP}"

	if [ "${REDIRECTOR_UTILITY}" = ebtables ]; then
		# We can optimize by using ICMP ranges.
		${IPV6_REDIRECTOR_FUNC} "${IP_PROTO_ICMP6} ${ICMP6_TYPE_OPTION} ${ICMP6_INTERCEPTED_RANGE}"
		${IPV6_REDIRECTOR_FUNC} "${IP_PROTO_ICMP6} ${ICMP6_TYPE_OPTION} ${ICMP6_ECHO_RANGE}"
	else
		# No ICMPv6 range support with ip6tables, we must add multiple rules
		# ICMP6_INTERCEPTED_RANGE
		${IPV6_REDIRECTOR_FUNC} "${IP_PROTO_ICMP6} ${ICMP6_TYPE_OPTION} ${ICMP6_DESTINATION_UNREACHABLE}"
		${IPV6_REDIRECTOR_FUNC} "${IP_PROTO_ICMP6} ${ICMP6_TYPE_OPTION} ${ICMP6_PACKET_TOO_BIG}"
		${IPV6_REDIRECTOR_FUNC} "${IP_PROTO_ICMP6} ${ICMP6_TYPE_OPTION} ${ICMP6_TIME_EXCEEDED}"
		${IPV6_REDIRECTOR_FUNC} "${IP_PROTO_ICMP6} ${ICMP6_TYPE_OPTION} ${ICMP6_PARAMETER_PROBLEM}"
		# ICMP6_ECHO_RANGE
		${IPV6_REDIRECTOR_FUNC} "${IP_PROTO_ICMP6} ${ICMP6_TYPE_OPTION} ${ICMP6_ECHO_REQUEST}"
		${IPV6_REDIRECTOR_FUNC} "${IP_PROTO_ICMP6} ${ICMP6_TYPE_OPTION} ${ICMP6_ECHO_REPLY}"
	fi

	if [ "${QUIC_TO_TCP}" = "1" ]; then
		${IPV4_REDIRECTOR_FUNC} "${IP_PROTO_UDP}" "${QUIC_DEST_PORT}"
		${IPV6_REDIRECTOR_FUNC} "${IP_PROTO_UDP}" "${QUIC_DEST_PORT}"
	fi
}

_trap_error() { local ERR_CODE LINE_NO
	ERR_CODE=$1
	LINE_NO=$2
	echo "ERROR: a command failed at line ${LINE_NO} - exited with status: ${ERR_CODE}"
}

# This should only be used in a development environment
_enable_debug() {
	set -o xtrace   # Print commands just before execution.
	set -o errexit  # Shell exits when a command in a command list exits non-zero.
	set -o errtrace # ERR-traps are inherited by by shell functions, command
	                # substitutions, and commands executed in a subshell environment.
	# set -o pipefail # Disabled, see why in the note below:
	                # The exit code from a pipeline is different from the normal
	                # ("last command in pipeline") behaviour: TRUE when no
	                # command failed, FALSE when something failed (code of the
	                # rightmost command that failed).
	                # NOTE: disabled because if we have 'A | B' and B finishes before
	                # A, pipefail would consider there is a failure while this is
	                # maybe the intended behaviour, e.g. 'yes | head -n1', 'head'
	                # command will finish before 'yes' ; same with 'grep -q', etc.
	set -o nounset  # Treat unset variables as an error when performing parameter
	                # expansion.

	# While trapping ERR is not supported in Ash, this debug mode is only used
	# in development environment, where Ash is actually a symlink to Bash.
	# shellcheck disable=SC2169
	trap '_trap_error $? $LINENO' ERR
}

# $1 : previous PID ; $2 current PID ; $3 name
libmoff_wait_previous_or_suicide() { local PREVIOUS_PID CALLER_PID NAME
	PREVIOUS_PID=${1}; shift
	CALLER_PID=${1}; shift
	NAME=${1}; shift

	libmoff_check_sleep_mod
	if ! libmoff_wait_pid "${PREVIOUS_PID}"; then
		echo "PID ${PREVIOUS_PID} is still running after 60 sec." >&2
		echo "Killing previous PID, ${NAME} (${CALLER_PID}) and exiting. BYE." >&2
		kill "${PREVIOUS_PID}"
		kill "${CALLER_PID}"
		sleep 5
		kill -9 "${PREVIOUS_PID}"
		kill -9 "${CALLER_PID}"
		exit 1
	fi
}

# Kickoff

# Check for ebtables bug and define fixing variables if needed.
_set_ebtables_ip6_fixing_vars
# Enable debugging
[ "${MOFF_DEBUG}" = "1" ] && _enable_debug
