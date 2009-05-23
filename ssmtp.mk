########################################################
# ssmtp with ssl support for uClinux and Asterisk, 
# Ming C.(Vincent) Li Feb 2009
#
# make -f libssl.mk libssl-package
# make -f ssmtp.mk ssmtp-package 
#
# Run after "make -f libssl.mk libssl"
#########################################################

include rules.mk

SSMTP_SITE=http://ftp.de.debian.org/debian/pool/main/s/ssmtp
SSMTP_VERSION=2.62
SSMTP_SOURCE=ssmtp_$(SSMTP_VERSION).orig.tar.gz
SSMTP_UNZIP=zcat
SSMTP_DIR=$(BUILD_DIR)/ssmtp
		   
TARGET_DIR=$(BUILD_DIR)/tmp/ssmtp/ipkg/ssmtp
PKG_NAME:=ssmtp
PKG_VERSION:=$(SSMTP_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/tmp/ssmtp

STAGING_INC=$(STAGING_DIR)/usr/include
STAGING_LIB=$(STAGING_DIR)/usr/lib

export CFLAGS = -I$(STAGING_DIR)/usr/include
export LDFLAGS = -L$(STAGING_DIR)/usr/lib
export CC=bfin-linux-uclibc-gcc 

SSMTP_CONFIGURE_OPTS=--host=bfin-linux-uclibc \
			--target=bfin-linux-uclibc \
			--enable-ssl \
			--libdir=$(LDFLAGS) \
		       --prefix=/

$(DL_DIR)/$(SSMTP_SOURCE):
	$(WGET) -P $(DL_DIR) $(SSMTP_SITE)/$(SSMTP_SOURCE)


$(SSMTP_DIR)/.unpacked: $(DL_DIR)/$(SSMTP_SOURCE)
	$(SSMTP_UNZIP) $(DL_DIR)/$(SSMTP_SOURCE) | \
        tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	$(PATCH_KERNEL) $(SSMTP_DIR) patch ssmtp.patch

	touch $(SSMTP_DIR)/.unpacked

$(SSMTP_DIR)/.configured: $(SSMTP_DIR)/.unpacked
	cd $(SSMTP_DIR); \
	./configure $(SSMTP_CONFIGURE_OPTS)
	touch $(SSMTP_DIR)/.configured

ssmtp: $(SSMTP_DIR)/.configured
	$(MAKE) -C $(SSMTP_DIR) 

	rm -Rf $(TARGET_DIR)
	mkdir -p $(TARGET_DIR)
	mkdir -p $(TARGET_DIR)/bin
	mkdir -p $(TARGET_DIR)/etc/ssmtp
	cp -v $(SSMTP_DIR)/ssmtp $(TARGET_DIR)/bin/
	cp -v $(SSMTP_DIR)/ssmtp.conf $(TARGET_DIR)/etc/ssmtp/
	mkdir -p $(TARGET_DIR)/usr/doc
	cp -v doc/ssmtp.txt $(TARGET_DIR)/usr/doc


	touch $(PKG_BUILD_DIR)/.built



all: ssmtp

dirclean:
	rm -rf $(SSMTP_DIR)


#---------------------------------------------------------------------------
#                              CREATING PACKAGE
#---------------------------------------------------------------------------

define Package/ssmtp
  SECTION:=network
  CATEGORY:=Applications
  TITLE:=SSMTP
  DEPENDS:=libssl
  DESCRIPTION:=\
        extremely simple MTA to get mail off the system to a mail hub
  URL:=http://ftp.de.debian.org/debian/pool/main/s/ssmtp/ssmtp_2.62.orig.tar.gz
  ARCHITECTURE:=bfin-uclinux

endef

# post installation - add the sym link for auto start

define Package/ssmtp/postinst
#!/bin/sh
endef

# pre-remove - remove sym link

define Package/ssmtp/prerm
#!/bin/sh
rm -rf /bin/ssmtp
endef

$(eval $(call BuildPackage,ssmtp))

ssmtp-package: ssmtp $(PACKAGE_DIR)/ssmtp_$(VERSION)_$(PKGARCH).ipk

