README.txt for ucasterisk
Created David Rowe 16/10/07

Experimental build system for Blackfin Asterisk.  Key differences compared
to buildroot based systems:

1/ Flatter directory structure to ease development, e.g. you can
   compile just Asterisk without building a uImage.  Faster and less
   output to wade through.  Makefiles (e.g. asterisk.mk) and source
   (e.g. asterisk-1.4.4) are within one directory level of each other.
   Less chance of breaking build system due to decoupling of modules
   (kernel, root fs, asre seperate from Asterisk).

2/ Use of packages (via ipkg) to install applications like Asterisk,
   rather than placing everything in a uImage.  Target is initially
   booted with a basic kernel and root file system, then packages are
   installed required.  Assumes availablility of persistant (non ram)
   based file system like yaffs or jffs2.  Goal is to make installing 
   software on target more like an x86 than an embedded system.

STATUS
------

This version just builds Asterisk and an Asterisk ipkg.  Assumes
uClinux-dist is built elsewhere, and that toolchain is installed and
in our path.

We need a native ipkg that runs on the Blackfin.

INSTALLATION
------------

1/ We assumes a Blackfin toolchain is in your path.

2/ Set the environment variable UCLINUX_DIST in Makefile to point
   to your uClinux-dist tree.

HOWTO
-----

1/ Build Asterisk:

[david@bunny ucasterisk]$ make -f asterisk.mk asterisk

2/ Build Asterisk ipkg:

[david@bunny ucasterisk]$ make -f asterisk.mk asterisk-package

NOTES
-----

1/ Patch files are compatable with Astfin, so hopefully it's possible
to move patches back and forth.

Directories
-----------

ipkg    - working directory for building packages

include - from OpenWRT kamikaze, contains useful stuff for building
          packages.

sctipts - Useful scripts from OpenWRT kamikaze
