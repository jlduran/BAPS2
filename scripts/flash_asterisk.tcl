#!/usr/local/bin/expect  -f
# flash_asterisk.tcl
# David Rowe 1 Dec 2007
#
# Given an IP04/IP08 target with uClinux, installs 
# baseline Asterisk using babs ipkg system.
#

# -------------------- you will need to change these......

# target IP
set target_ip 192.168.1.30

# -------------------- end changes

set timeout -1

# rcp ipkgs from host to target

spawn bash
expect "$ "
send "rcp ipkg/oslec*.ipk ipkg/zaptel-sport*.ipk root@$target_ip:/root\r"
expect "$ "
send "rcp ipkg/asterisk*.ipk root@$target_ip:/root\r"
expect "$ "
close

# install them using ipkg

spawn telnet $target_ip
expect "~> "
send "cd /root\r"
expect "> "
send "ipkg install oslec*\r"
expect "> "
send "ipkg install zaptel-sport*\r"
expect "> "
send "ipkg install asterisk*\r"
expect "> "
send "reboot\r"
close
