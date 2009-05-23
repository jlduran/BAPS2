AGI PHP Test
David Rowe 10 March 2008

The FreePBX guys suggested that previous people had experienced memory
fragmentation problems running the AGIs that are used for dialling in
FreePBX.

So I devised the following test.  It ran OK (10,000 calls) when tested
on an IP04.  Below is a copy of a FreePBX development forum post:

http://freepbx.org/forum/freepbx/development/retrieve-conf-as-a-function


To test FreePBX PHP AGIs like dialparties.agi on the Blackfin IP04 I
set up this test:

extensions_custom.conf:

[from-internal-custom]

exten => 1234,1,Answer
exten => 1234,2,NoOp(About to call dial x)
exten => 1234,3,Macro(dial,1,'',1235)
exten => 1234,4,NoOp(After calling dial)

exten => 1235,1,Answer
exten => 1235,2,Wait(10)
exten => 1235,3,Hangup

iax.conf:

[guest]
type=user
context=from-internal-custom
callerid="Guest IAX User"

Then I wrote an expect script to login to the Blackfin target (an IP04
with * 1.4.4) and execute this line many times at the * CLI:

CLI> originate IAX2/guest@localhost/1235 extension 1234@from-internal-custom

which makes a call between 1234 & 1235, executing dialplan.agi for
each call. I have now made around 10,000 calls on the Blackfin target
with no serious memory problems. Thats a lot of calls for our typical
4 port PBX.

I did notice that after a few 1000 calls Asterisk's memory consumption
had increased by approx 1 MB, not sure why. Could be some tables/logs
that are growing, or maybe CDR etc.

I think the problem the Xorcom guys may have been having is not so
much fragmentation as file buffering. You see by default uClinux on
the Blackfin can use up to 100% of its memory to buffer files. However
you can throttle this with something like:

echo 10 > /proc/sys/vm/pagecache_ratio

which sets asaide a maximum of 10% of system memory for file
buffers. If you leave this at the default 100% after many files are
accessed the system memory can be consumed to a point where large apps
like PHP can't load.

Anyway - looks like a good result for running AGIs. Its still sucks
that PHP uses up to 9M each time it runs - uClinux is inefficient in
it's memory usage and we dont have much memory (just 64M) compared to
a x86. So time to look at retrieve_conf again........

