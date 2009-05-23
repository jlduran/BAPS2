; extensions.conf for ADI profiling

[general]
static = yes
writeprotect = no
autofallthrough = yes
clearglobalvars = no
priorityjumping = no

[default]
exten => 2000,1,Dial(SIP/sipguest)
exten => 2001,1,Dial(SIP/wip)
exten => 2008,1,Background(demo-instruct)
exten => 2008,2,Goto(2008,1)
exten => 2010,1,Answer()
exten => 2010,2,Milliwatt()
