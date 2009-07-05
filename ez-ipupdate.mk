# ez-ipupdate.mk
# Jose Luis Duran April 2009
#
# ez-ipupdate is a small utility for updating your host name for any
# of the dynamic DNS service offered at:
# http://www.ez-ip.net
# http://www.justlinux.com
# http://www.dhs.org
# http://www.dyndns.org
# http://www.ods.org
# http://gnudip.cheapnet.net (GNUDip)
# http://www.dyn.ca (GNUDip)
# http://www.tzo.com
# http://www.easydns.com
# http://www.dyns.cx
# http://www.hn.org
# http://www.zoneedit.com
#
# To make ez-ipupdate:
#   $ make -f ez-ipupdate.mk ez-ipupdate-package

include rules.mk

EZIPUPDATE_NAME=ez-ipupdate
EZIPUPDATE_VERSION=3.0.11b8
EZIPUPDATE_SITE=http://ftp.debian.org/debian/pool/main/e/ez-ipupdate \
		http://ftp.de.debian.org/debian/pool/main/e/ez-ipupdate
EZIPUPDATE_SOURCE=$(EZIPUPDATE_NAME)_$(EZIPUPDATE_VERSION).orig.tar.gz
EZIPUPDATE_DIR=$(BUILD_DIR)/$(EZIPUPDATE_NAME)-$(EZIPUPDATE_VERSION)
EZIPUPDATE_CONFIGURE_OPTS=--host=bfin-linux-uclibc \
			--prefix=$(TARGET_DIR) \
			--libdir=$(STAGING_LIB)

TARGET_DIR=$(BUILD_DIR)/tmp/$(EZIPUPDATE_NAME)/ipkg/$(EZIPUPDATE_NAME)
PKG_NAME:=$(EZIPUPDATE_NAME)
PKG_VERSION:=$(EZIPUPDATE_VERSION)
PKG_RELEASE:=4
PKG_BUILD_DIR:=$(EZIPUPDATE_DIR)

STAGING_INC=$(STAGING_DIR)/usr/include
STAGING_LIB=$(STAGING_DIR)/usr/lib

$(DL_DIR)/$(EZIPUPDATE_SOURCE):
	mkdir -p dl
	wget -P $(DL_DIR) $(EZIPUPDATE_SITE)/$(EZIPUPDATE_SOURCE)

$(EZIPUPDATE_DIR)/.unpacked: $(DL_DIR)/$(EZIPUPDATE_SOURCE)
	zcat $(DL_DIR)/$(EZIPUPDATE_SOURCE) | tar -C $(BUILD_DIR) -xf -
	touch $(EZIPUPDATE_DIR)/.unpacked

$(EZIPUPDATE_DIR)/.configured: $(EZIPUPDATE_DIR)/.unpacked
	cd $(EZIPUPDATE_DIR); CC=bfin-linux-uclibc-gcc ./configure $(EZIPUPDATE_CONFIGURE_OPTS)
	touch $(EZIPUPDATE_DIR)/.configured

ez-ipupdate: $(EZIPUPDATE_DIR)/.configured
	make -C $(EZIPUPDATE_DIR) CC=bfin-linux-uclibc-gcc install
	mkdir -p $(TARGET_DIR)/etc/init.d
	cp -f $(EZIPUPDATE_DIR)/example-dyndns.conf $(TARGET_DIR)/etc/ez-ipupdate.conf
	cp -f files/ez-ipupdate.init $(TARGET_DIR)/etc/init.d/ez-ipupdate
	chmod u+x $(TARGET_DIR)/etc/init.d/ez-ipupdate
	$(TARGET_STRIP) $(TARGET_DIR)/bin/ez-ipupdate
	touch $(PKG_BUILD_DIR)/.built

all: ez-ipupdate

ez-ipupdate-dirclean:
	rm -rf $(EZIPUPDATE_DIR)
	rm -rf $(TOPDIR)/tmp/$(PKG_NAME)

#--------------------------------------------------------------------------
#                              CREATING PACKAGE    
#--------------------------------------------------------------------------

define Package/$(PKG_NAME)
  SECTION:=net
  CATEGORY:=Network
  TITLE:=ez-ipupdate
  DESCRIPTION:=\
        ez-ipupdate is a small utility for updating your host name for any \\\
	of the dynamic DNS service offered at: \\\
        http://www.ez-ip.net \\\
	http://www.justlinux.com \\\
	http://www.dhs.org \\\
	http://www.dyndns.org \\\
	http://www.ods.org \\\
	http://gnudip.cheapnet.net (GNUDip) \\\
	http://www.dyn.ca (GNUDip) \\\
	http://www.tzo.com \\\
	http://www.easydns.com \\\
	http://www.dyns.cx \\\
	http://www.hn.org \\\
	http://www.zoneedit.com
  URL:=http://www.ez-ipupdate.com
endef

# post installation

define Package/$(PKG_NAME)/postinst
#!/bin/sh
/etc/init.d/ez-ipupdate enable
endef

# pre-remove
define Package/$(PKG_NAME)/prerm
#!/bin/sh
/etc/init.d/ez-ipupdate disable
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

ez-ipupdate-package: ez-ipupdate $(PACKAGE_DIR)/$(PKG_NAME)_$(VERSION)_$(PKGARCH).ipk

