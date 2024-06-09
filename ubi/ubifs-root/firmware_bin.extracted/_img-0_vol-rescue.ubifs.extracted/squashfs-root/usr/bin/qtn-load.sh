#!/bin/sh

CONF="/etc/init.d/qtn-params"
FLAG="/tmp/qtn-preload-started"
ACTION=$1

# Help for this command
Usage ()
{
# arg  :
echo "        -start     : Start qtn preload sequence"
echo "        -stop      : Stop qtn preload sequence"
echo "        -check     : Check qtn preload startup"
echo "        -h         : help"
echo " if no arg, the script exits"
}

check_preload()
{
	local result=1
	if [ ! -f $FLAG ]; then
		result=0
	fi
	echo $result
}

start_preload() 
{
	if [ ! -f $FLAG -a -f $CONF ]; then
	. $CONF
	if [ -f /bin/check_qtn ] ;then
	MODE=`/bin/check_qtn`
	fi
	if [ -n "$MODE" -a "$MODE" != "none" ] ;then
	echo "Starting Quantenna FW PreLoading: " > /dev/console
	if [ -n "$QTN_MAC" ]; then 
		/sbin/ifconfig $BOOT_ITF hw ether $QTN_MAC
	fi
	/sbin/ifconfig $BOOT_ITF up
	/sbin/ifconfig $BOOT_ITF:qtn $IP_BOOT_LOCAL
	/sbin/vconfig add $BOOT_ITF $MNGT_VLAN
	/sbin/ifconfig $MNGT_ITF up	
	/sbin/ifconfig $MNGT_ITF $IP_MNGT_LOCAL netmask $IP_MNGT_NETMASK
	ebtables -t broute -A BROUTING -p 802_1Q -i $BOOT_ITF --vlan-id $MNGT_VLAN -j DROP
	firewall-cli add iptables -t filter -- "-A INPUT -i $BOOT_ITF -s $IP_BOOT_REMOTE -d $IP_BOOT_LOCAL -p udp --dport 69 -m state --state NEW -j ACCEPT"
	firewall-cli add iptables -t filter -- "-A INPUT -i $BOOT_ITF -s $IP_BOOT_REMOTE -d $IP_BOOT_LOCAL -p udp -m state --state ESTABLISHED -j ACCEPT"
	firewall-cli add iptables -t filter -- "-A OUTPUT -o $BOOT_ITF -d $IP_BOOT_REMOTE -s $IP_BOOT_LOCAL -p udp -m state --state ESTABLISHED,RELATED -j ACCEPT"
	firewall-cli add iptables -t filter -- "-A OUTPUT -o $MNGT_ITF -s $IP_MNGT_LOCAL -d $IP_MNGT_REMOTE -p udp -j ACCEPT"        
	firewall-cli add iptables -t filter -- "-A INPUT -i $MNGT_ITF -d $IP_MNGT_LOCAL -s $IP_MNGT_REMOTE -p udp -m state --state ESTABLISHED,RELATED -j ACCEPT"
	if printf "$MODE" | grep -qF "11ac"; then
	firewall-cli add iptables -t filter -- "-A OUTPUT -o $BOOT_ITF -s $IP_BOOT_LOCAL -d $IP_BOOT_REMOTE -p udp -j ACCEPT"
	firewall-cli add iptables -t filter -- "-A INPUT -i $BOOT_ITF -d $IP_BOOT_LOCAL -s $IP_BOOT_REMOTE -p udp -m state --state ESTABLISHED,RELATED -j ACCEPT"
	firewall-cli add iptables -t filter -- "-A OUTPUT -o $BOOT_ITF -s $IP_BOOT_LOCAL -d $IP_BOOT_REMOTE -p tcp -j ACCEPT"
	firewall-cli add iptables -t filter -- "-A INPUT -i $BOOT_ITF -d $IP_BOOT_LOCAL -s $IP_BOOT_REMOTE -p tcp -m state --state ESTABLISHED,RELATED -j ACCEPT"
	firewall-cli add iptables -t filter -- "-A OUTPUT -o $MNGT_ITF -s $IP_MNGT_LOCAL -d $IP_MNGT_REMOTE -p tcp -j ACCEPT"
	firewall-cli add iptables -t filter -- "-A INPUT -i $MNGT_ITF -d $IP_MNGT_LOCAL -s $IP_MNGT_REMOTE -p tcp -m state --state ESTABLISHED,RELATED -j ACCEPT"
	fi
	tftpd-hpa -B 1464 -l -s /etc/tftp
	touch $FLAG
	echo "OK"
	fi
	fi
}

stop_preload() 
{
	if [ -f $CONF ]; then
	. $CONF
	if [ -f /bin/check_qtn ] ;then
	MODE=`/bin/check_qtn`
	fi
	if [ -n "$MODE" -a "$MODE" != "none" ] ;then
	echo "Stopping Quantenna FW PreLoading: " > /dev/console
	firewall-cli remove iptables -t filter -- "-A INPUT -i $BOOT_ITF -s $IP_BOOT_REMOTE -d $IP_BOOT_LOCAL -p udp --dport 69 -m state --state NEW -j ACCEPT"
	firewall-cli remove iptables -t filter -- "-A INPUT -i $BOOT_ITF -s $IP_BOOT_REMOTE -d $IP_BOOT_LOCAL -p udp -m state --state ESTABLISHED -j ACCEPT"
	firewall-cli remove iptables -t filter -- "-A OUTPUT -o $BOOT_ITF -d $IP_BOOT_REMOTE -s $IP_BOOT_LOCAL -p udp -m state --state ESTABLISHED,RELATED -j ACCEPT"
	if printf "$MODE" | grep -qF "11ac"; then
	firewall-cli remove iptables -t filter -- "-A OUTPUT -o $BOOT_ITF -s $IP_BOOT_LOCAL -d $IP_BOOT_REMOTE -p tcp -j ACCEPT"
	firewall-cli remove iptables -t filter -- "-A INPUT -i $BOOT_ITF -d $IP_BOOT_LOCAL -s $IP_BOOT_REMOTE -p tcp -m state --state ESTABLISHED,RELATED -j ACCEPT"
	firewall-cli remove iptables -t filter -- "-A OUTPUT -o $BOOT_ITF -s $IP_BOOT_LOCAL -d $IP_BOOT_REMOTE -p udp -j ACCEPT"
	firewall-cli remove iptables -t filter -- "-A INPUT -i $BOOT_ITF -d $IP_BOOT_LOCAL -s $IP_BOOT_REMOTE -p udp -m state --state ESTABLISHED,RELATED -j ACCEPT"
	fi
	killall tftpd-hpa
	/sbin/ifconfig $BOOT_ITF:qtn down
	rm $FLAG
	echo "OK"
	fi
	fi
}

if [ "$ACTION" = "-h" ]
then
	Usage
	exit 1
fi

case "$ACTION" in
	"-start")
	start_preload
	;;

	"-stop")
	stop_preload
	;;

	"-check")
	if [ $(check_preload) -eq 0 ]; then
		exit 1
	fi
	;;

	*)
	Usage
	exit 1
	;;

esac
exit 0


