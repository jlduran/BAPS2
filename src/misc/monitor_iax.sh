#!/bin/sh 
# monitor_iax.sh
# David Rowe 28 April 2008 
# Adapted from script found on http://www.voip-info.org/wiki-IAX
#
# It was found that IAX
# trunks we losing registration ever day or so as the ppp link IP
# changed.  The NAT router (Linux 2.2 box in my case) was mistakenly
# sending IAX messages with the previous PPP IP, as it was
# relying on some sort of internal hash table.  Stopping IAX messages
# for 10 minutes resets the NAT router.


cd /usr/bin 
PATH=/sbin:/bin:/usr/sbin:/usr/bin

while [ 1 ]
do
  /sbin/asterisk -rx 'iax2 show registry' > reg_status
  sleep 1

  # We then Scan the Status and see if we're online or not...

  TEST="Registered"
  if grep $TEST reg_status > /dev/null
  then
    sleep 60  # all is well...
  else
  
    #IF we're this far down, we've lost IAX. Log the incident.
  
    date >> slap.log
   
    #Restart the IAX2 trunk. Delay required for some reason.
  
    # comment from Olivier Adler : restarting the IAX2 channel is not possible i
    # if there are calls on it. It's better to restart asterisk.
    # be carefull : restarting IAX2 channel or asterisk solve the 
    # masquerading problem, but does not clean the kernel tainting.
  
    /sbin/asterisk -rx 'unload chan_iax2.so' > /dev/null
    sleep 600 # adjust by experiment for NAT to reset
    /sbin/asterisk -rx 'load chan_iax2.so' > /dev/null 
    sleep 10  # give IAX time to reload before we test again
  fi
done
  stered" 
