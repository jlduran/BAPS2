#!/bin/bash
date="`date`"
x="`echo $date | grep -c 'Mon Jan 1'`"
y="`echo $date | grep -c 2007`"
if [ $x == 1 ] || [ $y == 1 ]
then
/bin/ntpdate -u pool.ntp.org
fi

