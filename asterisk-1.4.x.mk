# asterisk-1.4.x.mk, used for building different asterisk versions, just
# change the ASTERISK_VERSION field below and:
#
#  make -f asterisk-1.4.x.mk asterisk-package
#
# Before building asterisk you need:
#
#  make -f uClinux & make -f libssl.mk

include rules.mk

ASTERISK_VERSION=1.4.21.2
ASTERISK_NAME=asterisk-$(ASTERISK_VERSION)
ASTERISK_DIR=$(BUILD_DIR)/$(ASTERISK_NAME)
ASTERISK_SOURCE=$(ASTERISK_NAME).tar.gz
ASTERISK_SITE=http://ftp.digium.com/pub/asterisk/releases
ASTERISK_UNZIP=zcat
TARGET_DIR=$(TOPDIR)/tmp/asterisk-$(ASTERISK_VERSION)/ipkg/asterisk-$(ASTERISK_VERSION)

PKG_NAME:=asterisk-$(ASTERISK_VERSION)
PKG_VERSION:=$(ASTERISK_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(TOPDIR)/tmp/asterisk-$(ASTERISK_VERSION)

STAGING_INC=$(STAGING_DIR)/usr/include
STAGING_LIB=$(STAGING_DIR)/usr/lib
ASTERISK_CFLAGS=-g -mfdpic -mfast-fp -ffast-math -D__FIXED_PT__ \
-D__BLACKFIN__ -I$(STAGING_INC) -fno-jump-tables
ASTERISK_LDFLAGS=-mfdpic -L$(STAGING_LIB) -lpthread -ldl
ASTERISK_CONFIGURE_OPTS=--host=bfin-linux-uclibc --disable-largefile \
--without-pwlib --without-curl CFLAGS="$(ASTERISK_CFLAGS)" \
LDFLAGS="$(ASTERISK_LDFLAGS)"

$(DL_DIR)/$(ASTERISK_SOURCE):
	mkdir -p $(DL_DIR)
	$(WGET) -P $(DL_DIR) $(ASTERISK_SITE)/$(ASTERISK_SOURCE)

$(ASTERISK_DIR)/.unpacked: $(DL_DIR)/$(ASTERISK_SOURCE) 
	$(ASTERISK_UNZIP) $(DL_DIR)/$(ASTERISK_SOURCE) | \
	tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	$(PATCH_KERNEL) $(ASTERISK_DIR) patch dtmf-1.4.20.patch
	$(PATCH_KERNEL) $(ASTERISK_DIR) patch gui-crash.patch
	$(PATCH_KERNEL) $(ASTERISK_DIR) patch asterisk.patch
	ln -sf $(BUILD_DIR)/src/codec_g729.c $(ASTERISK_DIR)/codecs
	ln -sf $(BUILD_DIR)/src/codec_speex.c $(ASTERISK_DIR)/codecs
	ln -sf $(BUILD_DIR)/src/g729ab_codec.h $(ASTERISK_DIR)/codecs
	touch $(ASTERISK_DIR)/.unpacked

$(ASTERISK_DIR)/.configured: $(ASTERISK_DIR)/.unpacked $(STAGING_LIB)/libgsm.a
	ln -sf $(BUILD_DIR)/patch/menuselect.makeopts $(ASTERISK_DIR)/
	cd $(ASTERISK_DIR); ./configure $(ASTERISK_CONFIGURE_OPTS)
	touch $(ASTERISK_DIR)/.configured

# optimised GSM library, rather than slow version in asterisk source

$(STAGING_LIB)/libgsm.a:
	-patch -f -p0 < patch/blackfin-gsm.patch
	make -C $(UCLINUX_DIST)/lib/blackfin-gsm \
	CC=bfin-linux-uclibc-gcc AR=bfin-linux-uclibc-ar
	cp $(UCLINUX_DIST)/lib/blackfin-gsm/gsm/lib/libgsm.a $(STAGING_LIB)
	cp $(UCLINUX_DIST)/lib/blackfin-gsm/gsm/inc/gsm.h $(STAGING_INC)

asterisk: $(ASTERISK_DIR)/.configured $(ASTERISK_DIR) 

	OPTIMIZE="-Os" ASTCFLAGS="$(ASTERISK_CFLAGS)" \
	ASTLDFLAGS="$(ASTERISK_LDFLAGS)" \
	$(MAKE) -C $(ASTERISK_DIR) NOISY_BUILD=1

	rm -Rf $(TARGET_DIR)
	mkdir -p $(TARGET_DIR)
	mkdir -p $(TARGET_DIR)/bin/
	mkdir -p $(TARGET_DIR)/var/lib/asterisk/agi-bin
	mkdir -p $(TARGET_DIR)/var/lib/asterisk/sounds
	mkdir -p $(TARGET_DIR)/var/lib/asterisk/sounds/moh
	mkdir -p $(TARGET_DIR)/var/lib/asterisk/sounds/meetme
	mkdir -p $(TARGET_DIR)/var/lib/asterisk/sounds/voicemail
	mkdir -p $(TARGET_DIR)/var/spool/asterisk
	mkdir -p $(TARGET_DIR)/usr/lib/asterisk/modules
	ln -sf /var/lib/asterisk/sounds/moh \
	$(TARGET_DIR)/var/lib/asterisk/
	ln -sf /var/lib/asterisk/sounds/meetme \
	$(TARGET_DIR)/var/spool/asterisk/
	ln -sf /var/lib/asterisk/sounds/voicemail \
	$(TARGET_DIR)/var/spool/asterisk/
	cp -v $(ASTERISK_DIR)/main/asterisk $(TARGET_DIR)/bin/
	ln -sf /bin/asterisk $(TARGET_DIR)/bin/rasterisk
	find $(ASTERISK_DIR) -name '*.so' -exec cp -v "{}" \
	$(TARGET_DIR)/usr/lib/asterisk/modules/ \;
	$(TARGET_STRIP) $(TARGET_DIR)/bin/asterisk
	$(TARGET_STRIP) $(TARGET_DIR)/usr/lib/asterisk/modules/*.so

	#mkdir -p $(TARGET_DIR)/etc/asterisk
	#for x in $(ASTERISK_DIR)/configs/*.sample; do \
	#	cp $$x $(TARGET_DIR)/etc/asterisk/`basename $$x .sample`; \
	#done

	# Install default Asterisk conf and gsm prompt files
	# (be careful not to copy .svn files)

	mkdir -p $(TARGET_DIR)/etc/asterisk
	cp files/asterisk-defaults/etc/asterisk/*.conf $(TARGET_DIR)/etc/asterisk
	mkdir -p $(TARGET_DIR)/etc/asterisk/tools
	cp files/asterisk-defaults/etc/asterisk/tools/* $(TARGET_DIR)/etc/asterisk/tools
	mkdir -p $(TARGET_DIR)/var/lib/asterisk/sounds
	cp files/asterisk-defaults/var/lib/asterisk/sounds/*.gsm \
	$(TARGET_DIR)/var/lib/asterisk/sounds
	mkdir -p $(TARGET_DIR)/var/lib/asterisk/static-http
	cp files/asterisk.index.html \
	$(TARGET_DIR)/var/lib/asterisk/static-http/index.html

	# need this codecs.conf for our Speex patch to work
	cp files/codecs.conf.profile $(TARGET_DIR)/etc/asterisk/codecs.conf

	mkdir -p $(TARGET_DIR)/etc/init.d 
	cp files/asterisk.init $(TARGET_DIR)/etc/init.d/asterisk
	cp files/zaptel.conf.in $(TARGET_DIR)/etc/asterisk
	chmod a+x $(TARGET_DIR)/etc/init.d/asterisk

	touch $(PKG_BUILD_DIR)/.built

#---------------------------------------------------------------------------
#                     USEFUL ASTERISK MAKEFILE TARGETS     
#---------------------------------------------------------------------------

all: asterisk

asterisk-configure: $(ASTERISK_DIR)/.configured

asterisk-config: $(ASTERISK_DIR)/.configured
	$(MAKE) -C $(ASTERISK_DIR) menuconfig

asterisk-codecs:
	OPTIMIZE="-O4" ASTCFLAGS="$(ASTERISK_CFLAGS)" \
	ASTLDFLAGS="$(ASTERISK_LDFLAGS)" \
	$(MAKE) -C $(ASTERISK_DIR) codecs NOISY_BUILD=1

asterisk-pbx:
	OPTIMIZE="-O4" ASTCFLAGS="$(ASTERISK_CFLAGS)" \
	ASTLDFLAGS="$(ASTERISK_LDFLAGS)" \
	$(MAKE) -C $(ASTERISK_DIR) pbx NOISY_BUILD=1

dirclean:
	rm -rf $(ASTERISK_DIR)

#---------------------------------------------------------------------------
#                              CREATING PATCHES     
#---------------------------------------------------------------------------

# NOTE - this section is deprected - pls use asterisk-spandsp.mk to
# create patches to ensure CID code is included in the patch.

#---------------------------------------------------------------------------
#                              CREATING PACKAGE    
#---------------------------------------------------------------------------

define Package/$(PKG_NAME)
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Asterisk PBX
  DESCRIPTION:=\
        Asterisk is a complete PBX in software. It provides all \\\
        of the features you would expect from a PBX and more. \\\
        Asterisk does voice over IP in three protocols, and can \\\
        interoperate with almost all standards-based telephone \\\
        equipment using relatively inexpensive hardware.
  URL:=http://www.asterisk.org/
  ARCHITECTURE:=bfin-uclinux

endef

# post installation - add the sym link for auto start

define Package/$(PKG_NAME)/postinst
#!/bin/sh
/etc/init.d/asterisk enable
endef

# pre-remove - remove sym link

define Package/$(PKG_NAME)/prerm
#!/bin/sh
/etc/init.d/asterisk disable
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

asterisk-package: asterisk $(PACKAGE_DIR)/$(PKG_NAME)_$(VERSION)_$(PKGARCH).ipk
	mv $(PACKAGE_DIR)/$(PKG_NAME)_$(VERSION)_$(PKGARCH).ipk \
	$(PACKAGE_DIR)/$(PKG_NAME)-$(PKGARCH).ipk
