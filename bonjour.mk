#########################################################
# avahi  for  Switchfin
# Dimitar Penev, March 2010
#
# Copyright @ 2010 SwitchFin <dpn@switchfin.org>
#########################################################

include rules.mk

BONJOUR_SITE=http://www.opensource.apple.com/darwinsource/tarballs/other/mDNSResponder-107.6.tar.gz
BONJOUR_VERSION=107.6
BONJOUR_SOURCE=mDNSResponder-107.6.tar.gz
BONJOUR_CROSS_COMPILE_PATCH=bonjour.patch
BONJOUR_UNZIP=bzcat
BONJOUR_DIR_BASENAME=mDNSResponder-$(BONJOUR_VERSION)
BONJOUR_DIR=$(BUILD_DIR)/$(BONJOUR_DIR_BASENAME)
BONJOUR_CONFIGURE_OPTS=--host=bfin-linux-uclibc --with-distro=none

STAGING_INC=$(STAGING_DIR)/usr/include
TARGET_DIR=$(BUILD_DIR)/tmp/bonjour/ipkg/bonjour
PKG_NAME:=bonjour
PKG_VERSION:=$(BONJOUR_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/tmp/bonjour

$(DL_DIR)/$(BONJOUR_SOURCE):
	$(WGET) -P $(DL_DIR) $(BONJOUR_SITE)/$(BONJOUR_SOURCE)

$(BONJOUR_DIR)/.unpacked: $(DL_DIR)/$(BONJOUR_SOURCE)
	mkdir -p $(BONJOUR_DIR)
	tar -xf $(DL_DIR)/$(BONJOUR_SOURCE) -C $(BUILD_DIR)
	touch $(BONJOUR_DIR)/.unpacked

$(BONJOUR_DIR)/.configured: $(BONJOUR_DIR)/.unpacked
	patch -p0 -d $(BONJOUR_DIR) < patch/$(BONJOUR_CROSS_COMPILE_PATCH)
	cp -p src/nss.h $(STAGING_INC)
	touch $(BONJOUR_DIR)/.configured

bonjour: $(BONJOUR_DIR)/.configured
	make -C $(BONJOUR_DIR)/mDNSPosix/ CC=bfin-linux-uclibc-gcc STRIP=bfin-linux-uclibc-strip LD=bfin-linux-uclibc-gcc os=linux STAG_INC=$(STAGING_INC)
	mkdir -p $(TARGET_DIR)/usr/sbin/
	mkdir -p $(TARGET_DIR)/usr/bin/
	mkdir -p $(TARGET_DIR)/usr/lib/
	mkdir -p $(TARGET_DIR)/lib/
	cp -f $(BONJOUR_DIR)/mDNSPosix/build/prod/mdnsd $(TARGET_DIR)/usr/sbin/
	cp -f $(BONJOUR_DIR)/mDNSPosix/build/prod/libdns_sd.so $(TARGET_DIR)/lib/
	cp -f $(BONJOUR_DIR)/mDNSPosix/build/prod/libnss_mdns-0.2.so $(TARGET_DIR)/lib/
	cp -f $(BONJOUR_DIR)/Clients/build/dns-sd $(TARGET_DIR)/usr/bin/
	cd $(TARGET_DIR)/lib/; ln -sf libnss_mdns-0.2.so libnss_mdns.so.2

all: bonjour

bonjour-dirclean:
	rm -rf $(BONJOUR_DIR)
	rm -rf $(PKG_BUILD_DIR)

################################################
#
# Create IPKG
#
#################################################

define Package/$(PKG_NAME)
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Bonjour
  DESCRIPTION:=\
	Bonjour is a networking technology that lets you create an \\\
	instant network of computers and devices without any configuration. \\\
	It allows the services and capabilities of each device to be \\\
	registered on the network, and allows these services to be dynamically \\\
	discoverable by other devices on the network.
  URL:=http://developer.apple.com/bonjour
endef

# post installation

define Package/$(PKG_NAME)/postinst
#!/bin/sh
/etc/init.d/bonjour enable
endef

# pre-remove
define Package/$(PKG_NAME)/prerm
#!/bin/sh
/etc/init.d/bonjour disable
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

bonjour-package: bonjour $(PACKAGE_DIR)/$(PKG_NAME)_$(PKG_VERSION)_$(PKGARCH).ipk
