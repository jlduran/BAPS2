#!/usr/local/bin/expect  -f
# flash_target.tcl
# David Rowe 1 Dec 2007
#
# Given an IP04/IP08 target with u-boot installed, installs uClinux and
# baseline Asterisk using babs ipkg system.
#
# Assumes:
#
# 1) /etc/minirc/.dfl on RS232 machine has 115200 as default baud
# rate.
#
# 2) The following u-boot env vars have been set:
#
#    set con console=ttyBF0,115200
#    set eth0 your:mac:address:for:eth0
#    set eth1 your:mac:address:for:eth1
#    set root /dev/mtdblock0 rw
#    set addba 'set bootargs $(con) ethaddr=$(eth0) ethaddr1=$(eth1) root=$(root)'
#

# -------------------- you will need to change these......

# machine with RS232 connection to target
set rs232 dragonballz         
# IP of tftp server holding uImage.ip08
set tftpserver 192.168.1.2    
# name of uImage
set uImage uImage.ip08        
# target IP
set target_ip 192.168.1.30

# TODO - write expect code to overwite the above defauts from cmd line

# -------------------- end changes

set send_slow {1 0.2}
set timeout -1

# connect to machine with RS232 port

spawn ssh $rs232
expect "$ "
send "killall -9 minicom\r"
expect "$ "
send "minicom\r"
expect "on special keys"

# get u-boot prompt

expect "Hit any key to stop autoboot"

send "\r"
expect "ip04>"

# flash new kernel

send -s "set autostart\r"
expect "ip04>"
send -s "set serverip $tftpserver\r"
expect "ip04>"
send -s "tftp 0x1000000 $uImage\r"
expect "ip04>"
send -s "nand erase clean\r"
expect "ip04>"
send -s "nand erase\r"
expect "ip04>"
# possible bug source - we assume below uImage will be no larger than 0x4c0000
send -s "nand write 0x1000000 0x0 0x4c0000\r" 
expect "ip04>"

# set bootargs for /dev/mtdblock0

send -s "set root /dev/mtdblock0 rw\r"
expect "ip04>"
send -s "run addba\r"
expect "ip04>"

# save and reboot into uClinux

send -s "set autostart yes\r"
expect "ip04>"
send -s "save\r"
expect "ip04>"
send -s "reset\r"
expect "root:~> "

# set up yaffs, reboot back into u-boot

send -s "copy_rootfs.sh\r"
expect "root:~> "
send -s "reboot\r"

# set yaffs as root fs, reboot into uClinux

expect "Hit any key to stop autoboot"
send "\r"
expect "ip04>"
send -s "set root /dev/mtdblock2 rw\r"
expect "ip04>"
send -s "run addba\r"
expect "ip04>"
send -s "save\r"
expect "ip04>"
send -s "reset\r"
expect "root:~> "

# set IP to something host can find

send -s "ifconfig eth0 $target_ip\r"
expect "root:~> "
close

# install asterisk on target

spawn bash
expect "$ "
send "scripts/flash_asterisk.tcl\r"
expect "$ "
close
