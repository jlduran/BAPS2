#  Adopted from asterisk.mk, and uClinux-dist/user/dropbear/Makefile 
#  Ming C (Vincent) Li - Jan 2 2008 
#  mchun.li at gmail dot com 
#
#  Thanks also to Kelvin Chua for your patch that adds scp and ssh support
# 
# Add some changes to compile dropbear 0.52 for IP04 - April 2009

include rules.mk

DROPBEAR_VERSION=0.52
DROPBEAR_NAME=dropbear
DROPBEAR_SITE=http://matt.ucc.asn.au/dropbear
DROPBEAR_SOURCE=$(DROPBEAR_NAME)-$(DROPBEAR_VERSION).tar.gz
DROPBEAR_DIR=$(BUILD_DIR)/$(DROPBEAR_NAME)-$(DROPBEAR_VERSION)
DROPBEAR_BUILD_DIR=$(DROPBEAR_DIR)/build
DROPBEAR_UNZIP=zcat

PKG_NAME:=$(DROPBEAR_NAME)
PKG_VERSION:=$(DROPBEAR_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(TOPDIR)/tmp/$(PKG_NAME)
TARGET_DIR=$(TOPDIR)/tmp/$(PKG_NAME)/ipkg/$(PKG_NAME)

STAGING_INC=$(STAGING_DIR)/usr/include
STAGING_LIB=$(STAGING_DIR)/usr/lib
DROPBEAR_CFLAGS=-I$(DROPBEAR_DIR) -I. -I$(DROPBEAR_DIR)/libtomcrypt/src/headers/ -O2 -Wall -D__uClinux__ -DEMBED \
-fno-builtin -mfdpic -I$(UCLINUX_DIST) -isystem  $(STAGING_INC) -I$(UCLINUX_DIST)/lib/zlib
DROPBEAR_LIBS=$(DROPBEAR_LTC) $(DROPBEAR_LTM) -lutil -lz -lcrypt

DROPBEAR_LDFLAGS=-mfdpic -L$(STAGING_LIB) -L$(UCLINUX_DIST)/lib/zlib -B$(STAGING_LIB)
DROPBEAR_CONFIGURE_OPTS=--host=bfin-linux-uclibc --with-zlib=$(UCLINUX_DIST)/lib/zlib CFLAGS="$(DROPBEAR_CFLAGS)"
LDFLAGS="$(DROPBEAR_LDFLAGS)"

$(DL_DIR)/$(DROPBEAR_SOURCE):
	$(WGET) -P $(DL_DIR) $(DROPBEAR_SITE)/$(DROPBEAR_SOURCE)

$(DROPBEAR_DIR)/.unpacked: $(DL_DIR)/$(DROPBEAR_SOURCE)
	$(DROPBEAR_UNZIP) $(DL_DIR)/$(DROPBEAR_SOURCE) | \
	tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	patch -f -d $(DROPBEAR_DIR) -p0 < patch/$(DROPBEAR_NAME).patch
	touch $(DROPBEAR_DIR)/.unpacked

$(DROPBEAR_BUILD_DIR): $(DROPBEAR_DIR)/.unpacked
	rm -rf $(DROPBEAR_BUILD_DIR)
	mkdir -p $(DROPBEAR_BUILD_DIR)

$(DROPBEAR_DIR)/.configured: $(DROPBEAR_BUILD_DIR)
	cd $(DROPBEAR_BUILD_DIR); \
	../configure $(DROPBEAR_CONFIGURE_OPTS)
	touch $(DROPBEAR_DIR)/.configured

dropbear: $(DROPBEAR_DIR)/.configured
	make -C  $(DROPBEAR_BUILD_DIR) -f Makefile MULTI=1 SCPPROGRESS=1
 
	rm -Rf $(TARGET_DIR)
	mkdir -p $(TARGET_DIR)/bin
	cp -v $(DROPBEAR_BUILD_DIR)/dropbearmulti $(TARGET_DIR)/bin/
	cp -v $(DROPBEAR_BUILD_DIR)/ssh $(TARGET_DIR)/bin/
	cp -v $(DROPBEAR_BUILD_DIR)/scp $(TARGET_DIR)/bin/
	cp -v $(DROPBEAR_BUILD_DIR)/dbclient $(TARGET_DIR)/bin/

	touch $(PKG_BUILD_DIR)/.built

all: dropbear

dropbear-dirclean:
	rm -rf $(DROPBEAR_DIR)
	rm -rf $(TOPDIR)/tmp/$(PKG_NAME)

#---------------------------------------------------------------------------
#                              CREATING PACKAGE
#---------------------------------------------------------------------------

define Package/dropbear
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Dropbear
  DESCRIPTION:=\
	Dropbear is a relatively small SSH 2 server and client.
  URL:=http://matt.ucc.asn.au/dropbear/dropbear.html
  ARCHITECTURE:=bfin-uclinux
endef

# post installation - add the sym link for auto start

define Package/dropbear/postinst
#!/bin/sh
ln -sf /bin/dropbearmulti /bin/dropbear
ln -sf /bin/dropbearmulti /bin/dropbearkey
rm -rf /etc/dropbear
mkdir -p /etc/dropbear
dropbearkey -t dss -f /etc/dropbear/dropbear_dss_host_key -s 1024
dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key -s 1024
touch /var/log/lastlog
touch /var/log/wtmp
cp /etc/inetd.conf /etc/inetd.conf.orig
echo "ssh     stream tcp nowait root /bin/dropbear -i 2 > /dev/null" >> /etc/inetd.conf
kill -HUP `pidof inetd`
endef

# pre-remove - remove sym link

define Package/dropbear/prerm
#!/bin/sh
rm -rf /etc/dropbear
rm -rf /bin/dropbear
rm -rf /bin/dropbearkey
rm -rf /bin/dropbearmulti
rm -f /var/log/lastlog
rm -f /var/log/wtmp
cat /etc/inetd.conf | sed '/dropbear/ d' > /etc/inetd.conf.tmp
cp /etc/inetd.conf.tmp /etc/inetd.conf
rm -f /etc/inetd.conf.tmp
kill -HUP `pidof inetd`
endef

$(eval $(call BuildPackage,dropbear))

dropbear-package: dropbear $(PACKAGE_DIR)/dropbear_$(VERSION)_$(PKGARCH).ipk

