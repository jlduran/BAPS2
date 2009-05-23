#!/bin/sh  
# test_mmc.sh
#
# Writes a file 10 times to MMC and checks it

tests=0
bad=0

while [ $tests -lt 10 ]
do
    # bring up MMC card and copy a file
    
    modprobe spi_mmc
    if mount /dev/mmc /mnt
    then
        cp /bin/busybox /mnt/busybox
        umount /mnt
    fi
    rmmod spi_mmc

    # now see if file is OK

    modprobe spi_mmc 
    mount /dev/mmc /mnt
    ls /mnt/ -l
    mount | grep mmc
    if diff /bin/busybox /mnt/busybox > /dev/null 
    then
        echo
    else
        bad=`expr $bad + 1`
    fi
    umount /mnt
    rmmod spi_mmc

    # delete file

    modprobe spi_mmc
    if mount /dev/mmc /mnt
    then
        rm -f /mnt/busybox
        umount /mnt
    fi
    rmmod spi_mmc

    tests=`expr $tests + 1`
    echo "tests: $tests  bad: $bad"
done
