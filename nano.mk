# nano package
# Nick Basil April 2008
#
# usage: make -f nano.mk nano-package 
#

include rules.mk

NANO_VERSION=2.1.1
NANO_NAME=nano
NANO_DIR=$(BUILD_DIR)/$(NANO_NAME)-$(NANO_VERSION)
NANO_SOURCE=$(NANO_NAME)-$(NANO_VERSION).tar.gz
NANO_SITE=http://www.nano-editor.org/dist/v2.1
TARGET_DIR=$(TOPDIR)/tmp/$(NANO_NAME)/ipkg/$(NANO_NAME)

CFLAGS="CFLAGS=-I$(STAGING_DIR)/usr/include"
LDFLAGS="LDFLAGS=-L$(STAGING_DIR)/usr/lib"
CONFIGURE_OPTS=$(CFLAGS) $(LDFLAGS) --host=bfin-linux-uclibc

PKG_NAME=nano
PKG_VERSION=$(NANO_VERSION)
PKG_RELEASE=1
PKG_BUILD_DIR:=$(TOPDIR)/tmp/nano

$(DL_DIR)/$(NANO_SOURCE):
	mkdir -p $(DL_DIR)
	$(WGET) -P $(DL_DIR) $(NANO_SITE)/$(NANO_SOURCE)

$(NANO_DIR)/.unpacked: $(DL_DIR)/$(NANO_SOURCE)
	tar -xzvf $(DL_DIR)/$(NANO_SOURCE)
	touch $(NANO_DIR)/.unpacked

$(NANO_DIR)/.configured: $(NANO_DIR)/.unpacked
	cd $(NANO_DIR); ./configure $(CONFIGURE_OPTS)
	touch $(NANO_DIR)/.configured
  
nano: $(NANO_DIR)/.configured
	cd $(NANO_DIR); make
	mkdir -p $(TARGET_DIR)/bin
	cp $(NANO_DIR)/src/nano $(TARGET_DIR)/bin/nano 
	touch $(PKG_BUILD_DIR)/.built

all: nano

# PACKAGE DEFINITION
define Package/nano
  SECTION=editor
  CATEGORY=EDITOR
  TITLE=nano editor
  DESCRIPTION=\
    basic text editor
  URL=http://www.nano-editor.org/
endef

# PACKAGE POST-INST
define Package/$(PKG_NAME)/postinst
endef

# PACKAGE PRE-REMOVE
define Package/$(PKG_NAME)/prerm
endef

$(eval $(call BuildPackage,nano))

nano-package: nano $(PACKAGE_DIR)/$(PKG_NAME)_$(VERSION)_$(PKGARCH).ipk

