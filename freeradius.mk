# freeradius.mk
# Jose Luis Duran June 2009
#
# Dnsmasq is a lightweight, easy to configure DNS forwarder and DHCP
# server. It is designed to provide DNS, and optionally DHCP, to a small
# network. It can serve the names of local machines which are not in the
# global DNS. The DHCP server integrates with the DNS server and allows
# machines with DHCP-allocated addresses to appear in the DNS with names
# configured either in each host or in a central configuration file.
# Dnsmasq supports static and dynamic DHCP leases and BOOTP/TFTP/PXE for
# network booting of diskless machines.
#
# To make freeradius:
#   $ make -f freeradius.mk freeradius-package

include rules.mk

FREERADIUS_VERSION=2.1.8
FREERADIUS_SITE=ftp://ftp.freeradius.org:/pub/freeradius
FREERADIUS_SOURCE=freeradius-server-$(FREERADIUS_VERSION).tar.gz
FREERADIUS_DIR=$(BUILD_DIR)/freeradius-server-$(FREERADIUS_VERSION)

TARGET_DIR=$(BUILD_DIR)/tmp/freeradius/ipkg/freeradius
PKG_NAME:=freeradius
PKG_VERSION:=$(FREERADIUS_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/tmp/freeradius

FREERADIUS_CPPFLAGS=-I$(FREERADIUS_BUILD_DIR)/src/include -I$(STAGING_INCLUDE_DIR)/mysql
FREERADIUS_LDFLAGS=-L$(STAGING_LIB_DIR)/mysql
FREERADIUS_CONFIG_ARGS = --without-rlm-sql-mysql \
	--with-rlm-sql-mysql-include-dir=$(STAGING_INCLUDE_DIR)/mysql \
	--with-rlm-sql-mysql-lib-dir=$(STAGING_LIB_DIR)/mysql

$(DL_DIR)/$(FREERADIUS_SOURCE):
	mkdir -p dl
	wget -P $(DL_DIR) $(FREERADIUS_SITE)/$(FREERADIUS_SOURCE)

$(FREERADIUS_DIR)/.unpacked: $(DL_DIR)/$(FREERADIUS_SOURCE)
	zcat $(DL_DIR)/$(FREERADIUS_SOURCE) | tar -C $(BUILD_DIR) -xf -
	touch $(FREERADIUS_DIR)/.unpacked

$(FREERADIUS_DIR)/.configured: $(FREERADIUS_DIR)/.unpacked
	cd $(FREERADIUS_DIR); ./configure $(FREERADIUS_CONFIGURE_OPTS)
	touch $(FREERADIUS_DIR)/.configured

freeradius: $(FREERADIUS_DIR)/.configured
	make -C $(FREERADIUS_DIR) CC=bfin-linux-uclibc-gcc \
		COPTS='$(FREERADIUS_COPTS)' \
		BINDIR=/bin DESTDIR=$(TARGET_DIR) install
	mkdir -p $(TARGET_DIR)/var/lib/misc
	mkdir -p $(TARGET_DIR)/etc/init.d
	rm -rf $(TARGET_DIR)/usr
	cp -f $(FREERADIUS_DIR)/freeradius.conf.example $(TARGET_DIR)/etc/freeradius.conf
	cp files/freeradius.init $(TARGET_DIR)/etc/init.d/freeradius
	chmod u+x $(TARGET_DIR)/etc/init.d/freeradius
	touch $(PKG_BUILD_DIR)/.built

all: freeradius

freeradius-dirclean:
	rm -rf $(FREERADIUS_DIR)
	rm -rf $(TOPDIR)/tmp/$(PKG_NAME)

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
	dynamic DHCP leases and BOOTP/TFTP/PXE for network booting of \\\
	diskless machines.
  URL:=http://thekelleys.org.uk/freeradius/doc.html
endef

# post installation

define Package/$(PKG_NAME)/postinst
#!/bin/sh
/etc/init.d/freeradius enable
endef

# pre-remove
define Package/$(PKG_NAME)/prerm
#!/bin/sh
/etc/init.d/freeradius disable
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

freeradius-package: freeradius $(PACKAGE_DIR)/$(PKG_NAME)_$(VERSION)_$(PKGARCH).ipk

