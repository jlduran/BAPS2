#!/bin/sh 

exec_option=$1

if [ $exec_option == start ]
then
	export TZ=`cat /etc/TZ`
	export MMC=`cat /etc/MMC`
	if [ $MMC == 1 ]
	then
		echo "[directories]" > /etc/asterisk/asterisk.conf
		echo "astlogdir => /mnt/mmc" >> /etc/asterisk/asterisk.conf
		if [ ! -d /mnt/mmc/cdr-custom ]
		then
			mkdir /mnt/mmc/cdr-custom
		fi
		echo "CDR is enabled"
	elif [ $MMC == 0 ]
	then
		echo "" > /etc/asterisk/asterisk.conf
		echo "CDR is disabled"
	fi
	asterisk -f >/dev/null 2>/dev/null &
elif [ $exec_option == stop ]
then
	killall -9 asterisk
fi

