#!/bin/sh

TABLE=$3
if [ "$4" == "-A" ]; then
        COMMAND="add"
else
        COMMAND="remove"
fi
shift 4
firewall-cli -6 $COMMAND iptables -t $TABLE -- "-A ${*}"
