#########################################################
# libiconv.mk
# David Rowe March 2008
#
# usage: make -f libiconv.mk libiconv-package 
#
# Required for PHP to ./configure OK, but doesn't seem to be
# required at run time.  Perhaps PHP links with the static
# lib, not sure.  It get errors from PHP build re the
# the inconv.h if this is not built.
#
#########################################################

include rules.mk

LIBICONV_SITE=http://ftp.gnu.org/pub/gnu/libiconv/
LIBICONV_VERSION=1.12
LIBICONV_SOURCE=libiconv-$(LIBICONV_VERSION).tar.gz
LIBICONV_UNZIP=zcat
LIBICONV_DIR=$(BUILD_DIR)/libiconv-$(LIBICONV_VERSION)
LIBICONV_CONFIGURE_OPTS=--host=bfin-linux-uclibc --enable-shared \
                --disable-rpath --prefix=$(TARGET_DIR)

TARGET_DIR=$(BUILD_DIR)/tmp/libiconv/ipkg/libiconv
PKG_NAME:=libiconv
PKG_VERSION:=$(LIBICONV_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/tmp/libiconv

$(DL_DIR)/$(LIBICONV_SOURCE):
	$(WGET) -P $(DL_DIR) $(LIBICONV_SITE)/$(LIBICONV_SOURCE)

libiconv-source: $(DL_DIR)/$(LIBICONV_SOURCE)

$(LIBICONV_DIR)/.unpacked: $(DL_DIR)/$(LIBICONV_SOURCE)
	tar -xzvf $(DL_DIR)/$(LIBICONV_SOURCE)
	touch $(LIBICONV_DIR)/.unpacked

$(LIBICONV_DIR)/.configured: $(LIBICONV_DIR)/.unpacked
	cd $(LIBICONV_DIR); ./configure $(LIBICONV_CONFIGURE_OPTS)
	#setup directories for package
	rm -Rf $(TARGET_DIR)
	mkdir -p $(TARGET_DIR)/lib
	touch $(LIBICONV_DIR)/.configured

libiconv: $(LIBICONV_DIR)/.configured
	make -C $(LIBICONV_DIR)
	make -C $(LIBICONV_DIR) install

	cp $(TARGET_DIR)/include/* $(STAGING_DIR)/usr/include
	cp $(TARGET_DIR)/lib/* $(STAGING_DIR)/usr/lib

	rm -Rf $(TARGET_DIR)/bin
	rm -Rf $(TARGET_DIR)/share
	rm -Rf $(TARGET_DIR)/include

	touch $(PKG_BUILD_DIR)/.built

all: libiconv

dirclean:
	rm -rf $(LIBICONV_DIR)


define Package/$(PKG_NAME)
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=Character set conversion library
  URL:=http://www.gnu.org/software/libiconv/
endef

#post installation - do nothing
define Package/$(PKG_NAME)/postinst
endef

#pre-remove
define Package/$(PKG_NAME)/prerm
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

libiconv-package: libiconv $(PACKAGE_DIR)/$(PKG_NAME)_$(VERSION)_$(PKGARCH).ipk

