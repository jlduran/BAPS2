#!/bin/sh 

exec_option=$1

if [ -f /etc/asterisk/rc.conf ]
then
	. /etc/asterisk/rc.conf
	if [ $exec_option == start ]
	then
		echo $HOSTNAME > /etc/HOSTNAME
		hostname -F /etc/HOSTNAME
		echo "127.0.0.1  $DOMAIN  localhost" > /etc/hosts
		echo "127.0.0.1  $HOSTNAME" >> /etc/hosts
		if [ "$DHCPD" == yes ]
		then
			rm -f /var/run/dhcpcd*
			dhcpcd &
		else
			ifconfig $IF $IPADDRESS up
			route add default gw $GATEWAY
			if [ ! -f /etc/resolv.conf ]
			then
				touch /etc/resolv.conf
			fi
			echo "nameserver  $DNS" > /etc/resolv.conf
		fi
		sleep 5
		if [ "$LOADZONE" ]
		then
			echo "loadzone=$LOADZONE" > /etc/zaptel.conf
			echo "defaultzone=$DEFAULTZONE" >> /etc/zaptel.conf
		else
			echo "loadzone=us" > /etc/zaptel.conf
			echo "defaultzone=us" >> /etc/zaptel.conf
		fi
	elif [ $exec_option == stop ]
	then
		killall -9 dhcpcd
		rm -f /var/run/dhcpcd*
		ifconfig $IF down
	fi
fi

