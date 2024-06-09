#!/bin/sh
# Copyright (C) 2011 Sagemcom

BUT_RESET=`cat /proc/sys/sagem/gpio/maps |grep "But reset"`

if [ "x$BUT_RESET" != "x" ]; then

	POLARITY=`echo $BUT_RESET |cut -d'|' -f 7`
	BUT_STATE=`echo $BUT_RESET |cut -d'|' -f 14`
	
	echo "POLARITY = $POLARITY"
	echo "BUT_STATE = $BUT_STATE"
	
	if [ $POLARITY = "Low" -a $BUT_STATE = 0 ]; then
		exit 1
	fi
	
	if [ $POLARITY = "High" -a $BUT_STATE = 1 ]; then 
		exit 1
	fi

fi
