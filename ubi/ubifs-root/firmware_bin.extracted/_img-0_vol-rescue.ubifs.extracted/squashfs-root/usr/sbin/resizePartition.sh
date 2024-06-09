#!/bin/sh

RESCUE="rescue"

UBI=$(grep . /sys/class/ubi/*/name | grep $RESCUE)

PARTITION_NUM=${UBI:20:1}
PARTITION_NAME=${UBI:27:6}

if [ "$PARTITION_NAME" = $RESCUE ]; then
		ubirsvol /dev/ubi0 -n $PARTITION_NUM $PARTITION_NAME -s 46000000
fi
