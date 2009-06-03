# strongswan.mk
# Jose Luis Duran June 2009
#
# To make strongswan:
#   $ make -f strongswan.mk strongswan-package

include rules.mk

STRONGSWAN_VERSION=4.3.1
STRONGSWAN_SITE=http://download.strongswan.org
STRONGSWAN_SOURCE=strongswan-$(STRONGSWAN_VERSION).tar.gz
STRONGSWAN_DIR=$(BUILD_DIR)/strongswan-$(STRONGSWAN_VERSION)

TARGET_DIR=$(BUILD_DIR)/tmp/strongswan/ipkg/strongswan
PKG_NAME:=strongswan
PKG_VERSION:=$(STRONGSWAN_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/tmp/strongswan

#--------------------------------------------------------------------------
#                          STRONGSWAN COMPILE OPTIONS
#                   Disable IPv6 & Read-only TFTP Server
#--------------------------------------------------------------------------

STRONGSWAN_CONFIGURE_OPTS=--host=bfin-linux-uclibc --prefix=$(TARGET_DIR) \
#		--libdir=$(STAGING_DIR)/usr/lib --includedir=$(STAGING_DIR)/usr/include \
		--disable-ldap

#--------------------------------------------------------------------------

$(DL_DIR)/$(STRONGSWAN_SOURCE):
	mkdir -p dl
	wget -P $(DL_DIR) $(STRONGSWAN_SITE)/$(STRONGSWAN_SOURCE)

$(STRONGSWAN_DIR)/.unpacked: $(DL_DIR)/$(STRONGSWAN_SOURCE)
	zcat $(DL_DIR)/$(STRONGSWAN_SOURCE) | tar -C $(BUILD_DIR) -xf -
	touch $(STRONGSWAN_DIR)/.unpacked

strongswan: $(STRONGSWAN_DIR)/.unpacked
	cd $(STRONGSWAN_DIR); ./configure $(STRONGSWAN_CONFIGURE_OPTS)
	make -C $(STRONGSWAN_DIR)
	make -C $(STRONGSWAN_DIR) install
#	mkdir -p $(TARGET_DIR)/var/lib/misc
#	mkdir -p $(TARGET_DIR)/etc/init.d
#	rm -rf $(TARGET_DIR)/usr
#	cp -f $(STRONGSWAN_DIR)/strongswan.conf.example $(TARGET_DIR)/etc/strongswan.conf
#	cp files/strongswan.init $(TARGET_DIR)/etc/init.d/strongswan
#	chmod u+x $(TARGET_DIR)/etc/init.d/strongswan
	touch $(PKG_BUILD_DIR)/.built

all: strongswan

strongswan-dirclean:
	rm -rf $(STRONGSWAN_DIR)

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
  URL:=http://thekelleys.org.uk/strongswan/doc.html
endef

# post installation

define Package/$(PKG_NAME)/postinst
#!/bin/sh
/etc/init.d/strongswan enable
endef

# pre-remove
define Package/$(PKG_NAME)/prerm
#!/bin/sh
/etc/init.d/strongswan disable
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

strongswan-package: strongswan $(PACKAGE_DIR)/$(PKG_NAME)_$(VERSION)_$(PKGARCH).ipk

