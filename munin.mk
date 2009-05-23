# munin.mk 
# David Rowe March 2008
# Thanks Michael O'Conner for suggesting Munin and providing
# the prototype munin-node script
#
# usage: make -f munin.mk munin-package
#
# BAPS package to install a munin node on a Blackfin system.
#
# see doc/munin.txt

include rules.mk

TARGET_DIR=$(BUILD_DIR)/tmp/munin/ipkg/munin
PKG_NAME:=munin
PKG_VERSION:=1
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/tmp/munin

munin: 
	mkdir -p $(TARGET_DIR)/etc/munin/plugins
	mkdir -p $(TARGET_DIR)/etc/munin/plugins-shared
	cp src/munin/munin-node.sh $(TARGET_DIR)/etc/munin/
	chmod u+x $(TARGET_DIR)/etc/munin/munin-node.sh
	cp src/munin/plugins/* $(TARGET_DIR)/etc/munin/plugins
	chmod u+x $(TARGET_DIR)/etc/munin/plugins/*
	cp src/munin/plugins-shared/* $(TARGET_DIR)/etc/munin/plugins-shared
	chmod u+x $(TARGET_DIR)/etc/munin/plugins-shared/*
	find $(TARGET_DIR)/etc/munin/ -name '*~' | xargs rm -f
	ln -sf /etc/munin/plugins-shared/if_ $(TARGET_DIR)/etc/munin/plugins/if_eth0
	touch $(PKG_BUILD_DIR)/.built

all: munin

dirclean:

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Munin node
  DESCRIPTION:=\
        Munin node and plugins for remote data logging from Blackfin	  \
        systems.  Monitor a network of IP04s and graph  \
        the results with a small amount of configuration.  Easy to set up \
        and customise.
endef

# post installation

define Package/$(PKG_NAME)/postinst
#!/bin/sh
echo "munin           4949/tcp"  >> /etc/services
echo "munin   stream tcp nowait root /etc/munin/munin-node.sh" >> /etc/inetd.conf
kill -HUP `pidof inetd`
endef

# pre-remove
define Package/$(PKG_NAME)/prerm
#!/bin/sh
cd /etc
cat services | sed '/munin/ d' > services.tmp
mv services.tmp services
cat inetd.conf | sed '/munin/ d' > inetd.tmp
mv inetd.tmp inetd.conf
kill -HUP `pidof inetd`
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

munin-package: munin $(PACKAGE_DIR)/$(PKG_NAME)_$(VERSION)_$(PKGARCH).ipk
