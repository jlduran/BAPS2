# pagecache.mk 
# David Rowe March 2008
#
# usage: make -f pagecache.mk pagecache-package
#
# Trivial package to set pagecahce_ratio on start up.
#
# see doc/pagecache.txt

include rules.mk

TARGET_DIR=$(BUILD_DIR)/tmp/pagecache/ipkg/pagecache
PKG_NAME:=pagecache
PKG_VERSION:=1
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/tmp/pagecache

pagecache: 
	mkdir -p $(TARGET_DIR)/etc/init.d
	cp files/pagecache.init $(TARGET_DIR)/etc/init.d/pagecache
	chmod u+x $(TARGET_DIR)/etc/init.d/pagecache
	touch $(PKG_BUILD_DIR)/.built

all: pagecache

dirclean:

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Sets pagecache_ratio to preserve memory
  DESCRIPTION:=\
	Reduces the amount of memory available for file buffering \\\
	freeing this memory for system use.
endef

# post installation

define Package/$(PKG_NAME)/postinst
#!/bin/sh
/etc/init.d/pagecache enable
/etc/init.d/pagecache start
endef

# pre-remove
define Package/$(PKG_NAME)/prerm
/etc/init.d/pagecache disable
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

pagecache-package: pagecache $(PACKAGE_DIR)/$(PKG_NAME)_$(VERSION)_$(PKGARCH).ipk
