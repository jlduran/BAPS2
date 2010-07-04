# dahdi.mk
# Makefile for DAHDI with Astfin GSM module support
#
# make -f dahdi.mk dahdi-package
#
# DAHDI_GSM_MODULE=y/n enables/disables support for uCpbx's GSM1 module.
# DAHDI_SPI_INTERFACE with DAHDI_GSM_MODULE currently not supported.
# http://www.ucpbx.com/files/file/GSM1_User_Manual.pdf
#
# Choose just one (1) of the lines below:
#   DAHDI_SPI_INTERFACE uses the Blackfin SPI hardware to talk
#   to the analog modules. This method is used for the earlier IP04s
#   and all IP04s shipped by Rowetel. Unfortunately it means the MMC
#   card can't be used, as dahdi hogs the SPI bus!
#
#   DAHDI_SPORT_INTERFACE uses the SPORT1 hardware to implement
#   a SPI port to talk to the analog modules.  This fees up the SPI
#   bus for the MMC card. This was developed by Alex Tao (thanks Alex)
#   and is likely to be the standard for the future.
#
# Note that different CPLD firmware is required to support each SPI
# method, if your IP04 won't detect modules this is a sign you may
# have the wrong CPLD firmware and/or driver.

DAHDI_SPORT_INTERFACE=y
DAHDI_GSM_MODULE=y

include rules.mk

DAHDI_VERSION=2.2.0.2+2.2.0
DAHDI_NAME=dahdi-linux-complete-$(DAHDI_VERSION)
DAHDI_DIR=$(BUILD_DIR)/$(DAHDI_NAME)
DAHDI_SOURCE=$(DAHDI_NAME).tar.gz
DAHDI_SITE=http://downloads.asterisk.org/pub/telephony/dahdi-linux-complete/releases
DAHDI_UNZIP=zcat
DAHDI_TOPDIR_MODULES:="dahdi bfsi wcfxs sport_interface ztdummy"
DAHDI_EXTRA_CFLAGS+=-DECHO_CAN_FROMENV -DECHO_CAN_ZARLINK
ifeq ($(strip $(DAHDI_SPORT_INTERFACE)),y)
DAHDI_EXTRA_CFLAGS+=-DCONFIG_4FX_SPORT_INTERFACE
else
DAHDI_EXTRA_CFLAGS+=-DCONFIG_4FX_SPI_INTERFACE
endif

STAGING_INC=$(STAGING_DIR)/usr/include
STAGING_LIB=$(STAGING_DIR)/usr/lib

MOD_PATH:=$(UCLINUX_DIST)/root/lib/modules
MOD_DIR:=$(shell ls $(UCLINUX_DIST)/root/lib/modules)

PKG_VERSION:=2.2.0
PKG_RELEASE:=1
PKG_NAME:=dahdi

ifeq ($(strip $(DAHDI_SPORT_INTERFACE)),y)
ifeq ($(strip $(DAHDI_GSM_MODULE)),y)
COMMENT:=with support for uCpbx GSM1 module SPI-over-SPORT1 version (later Atcom IP04s, IP08s).
else
COMMENT:=SPI-over-SPORT1 version (later Atcom IP04s, IP08s).
endif
else
COMMENT:=SPI-over-SPI hardware version (Rowetel IP04).
endif

TARGET_DIR=$(TOPDIR)/tmp/$(PKG_NAME)/ipkg/$(PKG_NAME)

PKG_BUILD_DIR:=$(TOPDIR)/tmp/$(PKG_NAME)/

$(DL_DIR)/$(DAHDI_SOURCE):
	mkdir -p $(DL_DIR)
	$(WGET) -P $(DL_DIR) $(DAHDI_SITE)/$(DAHDI_SOURCE)

$(DAHDI_DIR)/.unpacked: $(DL_DIR)/$(DAHDI_SOURCE) 
	$(DAHDI_UNZIP) $(DL_DIR)/$(DAHDI_SOURCE) | \
	tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	touch $(DAHDI_DIR)/.unpacked

$(DAHDI_DIR)/.configured: $(DAHDI_DIR)/.unpacked
	cd $(DAHDI_DIR); ./configure --host=bfin-linux-uclibc

	# we use sym-links so that any changes we make to dahdi
	# get captured by SVN
