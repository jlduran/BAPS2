#########################################################
# netcat for uClinux
# Darryl Ross Mar 2009
#
# usage: make -f netcat.mk netcat-package 
#
#########################################################

include rules.mk

NETCAT_SITE=http://internode.dl.sourceforge.net/sourceforge/netcat/
NETCAT_VERSION=0.7.1
NETCAT_SOURCE=netcat-0.7.1.tar.gz
NETCAT_DIR=$(BUILD_DIR)/netcat-$(NETCAT_VERSION)
NETCAT_CONFIGURE_OPTS=--host=bfin-linux-uclibc 

TARGET_DIR=$(BUILD_DIR)/tmp/netcat/ipkg/netcat
PKG_NAME:=netcat
PKG_VERSION:=$(NETCAT_VERSION)
PKG_RELEASE:=2
PKG_BUILD_DIR:=$(BUILD_DIR)/tmp/netcat

$(DL_DIR)/$(NETCAT_SOURCE):
	$(WGET) -P $(DL_DIR) $(NETCAT_SITE)/$(NETCAT_SOURCE)

netcat-source: $(DL_DIR)/$(NETCAT_SOURCE)

$(NETCAT_DIR)/.unpacked: $(DL_DIR)/$(NETCAT_SOURCE)
	tar -xzvf $(DL_DIR)/$(NETCAT_SOURCE)
	touch $(NETCAT_DIR)/.unpacked

$(NETCAT_DIR)/.configured: $(NETCAT_DIR)/.unpacked
	cd $(NETCAT_DIR); patch -p2 < $(BUILD_DIR)/patch/config.sub-netcat.patch
	cd $(NETCAT_DIR); ./configure $(NETCAT_CONFIGURE_OPTS)
	rm -Rf $(TARGET_DIR)
	mkdir -p $(TARGET_DIR)/bin
	mkdir -p $(TARGET_DIR)/usr/bin
	touch $(NETCAT_DIR)/.configured

netcat: $(NETCAT_DIR)/.configured
	make -C $(NETCAT_DIR)/ STAGEDIR=$(STAGING_DIR)
	cp -f $(NETCAT_DIR)/src/netcat $(TARGET_DIR)/bin/
	ln -sf /bin/netcat $(TARGET_DIR)/usr/bin/netcat
	ln -sf /bin/netcat $(TARGET_DIR)/bin/nc
	ln -sf /bin/netcat $(TARGET_DIR)/usr/bin/nc
	touch $(PKG_BUILD_DIR)/.built

all: netcat

dirclean:
	echo rm -rf $(NETCAT_DIR)


define Package/$(PKG_NAME)
  SECTION:=net
  CATEGORY:=Network
  TITLE:=netcat
  DESCRIPTION:=\
	NetCat client
  URL:=http://netcat.sourceforge.net/
endef

#post installation - do nothing
define Package/$(PKG_NAME)/postinst
endef

#pre-remove
define Package/$(PKG_NAME)/prerm
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

netcat-package: netcat $(PACKAGE_DIR)/$(PKG_NAME)_$(VERSION)_$(PKGARCH).ipk

