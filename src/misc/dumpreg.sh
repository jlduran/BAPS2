#!/bin/sh
#
# dumpreg.sh
# David Rowe 6 march 2009
# Dumps FXO registers using modified wcfxs.ko with /proc/wcfxs interface
#
# usage:
#  dumpreg card[0..3] reg[1..59]

if [ ! -d /proc/wcfxs ] ; then
  echo -n "/proc/wcfxs not found - is correct version of wcfxs installed?"
fi
echo $1 > /proc/wcfxs/card
echo $2 > /proc/wcfxs/regaddr
echo -n "card $1 reg $2 " 
cat /proc/wcfxs/value

