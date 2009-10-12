########################################################
# OpenVPN for uClinux
# Alex Brett October 2009
#
# make -f libssl.mk libssl-package
# make -f openvpn.mk openvpn-package 
#
# Run after "make -f libssl.mk libssl"
#
# TODO: Fix the --daemon mode (currently doesn't work)
#       Add an init script
#########################################################

include rules.mk

OPENVPN_SITE=http://openvpn.net/release/
OPENVPN_VERSION=2.0.9
OPENVPN_SOURCE=openvpn-$(OPENVPN_VERSION).tar.gz
OPENVPN_UNZIP=zcat
OPENVPN_DIR=$(BUILD_DIR)/openvpn

TARGET_DIR=$(BUILD_DIR)/tmp/openvpn/ipkg/openvpn
PKG_NAME:=openvpn
PKG_VERSION:=$(OPENVPN_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/tmp/openvpn

STAGING_INC=$(STAGING_DIR)/usr/include
STAGING_LIB=$(STAGING_DIR)/usr/lib

export CFLAGS = -I$(STAGING_DIR)/usr/include
export LDFLAGS = -L$(STAGING_DIR)/usr/lib
export CC=bfin-linux-uclibc-gcc 

OPENVPN_CONFIGURE_OPTS=--host=bfin-linux-uclibc \
			--build=i686-pc-linux-gnu \
			--target=bfin-linux-uclibc \
			--disable-lzo \
			--with-ssl-headers=$(STAGING_INC) \
			--with-ssl-lib=$(STAGING_LIB)

$(DL_DIR)/$(OPENVPN_SOURCE):
	$(WGET) -P $(DL_DIR) $(OPENVPN_SITE)/$(OPENVPN_SOURCE)

$(OPENVPN_DIR)/.unpacked: $(DL_DIR)/$(OPENVPN_SOURCE)
	$(OPENVPN_UNZIP) $(DL_DIR)/$(OPENVPN_SOURCE) | \
	tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	mv $(BUILD_DIR)/openvpn-$(OPENVPN_VERSION) $(BUILD_DIR)/openvpn
	$(PATCH_KERNEL) $(OPENVPN_DIR) patch openvpn.patch

	touch $(OPENVPN_DIR)/.unpacked

$(OPENVPN_DIR)/.configured: $(OPENVPN_DIR)/.unpacked
	cd $(OPENVPN_DIR); \
	./configure $(OPENVPN_CONFIGURE_OPTS)
	touch $(OPENVPN_DIR)/.configured

$(PKG_BUILD_DIR)/.built: $(OPENVPN_DIR)/.configured
	$(MAKE) -C $(OPENVPN_DIR) 

	rm -Rf $(TARGET_DIR)
	mkdir -p $(TARGET_DIR)
	mkdir -p $(TARGET_DIR)/bin
	mkdir -p $(TARGET_DIR)/etc/openvpn
	cp -v $(OPENVPN_DIR)/openvpn $(TARGET_DIR)/bin/

	touch $(PKG_BUILD_DIR)/.built

.PHONY: openvpn
openvpn: $(PKG_BUILD_DIR)/.built

all: openvpn

dirclean:
	rm -rf $(OPENVPN_DIR)


#---------------------------------------------------------------------------
#                              CREATING PACKAGE
#---------------------------------------------------------------------------

define Package/openvpn
  SECTION:=net
  CATEGORY:=Network
  TITLE:=OpenVPN
  DEPENDS:=libssl
  DESCRIPTION:=\
        A web-scale networking platform enabling the next wave of VPN services
  URL:=http://openvpn.net
  ARCHITECTURE:=bfin-uclinux

endef

# post installation - add the sym link for auto start

define Package/$(PKG_NAME)/postinst
#!/bin/sh
rm -rf /dev/net
mkdir -p /dev/net
mknod /dev/net/tun c 10 200
chmod 755 /dev/net
chmod 640 /dev/net/tun
endef

# pre-remove - remove sym link

define Package/$(PKG_NAME)/prerm
#!/bin/sh
rm -rf /bin/openvpn
rm -rf /dev/net
endef

$(eval $(call BuildPackage,openvpn))

openvpn-package: openvpn $(PACKAGE_DIR)/openvpn_$(VERSION)_$(PKGARCH).ipk

