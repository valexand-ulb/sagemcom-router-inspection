#!/bin/sh

ReasonOfLastBoot ()
{
#        echo "# Current boot was caused by Server Down" > /etc/ReasonOfLastBoot.txt
        touch /opt/conf/watchdog_reboot
}

forced_reboot ()
{
	if [ $param == "prod" ]
	then
		sleep 1 && reboot
	fi
}

save_log ()
{
	echo "forced reboot launched" >/opt/filesystem1/forced_reboot.log
	echo " ====================== uptime =======================" >>/opt/filesystem1/forced_reboot.log
	uptime >>/opt/filesystem1/forced_reboot.log
	echo " ====================== ls -l /tmp/ =======================" >>/opt/filesystem1/forced_reboot.log
	ls -l /tmp/ >>/opt/filesystem1/forced_reboot.log
	echo " ====================== show.sh =======================" >>/opt/filesystem1/forced_reboot.log
	show.sh >>/opt/filesystem1/forced_reboot.log
	echo " ====================== cat /proc/modules =======================" >>/opt/filesystem1/forced_reboot.log
	cat /proc/modules >>/opt/filesystem1/forced_reboot.log
	echo " ====================== ps =======================" >>/opt/filesystem1/forced_reboot.log
	ps >>/opt/filesystem1/forced_reboot.log
	echo " ====================== top -b -n1  =======================" >>/opt/filesystem1/forced_reboot.log
	top -b -n1 >>/opt/filesystem1/forced_reboot.log
	echo " ====================== ifconfig =======================" >>/opt/filesystem1/forced_reboot.log
	ifconfig >>/opt/filesystem1/forced_reboot.log
	echo " ====================== cat /proc/meminfo  =======================" >>/opt/filesystem1/forced_reboot.log
	cat /proc/meminfo >>/opt/filesystem1/forced_reboot.log >>/opt/filesystem1/forced_reboot.log 
	echo "================== cat /proc/slabinfo ======================" >>/opt/filesystem1/forced_reboot.log
	cat /proc/slabinfo >>/opt/filesystem1/forced_reboot.log
	echo " ====================== brctl show  =======================" >>/opt/filesystem1/forced_reboot.log
	brctl show >>/opt/filesystem1/forced_reboot.log 
	echo " ====================== route -n  =======================" >>/opt/filesystem1/forced_reboot.log
	route -n >>/opt/filesystem1/forced_reboot.log >>/opt/filesystem1/forced_reboot.log
	echo " ====================== logread  =======================" >>/opt/filesystem1/forced_reboot.log
	cat /var/log/messages  >>/opt/filesystem1/forced_reboot.log
	sync
}

param=$1

ReasonOfLastBoot
save_log
forced_reboot
