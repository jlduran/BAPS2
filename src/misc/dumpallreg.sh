#!/bin/sh
#
# dumpallreg.sh
# David Rowe 6 march 2009
# Dumps all FXO registers from all cards (modules) we want to monitor
#
# usage:
#   dumpallreg numfxocards[1..4]
#
# e.g. if you have 3 FXO cards (modules) in Ports 1, 2 and 3  
#   dumpallreg 3

if [ ! -d /proc/wcfxs ] ; then
  echo -n "/proc/wcfxs not found - is correct version of wcfxs installed?"
fi

card=0

while [ $card -lt $1 ]
do
  ./dumpreg.sh $card  1 # Control 1
  ./dumpreg.sh $card  2 # Control 2
  ./dumpreg.sh $card  5 # DAA Control 1   
  ./dumpreg.sh $card  6 # DAA Control 2
  ./dumpreg.sh $card 10 # DAA Control 3
  ./dumpreg.sh $card 11 # System and Line Side Device Revision
  ./dumpreg.sh $card 12 # Line Side Status
  ./dumpreg.sh $card 13 # Line Side Device Revision
  ./dumpreg.sh $card 16 # International Control 1
  ./dumpreg.sh $card 17 # International Control 2
  ./dumpreg.sh $card 18 # International Control 3
  ./dumpreg.sh $card 19 # International Control 4
  ./dumpreg.sh $card 22 # Ring Validation Control 1
  ./dumpreg.sh $card 23 # Ring Validation Control 2
  ./dumpreg.sh $card 24 # Ring Validation Control 3
  ./dumpreg.sh $card 28 # Loop current status
  ./dumpreg.sh $card 29 # Line voltage status

  card=`expr $card + 1`
done

