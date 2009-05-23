# busybox.mk
# David Rowe May 2008
#
# Package to install busybox utilities missing from the uImage.
# Bit messy but saves a reflash of uImage for one missing
# busybox utility.
#
# usage: make -f busybox.mk busybox-package
#
# NOTES:
# 1/ make help in the busybox directory was quite helpful
#    in working out how to automatically configure busybox.
# 2/ Use 'make menuconfig' to set any utilities you would
#    like, then copy the .config file to file/busybox.config
# 3/ The latest msh shell looks much improved, might be work
#    including this, e.g as /bin/msh.

include rules.mk

BUSYBOX_VERSION=1.10.1
BUSYBOX_DIRNAME=busybox-$(BUSYBOX_VERSION)
BUSYBOX_DIR=$(BUILD_DIR)/$(BUSYBOX_DIRNAME)
BUSYBOX_SITE=http://busybox.net/downloads/
BUSYBOX_SOURCE=busybox-$(BUSYBOX_VERSION).tar.bz2
BUSYBOX_UNZIP=bzcat

export CFLAGS = -I$(STAGING_DIR)/usr/include
export LDFLAGS = -L$(STAGING_DIR)/usr/lib

TARGET_DIR=$(BUILD_DIR)/tmp/busybox/ipkg/busybox
PKG_NAME:=busybox
PKG_VERSION:=$(BUSYBOX_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/tmp/busybox

$(DL_DIR)/$(BUSYBOX_SOURCE):
	$(WGET) -P $(DL_DIR) $(BUSYBOX_SITE)/$(BUSYBOX_SOURCE)

$(BUSYBOX_DIR)/.unpacked: $(DL_DIR)/$(BUSYBOX_SOURCE)
	$(BUSYBOX_UNZIP) $(DL_DIR)/$(BUSYBOX_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	touch $(BUSYBOX_DIR)/.unpacked

$(BUSYBOX_DIR)/.configured: $(BUSYBOX_DIR)/.unpacked
	cp files/busybox.config $(BUSYBOX_DIR)/.config
	touch $(BUSYBOX_DIR)/.configured

busybox: $(BUSYBOX_DIR)/.configured
	$(MAKE)	ARCH="$(ARCH)" CROSS_COMPILE=$(TARGET_CROSS) -C "$(BUSYBOX_DIR)" busybox

	mkdir -p $(TARGET_DIR)/bin
	cp $(BUSYBOX_DIR)/busybox $(TARGET_DIR)/bin/busybox-extra
	ln -sf busybox-extra $(TARGET_DIR)/bin/tr
	ln -sf busybox-extra $(TARGET_DIR)/bin/wc
	touch $(PKG_BUILD_DIR)/.built

all: busybox

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Extra busybox utilities
  DESCRIPTION:=\
        Additional busybox utilities not included in the default uImage.  Lets \
	you to install extra utilities without reflashing.
  URL:=http://busybox.net/
endef

# post installation

$(eval $(call BuildPackage,$(PKG_NAME)))

busybox-package: busybox $(PACKAGE_DIR)/$(PKG_NAME)_$(VERSION)_$(PKGARCH).ipk


