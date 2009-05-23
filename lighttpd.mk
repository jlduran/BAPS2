# lighttpd BAPS package by Mike Taht and David Rowe Feb 8 2008
#
# NOTES: 
#
# 1/ You may need to stop asterisk (or disable it's web server)
#    before starting lighttpd.

include rules.mk

LIGHTTPD_VERSION=1.4.18
LIGHTTPD_NAME=lighttpd-$(LIGHTTPD_VERSION)
LIGHTTPD_DIR=$(BUILD_DIR)/$(LIGHTTPD_NAME)
LIGHTTPD_SOURCE=$(LIGHTTPD_NAME).tar.gz
LIGHTTPD_SITE=http://www.lighttpd.net/download/
LIGHTTPD_UNZIP=zcat
TARGET_DIR=$(TOPDIR)/tmp/lighttpd/ipkg/lighttpd

PKG_NAME:=lighttpd
PKG_VERSION:=$(LIGHTTPD_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(TOPDIR)/tmp/lighttpd

STAGING_INC=$(STAGING_DIR)/usr/include
STAGING_LIB=$(STAGING_DIR)/usr/lib
LIGHTTPD_CONFIGURE_OPTS=--host=bfin-linux-uclibc --disable-ipv6 \
                        --prefix=$(TARGET_DIR)

$(DL_DIR)/$(LIGHTTPD_SOURCE):
	mkdir -p $(DL_DIR)
	$(WGET) -P $(DL_DIR) $(LIGHTTPD_SITE)/$(LIGHTTPD_SOURCE)

$(LIGHTTPD_DIR)/.unpacked: $(DL_DIR)/$(LIGHTTPD_SOURCE)
	$(LIGHTTPD_UNZIP) $(DL_DIR)/$(LIGHTTPD_SOURCE) | \
	tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	$(PATCH_KERNEL) $(LIGHTTPD_DIR) patch lighttpd.patch
	touch $(LIGHTTPD_DIR)/.unpacked

$(LIGHTTPD_DIR)/.configured: $(LIGHTTPD_DIR)/.unpacked
	cd $(LIGHTTPD_DIR); ./configure $(LIGHTTPD_CONFIGURE_OPTS)
	touch $(LIGHTTPD_DIR)/.configured

# this target useful when u just want to compile without install, e.g. to
# test a small tweak

lighttpd-build: $(LIGHTTPD_DIR)/.configured
	$(MAKE) -C $(LIGHTTPD_DIR)

lighttpd: lighttpd-build
	$(MAKE) -C $(LIGHTTPD_DIR) install

	# rm stuff we don't need

	cd $(TARGET_DIR); \
	rm -Rf bin lib/*.la sbin/lighttpd-angel var share

	# conf file

	mkdir -p $(TARGET_DIR)/etc
	cp files/lighttpd.conf $(TARGET_DIR)/etc

	# server root dir and test file

	mkdir -p $(TARGET_DIR)/www
	cp files/lighttpd.html $(TARGET_DIR)/www/index.html

	# init file

	mkdir -p $(TARGET_DIR)/etc/init.d
	cp files/lighttpd.init $(TARGET_DIR)/etc/init.d/lighttpd
	chmod a+x $(TARGET_DIR)/etc/init.d/lighttpd

	# doc

	mkdir -p $(TARGET_DIR)/usr/doc
	cp doc/lighttpd.txt $(TARGET_DIR)/usr/doc

	touch $(PKG_BUILD_DIR)/.built

all: lighttpd

distclean:
	rm -rf $(LIGHTTPD_BUILD_DIR)

#---------------------------------------------------------------------------
#                              CREATING PATCHES     
#---------------------------------------------------------------------------

# Generate patches between vanilla asterisk tar ball and our asterisk
# version.  Run this target after you have made any changes to
# asterisk to capture.

LO = lighttpd-$(LIGHTTPD_VERSION)-orig
L = lighttpd-$(LIGHTTPD_VERSION)

lighttpd-make-patch:

        # untar original, to save time we check if the orig is already there

	if [ ! -d $(LIGHTTPD_DIR)-orig ] ; then \
		cd $(DL_DIR); tar xzf $(LIGHTTPD_SOURCE); \
		mv $(L) $(LIGHTTPD_DIR)-orig; \
	fi

	# mmap MAP_SHARED -> MAP_PRIVATE

	-cd $(BUILD_DIR); diff -uN \
	$(LO)/src/stream.c \
	$(L)/src/stream.c \
	> $(PWD)/patch/lighttpd.patch

	-cd $(BUILD_DIR); diff -uN \
	$(LO)/src/network_writev.c \
	$(L)/src/network_writev.c \
	>> $(PWD)/patch/lighttpd.patch

	# make /var/www/html the server root, enable mod_cgi

	-cd $(BUILD_DIR); diff -uN \
	$(LO)/openwrt/lighttpd.conf \
	$(L)/openwrt/lighttpd.conf \
	>> $(PWD)/patch/lighttpd.patch

	# fork -> vfork to get mod CGI working

	-cd $(BUILD_DIR); diff -uN \
	$(LO)/src/mod_cgi.c \
	$(L)/src/mod_cgi.c \
	>> $(PWD)/patch/lighttpd.patch

#---------------------------------------------------------------------------
#                              CREATING PACKAGE
#---------------------------------------------------------------------------

define Package/lighttpd
  SECTION:=net
  CATEGORY:=Network
  TITLE:=lighttpd
  DESCRIPTION:=\
        Light web server with PHP support.
  URL:=http://www.lighttpd.net/
  ARCHITECTURE:=bfin-uclinux
endef

# post installation - add the sym link for auto start

define Package/lighttpd/postinst
#!/bin/sh
/etc/init.d/lighttpd enable
/etc/init.d/lighttpd start
endef

# pre-remove - remove sym link

define Package/lighttpd/prerm
#!/bin/sh
/etc/init.d/lighttpd disable
endef

$(eval $(call BuildPackage,lighttpd))

lighttpd-package: lighttpd $(PACKAGE_DIR)/lighttpd_$(VERSION)_$(PKGARCH).ipk
