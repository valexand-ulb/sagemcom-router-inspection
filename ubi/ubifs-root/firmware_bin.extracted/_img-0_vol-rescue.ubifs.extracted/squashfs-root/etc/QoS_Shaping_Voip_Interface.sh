VOIP_MGT_MAX=$(($3 / 1000))
CEIL=$((${VOIP_MGT_MAX} + 20))

VOIP_RATE=400
MGMT_RATE=100
MAX_PORT_VALUE=65535
TR_DEST_PORT=$1
DEV=$2

# Management Filter: tcp traffic over TR_DEST_PORT
MGMT_FILTER="protocol ip u32 match ip protocol 6 0xff match ip dport ${TR_DEST_PORT} 0xffff"
# DHCP Filter: udp traffic over port 67
DHCP_FILTER="protocol ip u32 match ip protocol 17 0xff match ip dport 67 0xffff"
# DNS udp Filter
DNS_UDP_FILTER="protocol ip u32 match ip protocol 17 0xff match ip dport 53 0xffff"
# DNS tcp Filter
DNS_TCP_FILTER="protocol ip u32 match ip protocol 6 0xff match ip dport 53 0xffff"
# NTP udp Filter
NTP_UDP_FILTER="protocol ip u32 match ip protocol 17 0xff match ip dport 123 0xffff"
# NTP tcp Filter
NTP_TCP_FILTER="protocol ip u32 match ip protocol 6 0xff match ip dport 123 0xffff"

check_port() {

#check wether given port is a number
case $TR_69_PORT in
    ''|*[!0-9]*) 
	 #change to https port since default bgc acs url is https:// ...
	TR_69_PORT=443 ;;
esac

#check wether given port is in the allowed range
if  [ $TR_DEST_PORT -gt $MAX_PORT_VALUE ] ; then
   # change to https port since default bgc acs url is https:// ...
	TR_DEST_PORT=443
fi
}


if [ $4 -eq 0 ]; then
  tc qdisc  del dev ${DEV} root
  exit
fi



check_port $TR_DEST_PORT

tc qdisc  del dev ${DEV} root

tc qdisc add dev ${DEV} root handle 1: htb default 10
tc class add dev ${DEV} parent 1: classid 1:1 htb rate ${CEIL}kbit ceil ${CEIL}kbit

tc class add dev ${DEV} parent 1:1 classid 1:2 htb rate ${VOIP_MGT_MAX}kbit ceil ${VOIP_MGT_MAX}kbit prio 1
tc class add dev ${DEV} parent 1:1 classid 1:3 htb rate ${CEIL}kbit ceil ${CEIL}kbit prio 0


tc class add dev ${DEV} parent 1:2 classid 1:10 htb rate ${VOIP_RATE}kbit ceil ${VOIP_MGT_MAX}kbit prio 2
tc class add dev ${DEV} parent 1:2 classid 1:15 htb rate ${MGMT_RATE}kbit ceil ${VOIP_MGT_MAX}kbit prio 3


tc filter add dev ${DEV} parent 1:0 ${MGMT_FILTER} flowid 1:15
tc filter add dev ${DEV} parent 1:0 ${DHCP_FILTER} flowid 1:3
tc filter add dev ${DEV} parent 1:0 ${DNS_UDP_FILTER} flowid 1:3
tc filter add dev ${DEV} parent 1:0 ${DNS_TCP_FILTER} flowid 1:3
tc filter add dev ${DEV} parent 1:0 ${NTP_UDP_FILTER} flowid 1:3
tc filter add dev ${DEV} parent 1:0 ${NTP_TCP_FILTER} flowid 1:3

tc qdisc add dev ${DEV} parent 1:3 handle 300: sfq perturb 10
tc qdisc add dev ${DEV} parent 1:10 handle 100: sfq perturb 10
tc qdisc add dev ${DEV} parent 1:15 handle 150: sfq perturb 10
