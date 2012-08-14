# Blackfin Asterisk Package System (BAPs)

## Introduction

Package-based Build System for Blackfin Asterisk. Key differences compared to buildroot based systems like Astfin and uCasterisk:

* End users do not need to compile any software, they just install them on a running Blackfin system, for example:

        root:~> ipkg install asterisk

  will grab the latest Asterisk package from a web site and install it on a Blackfin based hardware platform. Use is not limited to Asterisk, it could be used to manage any Blackfin software, including the kernel. The use of ipkg is very common on the OpenWRT project, and similar package based systems are common on x86 Linux, e.g. apt-get, debs, rpms.

  Note that software is installed at run time rather than build time. Packages (via ipkg) are used to install applications like Asterisk, rather than placing everything in a uImage. The target hardware is initially booted with a basic kernel and root file system, then packages are installed as required. We assume availability of persistent (non ram) based file system like yaffs or jffs2.

  The goal is to make installing software on the Blackfin much easier for end-users, more like an x86 experience.

* Compared to buildroot systems BAPS has a flat directory structure to ease development (less wear on your tab key). It is designed to allow modular compilation of packages, e.g. you can compile a single application without building the entire uImage. Faster and less output to wade through. Makefiles (e.g. asterisk.mk) and source (e.g. asterisk-1.4.4) are within one directory level of each other for easy navigation of the source tree. There is less chance of breaking the build system due to decoupling of modules (kernel, root fs, are separate from Asterisk).

## Packages

In addition to an IP08/IP04/IP01 uImage (kernel plus basic root filesystem) there is a growing list of packages:

<table>
  <tr>
    <th>Name</th><th>Description</th>
  </tr>
  <tr>
    <td>asterisk</td><td>Asterisk is a complete PBX in software. It provides all of the features you would expect from a PBX and more. Asterisk does voice over IP in three protocols, and can interoperate with almost all standards-based telephone equipment using relatively inexpensive hardware.</td>
  </tr>
  <tr>
    <td>dropbear</td><td>Dropbear is a relatively small SSH 2 server and client.</td>
  </tr>
  <tr>
    <td>g729</td><td>G.729 Codec.</td>
  </tr>
  <tr>
    <td>libgmp</td><td>GNU MP is a portable library written in C for arbitrary precision arithmetic on integers, rational numbers, and floating-point numbers. It aims to provide the fastest possible arithmetic for all applications that need higher precision than is directly supported by the basic C types.</td>
  </tr>
  <tr>
    <td>libssl</td><td>A toolkit implementing SSL v2/v3 and TLS protocols with full-strength cryptography world-wide.</td>
  </tr>
  <tr>
    <td>libtiff</td><td>Tiff image file format library.</td>
  </tr>
  <tr>
    <td>libxml</td><td>A library for manipulating XML and HTML resources.</td>
  </tr>
  <tr>
    <td>openvpn</td><td>A web-scale networking platform enabling the next wave of VPN services.</td>
  </tr>
  <tr>
    <td>oslec</td><td>Open Source Line Echo Canceller, a high quality free echo canceller for Asterisk.</td>
  </tr>
  <tr>
    <td>spandsp</td><td>Telephony Algorithms and Digital Signal Processing Routines.</td>
  </tr>
  <tr>
    <td>vim</td><td>Vim is an almost compatible version of the UNIX editor Vi.</td>
  </tr>
  <tr>
    <td>zaptel</td><td>Telephony hardware drivers for IP04 SPI-over-SPORT1 version (later Atcom IP04s, IP08s).</td>
  </tr>
</table>

## Getting Started

