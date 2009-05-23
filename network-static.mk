# network-static.mk 
# David Rowe April 2008
#
# usage: make -f network-static.mk network-static-package
#
# Trivial package for static network config
#
# see doc/network-static.txt

include rules.mk

TARGET_DIR=$(BUILD_DIR)/tmp/network-static/ipkg/network-static
PKG_NAME:=network-static
PKG_VERSION:=1
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/tmp/network-static

network-static: 
	mkdir -p $(TARGET_DIR)/etc/init.d
	cp files/network-static.init $(TARGET_DIR)/etc/init.d/network-static
	chmod u+x $(TARGET_DIR)/etc/init.d/network-static
	mkdir -p $(TARGET_DIR)/usr/doc
	cp doc/network-static.txt $(TARGET_DIR)/usr/doc/network-static.txt
	touch $(PKG_BUILD_DIR)/.built

all: network-static

dirclean:

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=network-static
  DESCRIPTION:=\
	Static (non-dhcp) network config scripts.
endef

# post installation

define Package/$(PKG_NAME)/postinst
#!/bin/sh
# switch off dhcp, switch on static
/etc/init.d/network disable
/etc/init.d/network-static enable
endef

# pre-remove
define Package/$(PKG_NAME)/prerm
#!/bin/sh
# back to dhcp
/etc/init.d/network-static disable
/etc/init.d/network enable
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

network-static-package: network-static $(PACKAGE_DIR)/$(PKG_NAME)_$(VERSION)_$(PKGARCH).ipk
