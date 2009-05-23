#########################################################
# libcurl for uClinux and Asterisk, 
# Keith Huang Feb 2008
# SSL supported added by Nick Basil Sep 2008
# 
# usage: make -f libcurl.mk libcurl-package 
#
# Run after building uClinux-dist, copies shared libs to
# uClinux-dist/staging, ready for use in Asterisk if 
# required.
#
# Requires libssl (make -f libssl.mk libssl) which transfers 
# libcrypto and libssl to the staging area.
#
#########################################################

include rules.mk

LIBCURL_SITE=http://curl.haxx.se/download
LIBCURL_VERSION=7.18.0
LIBCURL_SOURCE=curl-7.18.0.tar.gz
LIBCURL_UNZIP=zcat
LIBCURL_DIR=$(BUILD_DIR)/curl-$(LIBCURL_VERSION)
LIBCURL_CFLAGS="CFLAGS=-I$(STAGING_DIR)/usr/include" 
LIBCURL_LDFLAGS="LDFLAGS=-L$(STAGING_DIR)/usr/lib -lcrypto -lssl"
LIBCURL_CONFIGURE_OPTS=--host=bfin-linux-uclibc \
		--prefix=$(TARGET_DIR) \
		--disable-nls \
		--without-libidn \
		--disable-ldap \
    --disable-ipv6 \
    --without-ca-path \
    --without-ca-bundle \
		--with-random="/dev/urandom" 
    
TARGET_DIR=$(BUILD_DIR)/tmp/libcurl/ipkg/libcurl
PKG_NAME:=libcurl
PKG_VERSION:=$(LIBCURL_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/tmp/libcurl

$(DL_DIR)/$(LIBCURL_SOURCE):
	$(WGET) -P $(DL_DIR) $(LIBCURL_SITE)/$(LIBCURL_SOURCE)

libcurl-source: $(DL_DIR)/$(LIBCURL_SOURCE)

$(LIBCURL_DIR)/.unpacked: $(DL_DIR)/$(LIBCURL_SOURCE)
	tar -xzvf $(DL_DIR)/$(LIBCURL_SOURCE)
	touch $(LIBCURL_DIR)/.unpacked

$(LIBCURL_DIR)/.configured: $(LIBCURL_DIR)/.unpacked
	cd $(LIBCURL_DIR); ./configure $(LIBCURL_CONFIGURE_OPTS) $(LIBCURL_CFLAGS) $(LIBCURL_LDFLAGS)
	#setup directories for package
	rm -Rf $(TARGET_DIR)
	mkdir -p $(TARGET_DIR)/lib
	mkdir -p $(TARGET_DIR)/bin
	touch $(LIBCURL_DIR)/.configured

libcurl: $(LIBCURL_DIR)/.configured
	make -C $(LIBCURL_DIR)/ STAGEDIR=$(STAGING_DIR) 

	cp -f $(LIBCURL_DIR)/src/.libs/curl* $(TARGET_DIR)/bin

	#copy tp package location
	cp -f $(LIBCURL_DIR)/lib/.libs/libcurl.so.4 $(TARGET_DIR)/lib

	cp -f $(STAGING_DIR)/usr/lib/libcrypto.so.0.9.8 $(TARGET_DIR)/lib
	cp -f $(STAGING_DIR)/usr/lib/libssl.so.0.9.8 $(TARGET_DIR)/lib

	touch $(PKG_BUILD_DIR)/.built

all: libcurl

dirclean:
	rm -rf $(LIBCURL_DIR)


define Package/$(PKG_NAME)
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Libcurl
  DESCRIPTION:=\
	Curl is a command line tool for transferring files with URL syntax,\
supporting FTP, FTPS, HTTP, HTTPS, GOPHER, TELNET, DICT, FILE and LDAP.\
Curl supports HTTPS certificates, HTTP POST, HTTP PUT, FTP uploading, kerberos,\ HTTP form based upload, proxies, cookies, user+password authentication,\
 file transfer resume, http proxy tunneling and a busload of other useful\
 tricks.
LIBCURL_SECTION=libs
  URL:=http://www.libcurl.org
endef

#post installation - do nothing
define Package/$(PKG_NAME)/postinst
endef

#pre-remove
define Package/$(PKG_NAME)/prerm
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

libcurl-package: libcurl $(PACKAGE_DIR)/$(PKG_NAME)_$(VERSION)_$(PKGARCH).ipk

