#!/bin/ash
# shellcheck shell=dash
#
# Copyright (C) 2017 Tessares SA <http://www.tessares.net>
#
# Unauthorized copying of this file, via any medium, is strictly prohibited.
#
# See the AUTHORS file for a list of contributors.

# This file is a sample of what must be implemented in order to have the backup
# DNS functionality working.

#############
# Variables #
#############

# Used in function moff_dns_set_backup and moff_dns_set_normal
# PID file used by dnsmasq (pid-file configuration or -x argument)
DNS_PID_FILE=${MOFF_DNS_PID_FILE:-"/var/run/dnsmasq/dnsmasq.pid"}
# Resolv file used by dnsmasq (resolv-file configuration or -r argument)
DNS_RESOLV_FILE=${MOFF_DNS_RESOLV_FILE:-$(uci get dhcp.@dnsmasq[-1].resolvfile)}

# These variables should always be provided by moff.sh
: "${BACKUP_DNS_PRIMARY?}"   # Should be set but can be Null
: "${BACKUP_DNS_SECONDARY?}" # Should be set but can be Null
: "${DSL_BR_LAN_IFACE:?}"
: "${ENABLE_IPv4:?}"
: "${ENABLE_IPv6:?}"
: "${LTE_BR_IP:?}"
: "${LTE_BR_IP6:?}"

#############
# FUNCTIONS #
#############

# When the DSL is lost, clients might loose DNS resolution. We need to specify
# a new DNS Server and then reload the DNS Server. This script is designed to
# work properly with dnsmasq. The two following functions must be adapted in
# order to work with any other DNS Server.
moff_dns_set_backup() {
	if [ -n "${BACKUP_DNS_PRIMARY}" ]; then
		echo "nameserver ${BACKUP_DNS_PRIMARY}" > "${DNS_RESOLV_FILE}"
	else
		# If no primary DNS was specified for the backup configuration,
		# we assume that the LTE GW runs a working DNS Server. Thus, in
		# backup mode, we now want to use this DNS resolver.
		true > "${DNS_RESOLV_FILE}"
		if libmoff_is_ipv4_enabled; then
			echo "nameserver ${LTE_BR_IP}" >> "${DNS_RESOLV_FILE}"
		fi
		# LTE_BR_IP6 is a link-local IPv6 address. We must explicitely specify
		# the interface to reach it.
		if libmoff_is_ipv6_enabled; then
			echo "nameserver ${LTE_BR_IP6}%${DSL_BR_LAN_IFACE}" >> "${DNS_RESOLV_FILE}"
		fi
	fi

	if [ -n "${BACKUP_DNS_SECONDARY}" ]; then
		echo "nameserver ${BACKUP_DNS_SECONDARY}" >> "${DNS_RESOLV_FILE}"
	fi

	# Sending SIGHUP to dnsmasq forces it to re-read the resolv
	# file given in the configuration.
	kill -1 "$(cat "${DNS_PID_FILE}")"
}

moff_dns_set_normal() {
	# Sending SIGHUP to dnsmasq forces it to re-read the resolv
	# file given in the configuration. Here, we assume that the
	# resolv-file is overwritten when the DSL is connected. If not,
	# please overwrite the ${DNS_RESOLV_FILE} file with the DNS to
	# use.
	# echo "nameserver X" > ${DNS_RESOLV_FILE}
	kill -1 "$(cat "${DNS_PID_FILE}")"
}