ifeq ($(strip $(DAHDI_GSM_MODULE)),y)
	ln -sf $(BUILD_DIR)/src/dahdi-gsm/sport_interface.c $(DAHDI_DIR)/kernel/sport_interface.c
	ln -sf $(BUILD_DIR)/src/dahdi-gsm/wcfxs.c $(DAHDI_DIR)/kernel/wcfxs.c
	ln -sf $(BUILD_DIR)/src/dahdi-gsm/fx.c $(DAHDI_DIR)/kernel/fx.c
	ln -sf $(BUILD_DIR)/src/dahdi-gsm/bfsi.c $(DAHDI_DIR)/kernel/bfsi.c
	ln -sf $(BUILD_DIR)/src/dahdi-gsm/gsm_module.c $(DAHDI_DIR)/kernel/gsm_module.c
	ln -sf $(BUILD_DIR)/src/dahdi-gsm/GSM_module_SPI.h $(DAHDI_DIR)/kernel/GSM_module_SPI.h
	cp -f $(BUILD_DIR)/src/dahdi-gsm/dahdi-base.c-1.4.9.2 $(DAHDI_DIR)/kernel/dahdi-base.c
else
	ln -sf $(BUILD_DIR)/src/sport_interface.c $(DAHDI_DIR)/kernel/sport_interface.c
	ln -sf $(BUILD_DIR)/src/wcfxs.c $(DAHDI_DIR)/kernel/wcfxs.c
	ln -sf $(BUILD_DIR)/src/fx.c $(DAHDI_DIR)/kernel/fx.c
	ln -sf $(BUILD_DIR)/src/bfsi.c $(DAHDI_DIR)/kernel/bfsi.c
endif
	ln -sf $(BUILD_DIR)/src/sport_interface.h $(DAHDI_DIR)/kernel/sport_interface.h
	ln -sf $(BUILD_DIR)/src/wcfxs.h $(DAHDI_DIR)/kernel/wcfxs.h
	ln -sf $(BUILD_DIR)/src/bfsi.h $(DAHDI_DIR)/kernel/bfsi.h

	# patch for Zaptel

	patch -p0 < patch/dahdi.patch

	# patch for Oslec

	cd $(DAHDI_DIR); \
	patch -p1 < $(OSLEC_DIR)/kernel/dahdi-$(DAHDI_VERSION).patch
	touch $(DAHDI_DIR)/.configured

dahdi: $(DAHDI_DIR)/.configured

	# build libtonezone, reqd for Asterisk

	cd $(DAHDI_DIR); make libtonezone.so

	# install files needed for other apps

	mkdir -p $(STAGING_INC)
	mkdir -p $(STAGING_INC)/dahdi
	mkdir -p $(STAGING_LIB)
	mkdir -p $(TARGET_DIR)/lib
	cp $(DAHDI_DIR)/tonezone.h $(STAGING_INC)/dahdi
	cp $(DAHDI_DIR)/ztcfg.h $(STAGING_INC)
	cp $(DAHDI_DIR)/kernel/dahdi.h $(STAGING_INC)/dahdi
	cp $(DAHDI_DIR)/libtonezone.so $(STAGING_LIB)
	cp $(DAHDI_DIR)/libtonezone.so $(TARGET_DIR)/lib
	cd $(TARGET_DIR)/lib/; ln -sf libtonezone.so libtonezone.so.1.0
	$(TARGET_STRIP) $(TARGET_DIR)/lib/libtonezone.so
	cp $(OSLEC_DIR)/kernel/Module.symvers $(DAHDI_DIR)/kernel

	# build ztcfg, ztscan and zapscan

	cd $(DAHDI_DIR); make ztcfg ztscan
	bfin-linux-uclibc-gcc -I$(STAGING_INC) src/zapscan.c \
	-o $(DAHDI_DIR)/zapscan -Wall

	# build kernel modules (DAHDI_TOPDIR_MODULES)

	cd $(DAHDI_DIR); \
        make version.h
	make PWD=$(DAHDI_DIR) TOPDIR_MODULES=$(DAHDI_TOPDIR_MODULES) \
                EXTRA_CFLAGS="$(DAHDI_EXTRA_CFLAGS)" \
                KSRC=$(UCLINUX_DIST)/linux-2.6.x \
                -C $(DAHDI_DIR) modules
	make PWD=$(DAHDI_DIR)  \
		EXTRA_CFLAGS="$(DAHDI_EXTRA_CFLAGS)" \
		KSRC=$(UCLINUX_DIST)/linux-2.6.x \
		-C $(DAHDI_DIR) fxstest

	# set up dir structure for package

	mkdir -p $(TARGET_DIR)/lib/modules/$(MOD_DIR)/misc
	mkdir -p $(TARGET_DIR)/bin
	mkdir -p $(TARGET_DIR)/etc/init.d 
	mkdir -p $(TARGET_DIR)/etc/asterisk

	# install

	cp -f $(DAHDI_DIR)/kernel/dahdi.ko $(DAHDI_DIR)/kernel/wcfxs.ko \
	$(DAHDI_DIR)/kernel/sport_interface.ko $(DAHDI_DIR)/kernel/bfsi.ko \
	$(TARGET_DIR)/lib/modules/$(MOD_DIR)/misc
	cp -f $(DAHDI_DIR)/kernel/ztdummy.ko \
	$(TARGET_DIR)/lib/modules/$(MOD_DIR)/misc
	cp -f $(DAHDI_DIR)/ztcfg $(DAHDI_DIR)/zapscan $(DAHDI_DIR)/ztscan $ $(DAHDI_DIR)/fxstest $(TARGET_DIR)/bin
	cp files/dahdi.init $(TARGET_DIR)/etc/init.d/dahdi
	chmod a+x $(TARGET_DIR)/etc/init.d/dahdi
	cp -f files/dahdi.conf.in $(TARGET_DIR)/etc/dahdi.conf
	cp -f files/zapata.conf.in $(TARGET_DIR)/etc/asterisk

	touch $(PKG_BUILD_DIR)/.built

