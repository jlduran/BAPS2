#####################################################
# libxml for the Blackfin
# Based on Astfin2 libxml.mk
#####################################################

include rules.mk

LIBXML_SITE=ftp://xmlsoft.org/libxml2
LIBXML_VERSION=2.7.3
LIBXML_SOURCE=libxml2-sources-$(LIBXML_VERSION).tar.gz
LIBXML_UNZIP=zcat
LIBXML_CONFIGURE_OPTS=--host=bfin-linux-uclibc --build=i686-linux \
                      --without-python --prefix=$(TARGET_DIR) \
		      --libdir=$(STAGING_DIR)/usr/lib
	              
LIBXML_DIR=$(BUILD_DIR)/libxml2-$(LIBXML_VERSION)

TARGET_DIR=$(BUILD_DIR)/tmp/libxml/ipkg/libxml
PKG_NAME:=libxml
PKG_VERSION:=$(LIBXML_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/tmp/libxml

export CC=bfin-linux-uclibc-gcc

$(DL_DIR)/$(LIBXML_SOURCE):
	$(WGET) -P $(DL_DIR) $(LIBXML_SITE)/$(LIBXML_SOURCE)

libxml-source: $(DL_DIR)/$(LIBXML_SOURCE)

$(LIBXML_DIR)/.unpacked: $(DL_DIR)/$(LIBXML_SOURCE)
	$(LIBXML_UNZIP) $(DL_DIR)/$(LIBXML_SOURCE) | \
	tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	touch $(LIBXML_DIR)/.unpacked

$(LIBXML_DIR)/.configured: $(LIBXML_DIR)/.unpacked
	export CC=bfin-linux-uclibc-gcc
	cd $(LIBXML_DIR); ./configure $(LIBXML_CONFIGURE_OPTS)
	touch $(LIBXML_DIR)/.configured

libxml: $(LIBXML_DIR)/.configured
	make -C $(LIBXML_DIR)
	make -C $(LIBXML_DIR) install

	# NOTE --libdir option above means libs are automatically
	# installed in the staging dir, also means .la has correct
	# path to staging dir.  So now we set up libs on target:

	rm -Rf $(TARGET_DIR)
	mkdir -p $(TARGET_DIR)/lib
	cp $(STAGING_DIR)/usr/lib/libxml2.so.2.7.3 $(TARGET_DIR)/lib
	ln -sf libxml2.so.2.7.3 $(TARGET_DIR)/lib/libxml2.so
	ln -sf libxml2.so.2.7.3 $(TARGET_DIR)/lib/libxml2.so.2

	# strip is very effective - reduces .so size from 3M to 1M

	$(STRIP) $(TARGET_DIR)/lib/libxml2.so.2.7.3

	# remove other junk to save room on target
	cd $(TARGET_DIR); rm -Rf bin include share

	touch $(PKG_BUILD_DIR)/.built

all: libxml

libxml-dirclean:
	rm -rf $(LIBXML_DIR)

define Package/libxml
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=Gnome XML library
  DESCRIPTION:=\
        A library for manipulating XML and HTML resources.
  URL:=http://xmlsoft.org/
endef


#post installation - do nothing
define Package/$(PKG_NAME)/postinst
endef

#pre-remove
define Package/$(PKG_NAME)/prerm
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

libxml-package: libxml $(PACKAGE_DIR)/$(PKG_NAME)_$(VERSION)_$(PKGARCH).ipk

