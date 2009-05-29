# dnsmasq.mk
# Jose Luis Duran Apil 2009
#
# Dnsmasq is a lightweight, easy to configure DNS forwarder and DHCP
# server. It is designed to provide DNS, and optionally DHCP, to a small
# network. It can serve the names of local machines which are not in the
# global DNS. The DHCP server integrates with the DNS server and allows
# machines with DHCP-allocated addresses to appear in the DNS with names
# configured either in each host or in a central configuration file.
# Dnsmasq supports static and dynamic DHCP leases and BOOTP/TFTP for
# network booting of diskless machines.
#
# To make dnsmasq:
#   $ make -f dnsmasq.mk dnsmasq-package

include rules.mk

DNSMASQ_VERSION=2.47
DNSMASQ_SITE=http://thekelleys.org.uk/dnsmasq
DNSMASQ_SOURCE=dnsmasq-$(DNSMASQ_VERSION).tar.gz
DNSMASQ_DIR=$(BUILD_DIR)/dnsmasq-$(DNSMASQ_VERSION)

TARGET_DIR=$(BUILD_DIR)/tmp/dnsmasq/ipkg/dnsmasq
PKG_NAME:=dnsmasq
PKG_VERSION:=$(DNSMASQ_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/tmp/dnsmasq

#--------------------------------------------------------------------------
#                          DNSMASQ COMPILE OPTIONS
#                   Disable IPv6 & Read-only TFTP Server
#--------------------------------------------------------------------------

DNSMASQ_COPTS=-DNO_IPV6 -DNO_TFTP -DNO_LARGEFILE

#--------------------------------------------------------------------------

$(DL_DIR)/$(DNSMASQ_SOURCE):
	mkdir -p dl
	wget -P $(DL_DIR) $(DNSMASQ_SITE)/$(DNSMASQ_SOURCE)

$(DNSMASQ_DIR)/.unpacked: $(DL_DIR)/$(DNSMASQ_SOURCE)
	zcat $(DL_DIR)/$(DNSMASQ_SOURCE) | tar -C $(BUILD_DIR) -xf -
	touch $(DNSMASQ_DIR)/.unpacked

dnsmasq: $(DNSMASQ_DIR)/.unpacked
	make -C $(DNSMASQ_DIR) CC=bfin-linux-uclibc-gcc CFLAGS="$(TARGET_CFLAGS)" AWK=gawk\
                COPTS='$(DNSMASQ_COPTS)' PREFIX=/usr BINDIR=/sbin MANDIR=/usr/share/man\
                LOCALEDIR=/usr/share/locale DESTDIR=$(TARGET_DIR) install
	mkdir -p $(TARGET_DIR)/var/lib/misc
	mkdir -p $(TARGET_DIR)/etc/init.d
	rm -rf $(TARGET_DIR)/usr
	cp -f $(DNSMASQ_DIR)/dnsmasq.conf.example $(TARGET_DIR)/etc/dnsmasq.conf
	cp files/dnsmasq.init $(TARGET_DIR)/etc/init.d/dnsmasq
	chmod u+x $(TARGET_DIR)/etc/init.d/dnsmasq
	touch $(PKG_BUILD_DIR)/.built

#--------------------------------------------------------------------------
#                     USEFUL DNSMASQ MAKEFILE TARGETS     
#--------------------------------------------------------------------------

all: dnsmasq

dnsmasq-dirclean:
	rm -rf $(DNSMASQ_DIR)

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
  URL:=http://thekelleys.org.uk/dnsmasq/doc.html
endef

# post installation

define Package/$(PKG_NAME)/postinst
#!/bin/sh
/etc/init.d/dnsmasq enable
endef

# pre-remove
define Package/$(PKG_NAME)/prerm
#!/bin/sh
/etc/init.d/dnsmasq disable
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

dnsmasq-package: dnsmasq $(PACKAGE_DIR)/$(PKG_NAME)_$(VERSION)_$(PKGARCH).ipk

