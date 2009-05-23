# checkreset.mk 
# David Rowe Feb 2009
#
# usage: make -f checkreset.mk checkreset-package
#
# Package to check if reset is held down on boot.
#
# see doc/checkreset.txt

include rules.mk

TARGET_DIR=$(BUILD_DIR)/tmp/checkreset/ipkg/checkreset
PKG_NAME:=checkreset
PKG_VERSION:=1
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/tmp/checkreset

checkreset: 
	mkdir -p $(TARGET_DIR)/etc/init.d
	mkdir -p $(TARGET_DIR)/usr/doc
	cp doc/checkreset.txt $(TARGET_DIR)/usr/doc
	touch $(PKG_BUILD_DIR)/.built

all: checkreset

dirclean:

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=check reset
  DEPENDS:=leds
  DESCRIPTION:=\
	Check if reset help down on boot, and executes a user-defined \\\
        script, for example to set IP04 to a known IP, or restore \\\
        defaults.  Also see /usr/doc/checkreset.txt.
endef

# post installation

define Package/$(PKG_NAME)/postinst
#!/bin/sh
# hack /etc/rc - we can't use a service to do this as we want to bypass
# normal services starting, e.g. we don't want the normal network service
# to over-ride the reset-down network settings.  
#
# Grab everything before start services
cat /etc/rc | sed -n '/hostname/,/start up services/p' > /etc/rc.tmp
#
# build up rest of /etc/rc
echo >> /etc/rc.tmp
echo 'modprobe leds' >> /etc/rc.tmp
echo 'tmpcfgreset=`cat /proc/cfgreset`' >> /etc/rc.tmp
echo 'if [ $$tmpcfgreset == "0" ] ; then' >> /etc/rc.tmp
echo '   [ -f /etc/on_reset_down ] && /etc/on_reset_down' >> /etc/rc.tmp
echo 'else' >> /etc/rc.tmp
echo '  for i in /etc/rc.d/S*; do' >> /etc/rc.tmp
echo '    $$i start' >> /etc/rc.tmp
echo '  done' >> /etc/rc.tmp
echo 'fi' >> /etc/rc.tmp
echo >> /etc/rc.tmp
echo 'cat /etc/motd' >> /etc/rc.tmp
mv /etc/rc /etc/rc.bak
mv /etc/rc.tmp /etc/rc
endef

# pre-remove
define Package/$(PKG_NAME)/prerm
#!/bin/sh
cat /etc/rc | sed -n '/hostname/,/start up services/p' > /etc/rc.tmp
echo >> /etc/rc.tmp
echo 'for i in /etc/rc.d/S*; do' >> /etc/rc.tmp
echo '  $$i start' >> /etc/rc.tmp
echo 'done' >> /etc/rc.tmp
echo 'fi' >> /etc/rc.tmp
echo >> /etc/rc.tmp
echo 'cat /etc/motd' >> /etc/rc.tmp
rm /etc/rc
mv /etc/rc.tmp /etc/rc
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

checkreset-package: checkreset $(PACKAGE_DIR)/$(PKG_NAME)_$(VERSION)_$(PKGARCH).ipk
