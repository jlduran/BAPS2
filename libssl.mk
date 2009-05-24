#########################################################
# libssl for uClinux and Asterisk, thanks to Astfin Guys!
# usage: make -f libssl.mk libssl
#
# Run after building uClinux-dist, copies shared libs to
# uClinux-dist/staging, ready for use in Asterisk if 
# required.
#
# Copy shared ssl lib object to target so that ssmtp with
# ssl support could run, Vincent Li (mchun.li@gmail.com) 
# Feb 2009
#########################################################

include rules.mk

LIBSSL_SITE=http://www.openssl.org/source
LIBSSL_VERSION=0.9.8k
LIBSSL_SOURCE=openssl-$(LIBSSL_VERSION).tar.gz
LIBSSL_UNZIP=zcat
LIBSSL_DIR=$(UCLINUX_DIST)/lib/libssl/openssl-$(LIBSSL_VERSION)

TARGET_DIR=$(BUILD_DIR)/tmp/libssl/ipkg/libssl
PKG_NAME:=libssl
PKG_VERSION:=$(LIBSSL_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/tmp/libssl


$(DL_DIR)/$(LIBSSL_SOURCE):
	$(WGET) -P $(DL_DIR) $(LIBSSL_SITE)/$(LIBSSL_SOURCE)

libssl-source: $(DL_DIR)/$(LIBSSL_SOURCE)

$(LIBSSL_DIR)/.unpacked: $(DL_DIR)/$(LIBSSL_SOURCE)
	$(LIBSSL_UNZIP) $(DL_DIR)/$(LIBSSL_SOURCE) | tar -C $(UCLINUX_DIST)/lib/libssl $(TAR_OPTIONS) -
	touch $(LIBSSL_DIR)/.unpacked

$(LIBSSL_DIR)/.configured: $(LIBSSL_DIR)/.unpacked
	$(PATCH_KERNEL) $(UCLINUX_DIST) patch libssl.patch
	touch $(LIBSSL_DIR)/.configured

libssl: $(LIBSSL_DIR)/.configured
	make -C $(LIBSSL_DIR)
	make -C $(LIBSSL_DIR) STAGEDIR=$(STAGING_DIR) ROMFSDIR=$(UCLINUX_DIST)/root romfs
	rm -Rf $(TARGET_DIR)
	mkdir -p $(TARGET_DIR)/lib
	cp -f $(LIBSSL_DIR)/libssl.so.0.9.8 $(TARGET_DIR)/lib
	cp -f $(LIBSSL_DIR)/libcrypto.so.0.9.8 $(TARGET_DIR)/lib
	touch $(PKG_BUILD_DIR)/.built

all: libssl

libssl-dirclean:
	rm -rf $(LIBSSL_DIR)

define Package/$(PKG_NAME)
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Libssl
  DESCRIPTION:=\
        A toolkit implementing SSL v2/v3 and TLS protocols with full-strength cryptography world-wide.
  URL:=http://www.openssl.org/
endef

#post installation - do nothing
define Package/$(PKG_NAME)/postinst
endef

#pre-remove
define Package/$(PKG_NAME)/prerm
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

libssl-package: libssl $(PACKAGE_DIR)/$(PKG_NAME)_$(VERSION)_$(PKGARCH).ipk
