#!/bin/sh
# script for enabling/disabling ssh on qtn

do_start_ssh_on_qtn()
{
	#generate rsa priv + pub key and put the public on the tftp server 
	echo "-----------Generating SSH Auth Keys-----------"
	mkdir -p /tmp/.ssh/
	if [ -f /tmp/.ssh/ssh_rsa_priv_key ] || [ -f /tmp/.ssh/ssh_rsa_pub_key ]; then
		rm /tmp/.ssh/ssh_rsa*
	fi
	dropbearkey -t rsa -f /tmp/.ssh/ssh_rsa_priv_key | grep  "ssh-rsa " > /tmp/.ssh/ssh_rsa_pub_key
	cp /tmp/.ssh/ssh_rsa_pub_key /etc/tftp/ssh_rsa_pub_key
	chmod 644 /etc/tftp/ssh_rsa_pub_key

	#add firewall rules for tftp server and start tftpd-hpa server
	echo "-----------Starting tftp server-----------"
	firewall-cli add iptables -t filter -- "-A INPUT -s 10.1.1.2/32 -d 10.1.1.1/32 -i eth4.12 -p udp -m udp --dport 69 -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT"
	tftpd-hpa -B 1464 -l -s /etc/tftp

	#Send RPC so that qtn will download the new rsa authorozed key
	echo "-----------Requesting public key download-----------"
	ret_RPC_key_upload=`quantenna_test 10.1.1.2 run_script remote_command add_dropbear_authorizedkey ssh_rsa_pub_key | grep -ci 'Error'` 

	#remove firewall rules for tftp server and stop tftpd-hpa server
	echo "-----------Stopping tftp server-----------"
	firewall-cli remove iptables -t filter -- "-A INPUT -s 10.1.1.2/32 -d 10.1.1.1/32 -i eth4.12 -p udp -m udp --dport 69 -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT"
	rm /etc/tftp/ssh_rsa_pub_key
	killall tftpd-hpa

	if [ $ret_RPC_key_upload -gt 0 ]; then
		echo "Error : ssh_rsa_pub_key upload failed"
		echo "-----------remove generated rsa_keys-----------"
		rm /tmp/.ssh/*
		exit 1
	fi

	echo "-----------Starting ssh server-----------"
	#send RPC so that qtn will start the ssh server
	quantenna_test 10.1.1.2 run_script remote_command dropbear start

	#add firewall rules to authorize SSH traffic
	firewall-cli add iptables -t filter -- "-A INPUT -s 10.1.1.2/32 -d 10.1.1.1/32 -p tcp -m tcp --sport 22 -m state --state ESTABLISHED,RELATED -j ACCEPT"
	firewall-cli add iptables -t filter -- "-A OUTPUT -s 10.1.1.1/32 -d 10.1.1.2/32 -p tcp -m tcp --dport 22 -j ACCEPT"

	#start SSH session
	echo "-----------starting ssh session-----------"
	echo "please do not forget to run the cmd '/etc/qtn_ssh.sh stop' after closing the ssh session"
	ssh -i /tmp/.ssh/ssh_rsa_priv_key  10.1.1.2

}

do_stop_ssh_on_qtn()
{
	#remove generated rsa_keys
	echo "-----------remove generated rsa_keys-----------"
	rm /tmp/.ssh/*

	#Send RPC so that qtn will remove the rsa authorozed key
	echo "-----------Requesting public key remove from this client-----------"
	quantenna_test 10.1.1.2 run_script remote_command remove_dropbear_authorizedkey ssh_rsa_pub_key

	#send RPC so that qtn will stop the ssh server
	echo "-----------Stopping ssh server-----------"
	quantenna_test 10.1.1.2 run_script remote_command dropbear stop

	#remove firewall rules added for SSH traffic
	firewall-cli remove iptables -t filter -- "-A INPUT -s 10.1.1.2/32 -d 10.1.1.1/32 -p tcp -m tcp --sport 22 -m state --state ESTABLISHED,RELATED -j ACCEPT"
	firewall-cli remove iptables -t filter -- "-A OUTPUT -s 10.1.1.1/32 -d 10.1.1.2/32 -p tcp -m tcp --dport 22 -j ACCEPT"
}

if [ $# -ne 1 ]; then
	echo "Usage : qtn_ssh <start/stop>"
	exit 0
fi

case "$1" in
	start)
		do_start_ssh_on_qtn
		;;
	stop)
		do_stop_ssh_on_qtn
		;;
	*):
		echo "Usage : qtn_ssh <start/stop>"
		exit 1
esac