all: dahdi

dahdi-dirclean:
	rm -Rf $(DAHDI_DIR)
	rm -Rf $(TOPDIR)/tmp/$(PKG_NAME)

ZO = dahdi-$(DAHDI_VERSION)-orig
Z = dahdi-$(DAHDI_VERSION)

dahdi-make-patch:

        # untar original, to save time we check if the orig is already there

	if [ ! -d $(DAHDI_DIR)-orig ] ; then \
		cd $(DL_DIR); \
	        tar xzf $(DAHDI_SOURCE); \
		mv $(Z) $(DAHDI_DIR)-orig; \
	fi

	-cd $(BUILD_DIR); diff -uN \
	$(ZO)/Makefile \
	$(Z)/Makefile \
	> $(PWD)/patch/dahdi.patch

define Package/$(PKG_NAME)
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Zaptel
  DESCRIPTION:=\
        Telephony hardware drivers for IP04 $(COMMENT) 
  DEPENDS:=oslec
  URL:=http://www.asterisk.org
endef

# post installation - add the modules.dep entries

define Package/$(PKG_NAME)/postinst
#!/bin/sh
cd /lib/modules/$(MOD_DIR)
cat modules.dep | sed '/.*dahdi.ko:/ d' > modules.tmp
cat modules.tmp | sed '/.*wcfxs.ko:/ d' > modules.tmp1
cat modules.tmp1 | sed '/.*bfsi.ko:/ d' > modules.tmp
cat modules.tmp | sed '/.*ztdummy.ko:/ d' > modules.tmp1
cat modules.tmp1 | sed '/.*sport_interface.ko:/ d' > modules.dep
rm -f modules.tmp modules.tmp1
echo /lib/modules/$(MOD_DIR)/misc/bfsi.ko: >> modules.dep
echo /lib/modules/$(MOD_DIR)/misc/sport_interface.ko: >> modules.dep
echo /lib/modules/$(MOD_DIR)/misc/dahdi.ko: /lib/modules/$(MOD_DIR)/misc/oslec.ko >> modules.dep
rm -Rf /dev/zap
mkdir -p /dev/zap
mknod /dev/zap/ctl c 196 0
mknod /dev/zap/timer c 196 253
mknod /dev/zap/channel c 196 254
mknod /dev/zap/pseudo c 196 255
mknod /dev/zap/1 c 196 1
mknod /dev/zap/2 c 196 2
mknod /dev/zap/3 c 196 3
mknod /dev/zap/4 c 196 4
mknod /dev/zap/5 c 196 5
mknod /dev/zap/6 c 196 6
mknod /dev/zap/7 c 196 7
mknod /dev/zap/8 c 196 8

echo /lib/modules/$(MOD_DIR)/misc/ztdummy.ko: /lib/modules/$(MOD_DIR)/misc/dahdi.ko >> modules.dep
echo /lib/modules/$(MOD_DIR)/misc/wcfxs.ko: /lib/modules/$(MOD_DIR)/misc/bfsi.ko /lib/modules/$(MOD_DIR)/misc/sport_interface.ko /lib/modules/$(MOD_DIR)/misc/dahdi.ko >> modules.dep
/etc/init.d/dahdi enable
endef

# pre-remove - remove the modules.dep entries

define Package/$(PKG_NAME)/prerm
#!/bin/sh
cd /lib/modules/$(MOD_DIR)
cat modules.dep | sed '/.*dahdi.ko:/ d' > modules.tmp
cat modules.tmp | sed '/.*wcfxs.ko:/ d' > modules.tmp1
cat modules.tmp1 | sed '/.*bfsi.ko:/ d' > modules.tmp
cat modules.tmp | sed '/.*ztdummy.ko:/ d' > modules.tmp1
cat modules.tmp1 | sed '/.*sport_interface.ko:/ d' > modules.dep
rm -f modules.tmp modules.tmp1
/etc/init.d/dahdi disable
rm -f -r /dev/zap
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

dahdi-package: dahdi $(PACKAGE_DIR)/$(PKG_NAME)_$(VERSION)_$(PKGARCH).ipk

