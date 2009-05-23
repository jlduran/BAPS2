#!/usr/local/bin/expect -f

# thrash_agi.tcl - Expect script to maki Blackfin call PHP AGI
# may times.  Designed to flush out any memory leak problems

set file [lindex $argv 0]
set path  [lindex $argv 1]
set timeout 5

spawn bash
send "telnet atcom\r"
expect "root:~> "
send "asterisk -r\r"
expect "CLI> "
send "set verbose 5\r"
expect "CLI> "
for {set i 0} {$i < 10000} {incr i} {
    send "originate IAX2/guest@localhost/1235 extension 1234@from-internal-custom\r"
    expect "Returned from dialparties "
    puts "ITERATION $i ---------------------------";
}
send "exit\r"
expect "root:~> "
