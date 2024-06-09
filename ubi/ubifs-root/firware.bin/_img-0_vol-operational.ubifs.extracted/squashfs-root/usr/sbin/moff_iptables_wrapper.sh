#!/bin/sh

TABLE=$3
if [ "$4" == "-A" ]; then
        COMMAND="add"
else
        COMMAND="remove"
fi
shift 4
firewall-cli $COMMAND iptables -t $TABLE -- "-A ${*}"
