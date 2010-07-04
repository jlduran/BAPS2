# squid.mk
# Jose Luis Duran June 2009
#
# Squid is a caching proxy for the Web supporting HTTP, HTTPS, FTP, and more.
# It reduces bandwidth and improves response times by caching and reusing
# frequently-requested web pages. Squid has extensive access controls and
# makes a great server accelerator.
#
# To make squid:
#   $ make -f squid.mk squid-package

include rules.mk

SQUID_VERSION=2.7.STABLE9
SQUID_SITE=http://www.squid-cache.org/Versions/v2/2.7
SQUID_SOURCE=squid-$(SQUID_VERSION).tar.gz
SQUID_DIR=$(BUILD_DIR)/squid-$(SQUID_VERSION)

TARGET_DIR=$(BUILD_DIR)/tmp/squid/ipkg/squid
PKG_NAME:=squid
PKG_VERSION:=$(SQUID_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/tmp/squid

STAGING_INC=$(STAGING_DIR)/usr/include
SQUID_CFLAGS=-g -mfdpic -mfast-fp -ffast-math -D__FIXED_PT__ \
-D__BLACKFIN__ -I$(STAGING_INC)
SQUID_LDFLAGS=-mfdpic
SQUID_CONFIGURE_OPTS=--host=bfin-linux-uclibc --prefix=$(STAGING_DIR) \
CFLAGS="$(SQUID_CFLAGS)" LDFLAGS="$(SQUID_LDFLAGS)"

$(DL_DIR)/$(SQUID_SOURCE):
	mkdir -p dl
	wget -P $(DL_DIR) $(SQUID_SITE)/$(SQUID_SOURCE)

$(SQUID_DIR)/.unpacked: $(DL_DIR)/$(SQUID_SOURCE)
	tar -xvzf $(DL_DIR)/$(SQUID_SOURCE)
	touch $(SQUID_DIR)/.unpacked

$(SQUID_DIR)/.configured: $(SQUID_DIR)/.unpacked
	cd $(SQUID_DIR); ./configure $(SQUID_CONFIGURE_OPTS)
	touch $(SQUID_DIR)/.configured

squid: $(SQUID_DIR)/.configured
	cd $(SQUID_DIR); make
	make -C $(SQUID_DIR) CC=bfin-linux-uclibc-gcc \
		COPTS='' \
		BINDIR=/bin DESTDIR=$(TARGET_DIR) install
	#mkdir -p $(TARGET_DIR)/var/lib/misc
	#mkdir -p $(TARGET_DIR)/etc/init.d
	#rm -rf $(TARGET_DIR)/usr
	#cp -f $(SQUID_DIR)/squid.conf.example $(TARGET_DIR)/etc/squid.conf
	#cp files/squid.init $(TARGET_DIR)/etc/init.d/squid
	#chmod u+x $(TARGET_DIR)/etc/init.d/squid
	touch $(PKG_BUILD_DIR)/.built

all: squid

squid-dirclean:
	rm -rf $(SQUID_DIR)
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
  URL:=http://thekelleys.org.uk/squid/doc.html
endef

# post installation

define Package/$(PKG_NAME)/postinst
#!/bin/sh
/etc/init.d/squid enable
endef

# pre-remove
define Package/$(PKG_NAME)/prerm
#!/bin/sh
/etc/init.d/squid disable
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

squid-package: squid $(PACKAGE_DIR)/$(PKG_NAME)_$(VERSION)_$(PKGARCH).ipk

