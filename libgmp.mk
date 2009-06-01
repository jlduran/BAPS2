#########################################################
# libgmp.mk
#
# usage: make -f libgmp.mk libgmp-package 
#
#########################################################

include rules.mk

LIBGMP_SITE=ftp://ftp.gnu.org/gnu/gmp
LIBGMP_VERSION=4.3.1
LIBGMP_SOURCE=gmp-$(LIBGMP_VERSION).tar.gz
LIBGMP_DIR=$(BUILD_DIR)/gmp-$(LIBGMP_VERSION)
LIBGMP_CONFIGURE_OPTS=--host=bfin-linux-uclibc --prefix=$(TARGET_DIR) \
	--libdir=$(STAGING_DIR)/usr/lib

TARGET_DIR=$(BUILD_DIR)/tmp/libgmp/ipkg/libgmp
PKG_NAME:=libgmp
PKG_VERSION:=$(LIBGMP_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/tmp/libgmp

$(DL_DIR)/$(LIBGMP_SOURCE):
	$(WGET) -P $(DL_DIR) $(LIBGMP_SITE)/$(LIBGMP_SOURCE)

libgmp-source: $(DL_DIR)/$(LIBGMP_SOURCE)

$(LIBGMP_DIR)/.unpacked: $(DL_DIR)/$(LIBGMP_SOURCE)
	tar -zxf $(DL_DIR)/$(LIBGMP_SOURCE)
	touch $(LIBGMP_DIR)/.unpacked

$(LIBGMP_DIR)/.configured: $(LIBGMP_DIR)/.unpacked
	cd $(LIBGMP_DIR); ./configure $(LIBGMP_CONFIGURE_OPTS)
	#setup directories for package
	rm -Rf $(TARGET_DIR)
	mkdir -p $(TARGET_DIR)/lib
	touch $(LIBGMP_DIR)/.configured

libgmp: $(LIBGMP_DIR)/.configured
	make -C $(LIBGMP_DIR)
	make -C $(LIBGMP_DIR) install

	# NOTE --libdir option above means libs are automatically
	# installed in the staging dir, also means .la has correct
	# path to staging dir.  So now we set up libs on target:

	cp -f $(TARGET_DIR)/include/gmp.h $(STAGING_DIR)/usr/include
	rm -Rf $(TARGET_DIR)
	mkdir -p $(TARGET_DIR)/lib
	cp $(STAGING_DIR)/usr/lib/libgmp.so.3.5.0 $(TARGET_DIR)/lib
	ln -sf libgmp.so.3.5.0 $(TARGET_DIR)/lib/libgmp.so
	ln -sf libgmp.so.3.5.0 $(TARGET_DIR)/lib/libgmp.so.3

	$(STRIP) $(TARGET_DIR)/lib/libgmp.so.3.5.0

	touch $(PKG_BUILD_DIR)/.built

all: libgmp

libgmp-dirclean:
	rm -rf $(LIBGMP_DIR)


define Package/$(PKG_NAME)
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Libgmp
  DESCRIPTION:=\
	GNU MP is a portable library written in C for arbitrary precision \\\
	arithmetic on integers, rational numbers, and floating-point \\\
	numbers. It aims to provide the fastest possible arithmetic for \\\
	all applications that need higher precision than is directly \\\
	supported by the basic C types.
  URL:=http://www.gmplib.org/
endef

#post installation - do nothing
define Package/$(PKG_NAME)/postinst
endef

#pre-remove
define Package/$(PKG_NAME)/prerm
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

libgmp-package: libgmp $(PACKAGE_DIR)/$(PKG_NAME)_$(VERSION)_$(PKGARCH).ipk

