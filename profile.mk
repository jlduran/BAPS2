# Makefile for Analog Profiling Project
# David Rowe 2 Nov 2007

include rules.mk

#===========================================================================
# BF537 STAMP Image
# Used for Call generator (CG) and Device under Test (DUT) #1
#===========================================================================

UCLINUX_DIRNAME=uClinux-dist
UCLINUX_DIR=$(BUILD_DIR)/$(UCLINUX_DIRNAME)
UCLINUX_KERNEL_SRC=$(BUILD_DIR)/uClinux-dist/linux-2.6.x
UCLINUX_SOURCE=uClinux-dist-2007R1.1-RC3.tar.bz2
UCLINUX_SITE=http://blackfin.uclinux.org/gf/download/frsrelease/350/3340/uClinux-dist-2007R1.1-RC3.tar.bz2
UCLINUX_UNZIP=bzcat
ROOT_DIR=$(UCLINUX_DIR)/root

#---------------------------------------------------------------------------
#                        downloaded uClinux-dist
#---------------------------------------------------------------------------

$(DL_DIR)/$(UCLINUX_SOURCE):
	mkdir -p dl
	$(WGET) -P $(DL_DIR) $(UCLINUX_SITE)/$(UCLINUX_SOURCE)

#---------------------------------------------------------------------------
#                        unpack
#---------------------------------------------------------------------------

$(UCLINUX_DIR)/.unpacked: $(DL_DIR)/$(UCLINUX_SOURCE)
	tar xjf $(DL_DIR)/$(UCLINUX_SOURCE) -C $(BUILD_DIR)
	mv uClinux-dist.R1.1-RC3/  uClinux-dist
	touch $(UCLINUX_DIR)/.unpacked

#---------------------------------------------------------------------------
#                      configure uClinux-dist
#---------------------------------------------------------------------------

$(UCLINUX_DIR)/.configured: $(UCLINUX_DIR)/.unpacked
	cp -af patch/vendors/* $(UCLINUX_DIR)/vendors
	-$(MAKE) -C $(UCLINUX_DIR) AnalogDevices/BF537-STAMP_config
	touch $(UCLINUX_DIR)/.configured

#---------------------------------------------------------------------------
#                       make uClinux to create uImage
#---------------------------------------------------------------------------

uClinux-stamp: $(UCLINUX_DEP) $(UCLINUX_DIR)/.configured
	$(MAKE) -C $(UCLINUX_DIR) ROMFSDIR=$(ROOT_DIR)

#---------------------------------------------------------------------------
#                       make uImage with Asterisk
#---------------------------------------------------------------------------

# Note the Asterisk version we use for the profiling tests doesn't support
# analog ports, so we only compile Zaptel just to get libtonezone which
# is required to build Asterisk

asterisk: $(ROOT_DIR)/lib/libg729ab.so
	make -f oslec.mk      # only reqd to satisfy a dependency for zaptel
	make -f zaptel.mk     # only reqd for libtonezone
	make -f asterisk.mk
	cp -a $(TOPDIR)/tmp/asterisk/ipkg/asterisk/* $(ROOT_DIR)
	cp files/sip.conf.profile $(ROOT_DIR)/etc/asterisk
	cp files/sip.conf.profile $(ROOT_DIR)/etc/asterisk/sip.conf
	cp files/extensions.conf.profile $(ROOT_DIR)/etc/asterisk/extensions.conf
	cp files/modules.conf.profile $(ROOT_DIR)/etc/asterisk/modules.conf
	cp files/codecs.conf.profile $(ROOT_DIR)/etc/asterisk/codecs.conf
	cp files/demo-instruct.ulaw $(ROOT_DIR)/var/lib/asterisk/sounds/
	cp -a libbfgdots/g729/src.fdpic/libg729ab.so $(ROOT_DIR)/lib
	ln -s $(ROOT_DIR)/etc/init.d/asterisk $(ROOT_DIR)/etc/rc.d/S50asterisk
	make -C $(UCLINUX_DIR) IMAGEDIR=$(UCLINUX_DIR)/images \
	ROMFSDIR=$(UCLINUX_DIR)/root BLOCKS=15080 image

uImage.stamp: uClinux-stamp asterisk

#===========================================================================
# IP04 Image
# Used for Device under Test (DUT) #2
#===========================================================================

uImage-ip04:
	make -f uClinux.mk
	cp patch/vendors/AnalogDevices/BF537-STAMP/rc $(ROOT_DIR)/etc/rc

uImage.ip04: uImage-ip04 asterisk

#===========================================================================
# build libg729ab.so from ADI SVN
#===========================================================================

LIBG729AB_SITE=svn://sources.blackfin.uclinux.org/uclinux-dist/trunk/lib/libbfgdots

libbfgdots:	
	svn co $(LIBG729AB_SITE) libbfgdots

$(ROOT_DIR)/lib/libg729ab.so: libbfgdots
	cd libbfgdots; make

#===========================================================================

all:
	@echo "usage:"
	@echo "  make -f profile.mk uImage.stamp"
	@echo "OR (in a seperate directory)"
	@echo "  make -f profile.mk uImage.ip04"

dirclean:
	rm -Rf uClinux-dist
	rm -Rf libbfgdots
	make -f oslec.mk dirclean
	make -f zaptel.mk dirclean
	make -f asterisk.mk dirclean