The installation of the BAPs uImage is still a little complex (apologies). It requires working with u-boot using the RS-232 console interface. For more information on this process please see the [IP04 Wiki](http://www.voip-info.org/wiki/view/IP04+Open+Hardware+IP-PBX) or please post to the Blackfin Asterisk forum.

However once the uImage is installed life gets much easier!

This process will **erase your IP04 root file system** so please backup anything you really need (like your asterisk conf files).

1. Get the baseline BAPs uImage (contains kernel and basic root file system) and place it on your tftp server:

        http://www.rowetel.com/ucasterisk/downloads/uImage_r3.IP08

  > **NOTE:** Despite it's name, uImage_r3.IP08 works fine on both the IP04 and IP08.

2. Connect an RS-232 cable to your IP04 (via the daughter board) and stop the boot process at the u-boot prompt.
  Now we are going to write the new uImage to flash. You only need to configure ethaddr1 if you have two ethernet interfaces.

  > **CAUTION:** Do not cut/paste the steps below into your serial terminal program, as they often cannot respond fast enough and lose characters. Type each line carefully by hand.

  Install the new uImage into NAND flash using u-boot:

        ip04>set autostart
        ip04>set serverip your.tftp.server
        ip04>tftp 0x1000000 uImage_r2.ip08
        ip04>nand erase clean
        ip04>nand erase
        ip04>nand write 0x1000000 0x0 0x300000
        ip04>set bootargs ethaddr=$(ethaddr) ethaddr1=$(ethaddr1) $(con) root=/dev/mtdblock0 rw
        ip04>save
        ip04>bootm 0x1000000

  (uClinux will boot...)

  > **TIP:** If Linux doesn't boot or you experience other problems reboot into uboot, type `print`, and carefully check bootargs.

3. Now we have uClinux running, but using a ram-based ext2 file system (mtdblock0) for root. So we need to copy /root into the yaffs file system:

  On the IP04:

        root:~> copy_rootfs.sh
        root:~> reboot

4. Now set up u-boot to mount root from yaffs (some of these env variables may be set already, use `print` to check):

        ip04>set autostart yes
        ip04>set bootargs ethaddr=$(ethaddr) ethaddr1=$(ethaddr1) $(con) $(root)
        ip04>set nandboot 'nboot 0x2000000 0x0'
        ip04>set bootcmd run nandboot
        ip04>save
        ip04>reset

5. Boot IP04 to a uClinux root prompt.  Use mount to check that root is mounted on mtdblock2 (yaffs file system).

  Now we can install some packages using ipkg:

        $root:~> ipkg update
        $root:~> ipkg install zaptel-spi asterisk native-sounds
        $root:~> reboot

## Documentation

After installation many packages include documentation in the /usr/doc directory of the IP04.  These are small files designed to capture Blackfin or IP04 specific information, for example simple tests and notes on differences from other versions of the same package. The documentation files can also be browsed from [BAPS2 git](http://svn.astfin.org/software/baps/trunk/doc).

## HOWTO - Developer

1. Clone BAPS2:

        $ git clone git://github.com/jlduran/BAPS2.git
        $ cd BAPS2

2. You need to install the toolchain and uClibc:

        [BAPS2]$ wget http://download.analog.com/27516/frsrelease/5/0/8/5087/blackfin-toolchain-08r1.5-14.i386.tar.bz2
        [BAPS2]$ tar xjf blackfin-toolchain-08r1.5-14.i386.tar.bz2
        [BAPS2]$ wget http://download.analog.com/27516/frsrelease/5/0/7/5075/blackfin-toolchain-uclibc-default-08r1.5-14.i386.tar.bz2
        [BAPS2]$ tar xjf blackfin-toolchain-uclibc-default-08r1.5-14.i386.tar.bz2

  If you untar the toolchain and uClibc in the BAPS2 directory, it will be included in your path automatically. If you untar it somewhere else make sure the bin directories in this toolchain are in your path.

3. Make a BAPS2 uImage that supports ipkg. This also configures uClinux-dist to support compiling of other packages. You need to make uClinux before making any other packages.

        [BAPS2]$ make -f uClinux.mk uClinux
        [BAPS2]$ cp uClinux-dist/images/uImage /tftpboot/uImage

  You can then try booting from your uImage via tftp, in u-boot:

        ip04>set autostart
        ip04>set bootargs ethaddr=your:mac:address root=/dev/mtdblock0 rw
        ip04>save
        ip04>tftp 0x1000000 uImage
        ip04>bootm

  Or you can flash the uImage as described in the [Getting Started](#getting-started) section above.

4. Check out ipkg.conf:

        root:~> cat /etc/ipkg.conf
        src snapshots http://rowetel.com/ucasterisk/ipkg
        dest root /

  Try installing a simple ipkgs:

        root:~> ipkg update
        root:~> ipkg list
        root:~> ipkg install hello
        root:~> hello

5. BAPS uses init.d type start up scripts, for example:

        root:~> ls /etc/init.d