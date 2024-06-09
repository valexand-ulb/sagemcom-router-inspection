#!/bin/sh

BRIDGED=$1
INTERFACE=$2
MACADDR=$3

if [ "$BRIDGED" == "1" ] ; then
	echo "bridged mode"
	#The port belongs to BR_WAN
	brctl delif BR_LAN $INTERFACE
	brctl addif BR_WAN $INTERFACE
	ebtables -I INPUT -i $INTERFACE -j DROP
	ebtables -I OUTPUT -o $INTERFACE -j DROP
	#add mac filtering
	ebtables -A FORWARD -i $INTERFACE -s ! $MACADDR -j DROP
	ebtables -A FORWARD -o $INTERFACE -d ! $MACADDR  -j DROP
else 
	echo "routed mode"
	#The port belongs to BR_LAN
	brctl delif BR_WAN $INTERFACE
	brctl addif BR_LAN $INTERFACE
	ebtables -D INPUT -i $INTERFACE -j DROP
	ebtables -D OUTPUT -o $INTERFACE -j DROP
	#delete mac filtering
	ebtables -D FORWARD -i $INTERFACE -s ! $MACADDR -j DROP
	ebtables -D FORWARD -o $INTERFACE -d ! $MACADDR  -j DROP
fi
