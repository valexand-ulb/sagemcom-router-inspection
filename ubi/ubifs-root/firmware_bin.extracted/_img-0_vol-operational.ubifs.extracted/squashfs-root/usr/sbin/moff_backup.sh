#!/bin/ash
# shellcheck shell=dash
#
# Copyright (C) 2017 Tessares SA <http://www.tessares.net>
#
# Unauthorized copying of this file, via any medium, is strictly prohibited.
#
# See the AUTHORS file for a list of contributors.

[ ${#} -lt 1 ] && echo "[moff_backup] Usage: ${0} EVENT" >&2 && exit 1
EVENT="${1}"

#############
# Variables #
#############
# Can be set via environement variables in order to overwrite the default ones
# Location of the library file libmoff.sh
MOFF_LIBRARY_FILE=${MOFF_LIBRARY_FILE:-"$(dirname "$0")/../lib/moff/libmoff.sh"}
# Location of the script file backup.sh
MOFF_BACKUP_DNS_FILE=${MOFF_BACKUP_DNS_FILE:-"/usr/sbin/moff_backup_dns.sh"}
# Location of the temporary file where we store rules to applied in order to
# cleanup the installed ones for the backup mode.
MOFF_CLEANUP_FILE=${MOFF_CLEANUP_BACKUP_FILE:-"/tmp/moff_backup_cleanup_file"}

###################
# Given Variables #
###################
# These variables should always be provided by moff.sh
: "${BACKUP_DNS_ENABLED:?}"
: "${DSL_BR_LAN_IFACE:?}"
: "${DSL_BR_MAC:?}"
: "${EBTABLES:?}"
: "${ENABLE_IPv4:?}"
: "${ENABLE_IPv6:?}"
: "${IPTABLES_FLAGS:?}"
: "${LTE_BR_MAC:?}"
: "${MOFF_DEBUG:?}"

if [ "${ENABLE_IPv4}" = "1" ]; then
	: "${DSL_BR_PREFIX:?}"
	: "${IPTABLES:?}"
	: "${LTE_BR_IP:?}"
fi

if [ "${ENABLE_IPv6}" = "1" ]; then
	: "${DSL_BR_LARGE_SUBNET6:?}"
	: "${IP6TABLES:?}"
	: "${LTE_BR_IP6:?}"
fi

#############
# FUNCTIONS #
#############

# Import MOff Library functions
if [ ! -f "${MOFF_LIBRARY_FILE}" ]; then
	echo "ERROR: Moff Library file cannot be found at ${MOFF_LIBRARY_FILE}," >&2
	echo "please change the MOFF_LIBRARY_FILE variable in ${0}, exiting" >&2
	exit 1
else
	# shellcheck source=libmoff.sh
	. "${MOFF_LIBRARY_FILE}"
fi

# Import functions
if [ ! -f "${MOFF_BACKUP_DNS_FILE}" ]; then
	echo "ERROR: Moff Backup DNS file cannot be found at ${MOFF_BACKUP_DNS_FILE}," >&2
	echo "please change the MOFF_BACKUP_DNS_FILE variable in ${0}, exiting" >&2
	exit 1
else
	# source backup DNS script which defines new functions.
	# shellcheck source=moff_backup_dns.sh
	. "${MOFF_BACKUP_DNS_FILE}"
fi

redirect_v4_to_mproxy() {
	libmoff_is_ipv4_enabled || return 0
	libmoff_redirect_v4_to_device "${DSL_BR_MAC}" "${LTE_BR_MAC}" "${DSL_BR_LAN_IFACE}" "${DSL_BR_PREFIX}"
}

redirect_v6_to_mproxy() {
	libmoff_is_ipv6_enabled || return 0
	libmoff_redirect_v6_to_device "${DSL_BR_MAC}" "${LTE_BR_MAC}" "${DSL_BR_LAN_IFACE}" "${DSL_BR_LARGE_SUBNET6}" "${@}"
}

# Set up backup redirection (full redirection)
moff_set_lte_backup() {
	redirect_v4_to_mproxy
	# We should never redirect IPv6 NDP nor MLD which are supposed to be link-local
	redirect_v6_to_mproxy "! ${IP_PROTO_ICMP6}"
	redirect_v6_to_mproxy "${IP_PROTO_ICMP6} --ip6-icmp-type ! ${ICMP6_NDP_MLD_RANGE}"
}

#######
# RUN #
#######

[ "${MOFF_DEBUG}" = "1" ] && echo "[moff_backup] Received event: ${EVENT}"

# Different case depending of the event
case ${EVENT} in
	"ON")
		# Install the backup rules
		moff_set_lte_backup

		# If the upstream DNS server of the GW have to be changed,
		# perform needed operations
		[ "${BACKUP_DNS_ENABLED}" = "1" ] && moff_dns_set_backup

		;;
	"OFF")
		# Remove backup redirection
		libmoff_cleanup_rules_silent

		[ "${BACKUP_DNS_ENABLED}" = "1" ] && moff_dns_set_normal

		;;
	*)
		echo "[moff_backup] Event ${EVENT} is not supported" >&2 && exit 1
		;;
esac

[ "${MOFF_DEBUG}" = "1" ] && echo "[moff_backup] End of actions for event: ${EVENT}"
exit 0
