#!/bin/sh

#
# Examples
#
# get_sta.sh rssi [MAC_ADDRESS]
# get_sta.sh uplink [MAC_ADDRESS]
# get_sta.sh downlink [MAC_ADDRESS]
#

cmd=$1
mac=$2

[ ! -n "$cmd" -o  ! -n "$mac" ] && {
	echo 0
	exit
}

get_rssi()
{
    result=`wl -i $1 sta_info $2 2>/dev/null | grep "smoothed rssi" | cut -d' ' -f3`
    [ "$result" != "" ] && {
        echo $result
        exit
    }
}

[ "$cmd" = "rssi" ] && {
    get_rssi wl0 $mac
    get_rssi wl1 $mac
	echo -199
	exit
}

get_uplink()
{
    result=`wl -i $1 sta_info $2 2>/dev/null | grep "rate of last tx pkt" | cut -d' ' -f7`
    [ "$result" != "" ] && {
        echo $result
        exit
    }
}

[ "$cmd" = "uplink" ] && {
    get_uplink wl0 $mac
    get_uplink wl1 $mac
	echo 1001
	exit
}


get_downlink()
{
    result=`wl -i $1 sta_info $2 2>/dev/null | grep "rate of last rx pkt" | cut -d' ' -f7`
    [ "$result" != "" ] && {
        echo $result
        exit
    }
}

[ "$cmd" = "downlink" ] && {
    get_downlink wl0 $mac
    get_downlink wl1 $mac
	echo 1001
	exit
}

get_operatingstandard()
{
    flags=`wl -i $1 sta_info $2 2>/dev/null | grep "flags"`

    if [ "$flags" != "" ]; then

        has_cap=`echo "$flags" | grep "HE_CAP"`
        if [ "$has_cap" != "" ]; then
            echo "ax"
            exit
        fi

        has_cap=`echo "$flags" | grep "VHT_CAP"`
        if [ "$has_cap" != "" ]; then
            echo "ac"
            exit
        fi

        has_cap=`echo "$flags" | grep "N_CAP"`
        if [ "$has_cap" != "" ]; then
            echo "n"
            exit
        fi
    fi
}

[ "$cmd" = "operatingstandard" ] && {
    get_operatingstandard wl0 $mac
    get_operatingstandard wl1 $mac
    echo "g"
    exit
}
