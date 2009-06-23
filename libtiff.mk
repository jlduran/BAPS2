#########################################################
# libtiff for uClinux and Asterisk, 
# Jeff Knighton Feb 2008
#
# usage: make -f libtiff.mk libtiff-package 
#
# Run after building uClinux-dist, copies shared libs to
# uClinux-dist/staging, ready for use in Asterisk if 
# required.
#########################################################

include rules.mk

LIBTIFF_SITE=http://dl.maptools.org/dl/libtiff
LIBTIFF_VERSION=3.8.2
LIBTIFF_SOURCE=tiff-3.8.2.tar.gz
LIBTIFF_DIR=$(BUILD_DIR)/tiff-$(LIBTIFF_VERSION)
LIBTIFF_CONFIGURE_OPTS=--host=bfin-linux-uclibc

TARGET_DIR=$(BUILD_DIR)/tmp/libtiff/ipkg/libtiff
PKG_NAME:=libtiff
PKG_VERSION:=$(LIBTIFF_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/tmp/libtiff

$(DL_DIR)/$(LIBTIFF_SOURCE):
	$(WGET) -P $(DL_DIR) $(LIBTIFF_SITE)/$(LIBTIFF_SOURCE)

libtiff-source: $(DL_DIR)/$(LIBTIFF_SOURCE)

$(LIBTIFF_DIR)/.unpacked: $(DL_DIR)/$(LIBTIFF_SOURCE)
	tar -xzvf $(DL_DIR)/$(LIBTIFF_SOURCE)
	touch $(LIBTIFF_DIR)/.unpacked

$(LIBTIFF_DIR)/.configured: $(LIBTIFF_DIR)/.unpacked
	cd $(LIBTIFF_DIR); ./configure $(LIBTIFF_CONFIGURE_OPTS)
	#setup directories for package
	touch $(LIBTIFF_DIR)/.configured

libtiff: $(LIBTIFF_DIR)/.configured
	make -C $(LIBTIFF_DIR)/ STAGEDIR=$(STAGING_DIR)
	cp -f $(LIBTIFF_DIR)/libtiff/.libs/libtiff* $(STAGING_DIR)/usr/lib/

	#copy to package location
	rm -Rf $(TARGET_DIR)
	mkdir -p $(TARGET_DIR)/lib
	cp -f $(LIBTIFF_DIR)/libtiff/.libs/libtiff.so.3 $(TARGET_DIR)/lib
	$(TARGET_STRIP) $(TARGET_DIR)/lib/libtiff.so.3
	cd $(TARGET_DIR)/lib/; ln -sf libtiff.so.3 libtiff.so
	touch $(PKG_BUILD_DIR)/.built

all: libtiff

libtiff-dirclean:
	rm -rf $(LIBTIFF_DIR)


define Package/$(PKG_NAME)
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Libtiff
  DESCRIPTION:=\
	Tiff image file format library.
  URL:=http://www.libtiff.org
endef

#post installation - do nothing
define Package/$(PKG_NAME)/postinst
endef

#pre-remove
define Package/$(PKG_NAME)/prerm
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

libtiff-package: libtiff $(PACKAGE_DIR)/$(PKG_NAME)_$(VERSION)_$(PKGARCH).ipk

