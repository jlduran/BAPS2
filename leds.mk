#########################################################
# leds.mk for BAPs 
# David Rowe April 2008
#
# usage: make -f leds.mk leds
#
#########################################################

include rules.mk

LEDS_VERSION=0.1
LEDS_DIR=$(BUILD_DIR)/src/leds

TARGET_DIR=$(BUILD_DIR)/tmp/leds/ipkg/leds
PKG_NAME:=leds
PKG_VERSION:=$(LEDS_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/tmp/leds

MOD_DIR:=$(shell ls $(UCLINUX_DIST)/root/lib/modules)

leds: 
	make -C $(UCLINUX_DIST) SUBDIRS=$(LEDS_DIR) modules V=1

	rm -Rf $(TARGET_DIR)
	mkdir -p $(TARGET_DIR)/lib/modules/$(MOD_DIR)
	cp -f $(LEDS_DIR)/leds.ko $(TARGET_DIR)/lib/modules/$(MOD_DIR)
	mkdir -p $(TARGET_DIR)/usr/doc
	cp -v doc/leds.txt $(TARGET_DIR)/usr/doc
	touch $(PKG_BUILD_DIR)/.built

all: leds

dirclean:
	rm -rf $(LEDS_DIR)

define Package/$(PKG_NAME)
  SECTION:=net
  CATEGORY:=Utilities
  TITLE:=leds
  DESCRIPTION:=\
	Control SD and SYS LEDS from /proc on IP04
  URL:=http://rowetel.com/baps.html
endef

# post installation - add modules.dep entries
define Package/$(PKG_NAME)/postinst
#!/bin/sh
cd /lib/modules/$(MOD_DIR)
cat modules.dep | sed '/.*leds.ko:/ d' > modules.tmp
mv modules.tmp modules.dep
echo /lib/modules/$(MOD_DIR)/leds.ko: >> modules.dep

endef

# pre-remove - rm modules.dep entries
define Package/$(PKG_NAME)/prerm
#!/bin/sh
cd /lib/modules/$(MOD_DIR)
cat modules.dep | sed '/.*leds.ko:/ d' > modules.tmp
mv modules.tmp modules.dep
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

leds-package: leds $(PACKAGE_DIR)/$(PKG_NAME)_$(VERSION)_$(PKGARCH).ipk

