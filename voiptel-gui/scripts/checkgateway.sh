#!/bin/bash 

gate=`asterisk -rx "sip show peers" | grep $1 | grep OK` 
gatecheck=`echo -n $gate` 

if [ "$gatecheck" == "" ]; then 
# echo Gateway $1 unreachable 
exit 1 
else 
# echo Gateway $1 reachable 
exit 0 
fi

