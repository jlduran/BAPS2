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
LIBSSL_VERSION=0.9.8d
LIBSSL_SOURCE=openssl-$(LIBSSL_VERSION).tar.gz
LIBSSL_UNZIP=zcat
UCLINUX_DIR=$(UCLINUX_DIST)

TARGET_DIR=$(BUILD_DIR)/tmp/libssl/ipkg/libssl
PKG_NAME:=libssl
PKG_VERSION:=$(LIBSSL_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/tmp/libssl


$(DL_DIR)/$(LIBSSL_SOURCE):
	$(WGET) -P $(DL_DIR) $(LIBSSL_SITE)/$(LIBSSL_SOURCE)

libssl-source: $(DL_DIR)/$(LIBSSL_SOURCE)

$(UCLINUX_DIR)/lib/libssl/.unpacked: $(DL_DIR)/$(LIBSSL_SOURCE)
	$(LIBSSL_UNZIP) $(DL_DIR)/$(LIBSSL_SOURCE) | tar -C $(UCLINUX_DIR)/lib $(TAR_OPTIONS) -
	touch $(UCLINUX_DIR)/lib/openssl-$(LIBSSL_VERSION)/.unpacked

$(UCLINUX_DIR)/lib/libssl/.configured: $(UCLINUX_DIR)/lib/libssl/.unpacked
	ln -sf $(UCLINUX_DIR)/lib/openssl-$(LIBSSL_VERSION)/ $(UCLINUX_DIR)/lib/libssl
	$(PATCH_KERNEL) $(UCLINUX_DIR) patch libssl.patch
	touch $(UCLINUX_DIR)/lib/libssl/.configured

libssl: $(UCLINUX_DIR)/lib/libssl/.configured
	make -C $(UCLINUX_DIR)/lib/libssl
	make -C $(UCLINUX_DIR)/lib/libssl STAGEDIR=$(STAGING_DIR) ROMFSDIR=$(UCLINUX_DIR)/root romfs
	rm -Rf $(TARGET_DIR)
	mkdir -p $(TARGET_DIR)/lib
	cp -f $(UCLINUX_DIR)/lib/libssl/libssl.so.0.9.8 $(TARGET_DIR)/lib
	cp -f $(UCLINUX_DIR)/lib/libssl/libcrypto.so.0.9.8 $(TARGET_DIR)/lib
	touch $(PKG_BUILD_DIR)/.built

all: libssl

libssl-clean:
	rm -rf $(UCLINUX_DIR)/lib/libssl

libssl-dirclean:
	rm -rf $(UCLINUX_DIR)/lib/libssl-$(LIBSSL_VERSION)
	rm $(UCLINUX_DIR)/lib/libssl

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
