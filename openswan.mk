# openswan.mk
# Jose Luis Duran June 2009
#
# To make openswan:
#   $ make -f openswan.mk openswan-package

include rules.mk

OPENSWAN_VERSION=2.6.21
OPENSWAN_SITE=http://www.openswan.org/download
OPENSWAN_SOURCE=openswan-$(OPENSWAN_VERSION).tar.gz
OPENSWAN_DIR=$(BUILD_DIR)/openswan-$(OPENSWAN_VERSION)

TARGET_DIR=$(BUILD_DIR)/tmp/openswan/ipkg/openswan
PKG_NAME:=openswan
PKG_VERSION:=$(OPENSWAN_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/tmp/openswan

STAGING_INC=$(STAGING_DIR)/usr/include
STAGING_LIB=$(STAGING_DIR)/usr/lib
OPENSWAN_CFLAGS=-mfdpic -I$(STAGING_INC)
OPENSWAN_LDFLAGS=-L$(STAGING_LIB)
OPENSWAN_COPTS=CFLAGS="$(OPENSWAN_CFLAGS)" LDFLAGS="$(OPENSWAN_LDFLAGS)" KERNELSRC=$(BUILD_DIR)/uClinux-dist/linux-2.6.x

$(DL_DIR)/$(OPENSWAN_SOURCE):
	mkdir -p dl
	wget -P $(DL_DIR) $(OPENSWAN_SITE)/$(OPENSWAN_SOURCE)

$(OPENSWAN_DIR)/.unpacked: $(DL_DIR)/$(OPENSWAN_SOURCE)
	zcat $(DL_DIR)/$(OPENSWAN_SOURCE) | tar -C $(BUILD_DIR) -xf -
	touch $(OPENSWAN_DIR)/.unpacked

openswan: $(OPENSWAN_DIR)/.unpacked
	make -C $(OPENSWAN_DIR) CC=bfin-linux-uclibc-gcc AR=bfin-linux-uclibc-ar $(OPENSWAN_COPTS) module minstall programs install
#	mkdir -p $(TARGET_DIR)/var/lib/misc
#	mkdir -p $(TARGET_DIR)/etc/init.d
#	rm -rf $(TARGET_DIR)/usr
#	cp -f $(OPENSWAN_DIR)/openswan.conf.example $(TARGET_DIR)/etc/openswan.conf
#	cp files/openswan.init $(TARGET_DIR)/etc/init.d/openswan
#	chmod u+x $(TARGET_DIR)/etc/init.d/openswan
	touch $(PKG_BUILD_DIR)/.built

all: openswan

openswan-dirclean:
	rm -rf $(OPENSWAN_DIR)

#--------------------------------------------------------------------------
#                              CREATING PACKAGE    
#--------------------------------------------------------------------------

define Package/$(PKG_NAME)
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Dnsmasq
  DESCRIPTION:=\
	Dnsmasq is a lightweight, easy to configure DNS forwarder and \\\
	DHCP server. It is designed to provide DNS, and optionally DHCP, \\\
	to a small network. It can serve the names of local machines \\\
	which are not in the global DNS. The DHCP server integrates with \\\
	the DNS server and allows machines with DHCP-allocated addresses \\\
	to appear in the DNS with names configured either in each host \\\
	or in a central configuration file. Dnsmasq supports static and \\\
	dynamic DHCP leases and BOOTP/TFTP for network booting of \\\
	diskless machines.
  URL:=http://thekelleys.org.uk/openswan/doc.html
endef

# post installation

define Package/$(PKG_NAME)/postinst
#!/bin/sh
/etc/init.d/openswan enable
endef

# pre-remove
define Package/$(PKG_NAME)/prerm
#!/bin/sh
/etc/init.d/openswan disable
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

openswan-package: openswan $(PACKAGE_DIR)/$(PKG_NAME)_$(VERSION)_$(PKGARCH).ipk

