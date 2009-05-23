#########################################################
# wispcar.mk for BAPs 
# David Rowe May 2008
#
# usage: make -f wispcar.mk leds
#
#########################################################

include rules.mk

WISPCAR_VERSION=0.1

TARGET_DIR=$(BUILD_DIR)/tmp/wispcar/ipkg/wispcar
PKG_NAME:=wispcar
PKG_VERSION:=$(WISPCAR_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/tmp/wispcar

wispcar: 
	rm -Rf $(TARGET_DIR)
	mkdir -p $(TARGET_DIR)/bin
	cp -f src/wispcar src/wispcard $(TARGET_DIR)/bin
	chmod u+x $(TARGET_DIR)/bin/wispcard
	chmod u+x $(TARGET_DIR)/bin/wispcar
	mkdir -p $(TARGET_DIR)/etc/init.d
	cp -f files/wispcar.init $(TARGET_DIR)/etc/init.d/wispcar
	chmod u+x $(TARGET_DIR)/etc/init.d/wispcar
	mkdir -p $(TARGET_DIR)/usr/doc
	cp -v doc/wispcar.txt $(TARGET_DIR)/usr/doc
	touch $(PKG_BUILD_DIR)/.built

all: wispcar

dirclean:
	rm -rf $(WISPCAR_DIR)

define Package/$(PKG_NAME)
  SECTION:=net
  CATEGORY:=Utilities
  TITLE:=Wispcar - Wifi Station Power Controller And Reporter
  DESCRIPTION:=\
	Controls Wifi Station Power Controller And Reporter hardware     \
	which provide voltage and current monitoring, watchdog and sleep \
	timer functions.
  URL:=http://rowetel.com/baps.html
endef

# post installation - add modules.dep entries
define Package/$(PKG_NAME)/postinst
#!/bin/sh
/etc/init.d/wispcar enable
/etc/init.d/wispcar start
endef

# pre-remove - rm modules.dep entries
define Package/$(PKG_NAME)/prerm
#!/bin/sh
/etc/init.d/wispcar stop
/etc/init.d/wispcar disable
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

wispcar-package: wispcar $(PACKAGE_DIR)/$(PKG_NAME)_$(VERSION)_$(PKGARCH).ipk

