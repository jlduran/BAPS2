#  Adopted from asterisk.mk, and uClinux-dist/user/dropbear/Makefile 
#  Ming C (Vincent) Li - Jan 2 2008 
#  mchun.li at gmail dot com 
#
#  Thanks also to Kelvin Chua for your patch that adds scp and ssh support

include rules.mk

DROPBEAR_VERSION=0.48.1
DROPBEAR_NAME=dropbear
DROPBEAR_DIR=$(UCLINUX_DIST)/user/$(DROPBEAR_NAME)
DROPBEAR_SRC_DIR=$(UCLINUX_DIST)/user/$(DROPBEAR_NAME)
DROPBEAR_BUILD_DIR=$(DROPBEAR_DIR)/build
TARGET_DIR=$(TOPDIR)/tmp/dropbear/ipkg/dropbear

PKG_NAME:=dropbear
PKG_VERSION:=$(DROPBEAR_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(TOPDIR)/tmp/dropbear

STAGING_INC=$(STAGING_DIR)/usr/include
STAGING_LIB=$(STAGING_DIR)/usr/lib
DROPBEAR_CFLAGS=-I$(DROPBEAR_SRC_DIR) -I. -I$(DROPBEAR_SRC_DIR)/libtomcrypt/src/headers/ -O2 -Wall -D__uClinux__ -DEMBED \
-fno-builtin -mfdpic -I$(UCLINUX_DIST) -isystem  $(STAGING_INC) -I$(UCLINUX_DIST)/lib/zlib
DROPBEAR_LIBS=$(DROPBEAR_LTC) $(DROPBEAR_LTM) -lutil -lz -lcrypt

DROPBEAR_LDFLAGS=-mfdpic -L$(STAGING_LIB) -L$(UCLINUX_DIST)/lib/zlib -B$(STAGING_LIB)
DROPBEAR_CONFIGURE_OPTS=--host=bfin-linux-uclibc --with-zlib=$(UCLINUX_DIST)/lib/zlib CFLAGS="$(DROPBEAR_CFLAGS)"
LDFLAGS="$(DROPBEAR_LDFLAGS)"

$(DROPBEAR_BUILD_DIR):
	rm -rf $(DROPBEAR_BUILD_DIR)
	mkdir -p $(DROPBEAR_BUILD_DIR)

$(DROPBEAR_BUILD_DIR)/Makefile: $(DROPBEAR_BUILD_DIR)
	cd $(DROPBEAR_BUILD_DIR); \
	../configure $(DROPBEAR_CONFIGURE_OPTS)

	# note that this will fail the 2nd time around (ie if make is run again)
	# this is OK as the files are already patched
	-patch -f -d $(UCLINUX_DIST) -p0 < patch/dropbear.patch

	set -e ;\
	list=`cd $(DROPBEAR_DIR)/libtomcrypt ; find . -mindepth 1 -type d` ; \
	cd  $(DROPBEAR_BUILD_DIR)/libtomcrypt ; \
	mkdir $$list

dropbear: $(DROPBEAR_BUILD_DIR)/Makefile
	make -C  $(DROPBEAR_BUILD_DIR) -f Makefile MULTI=1
 
	rm -Rf $(TARGET_DIR)
	mkdir -p $(TARGET_DIR)
	mkdir -p $(TARGET_DIR)/bin
	cp -v $(DROPBEAR_BUILD_DIR)/dropbearmulti $(TARGET_DIR)/bin/
	cp -v $(DROPBEAR_BUILD_DIR)/ssh $(TARGET_DIR)/bin/
	cp -v $(DROPBEAR_BUILD_DIR)/scp $(TARGET_DIR)/bin/
	cp -v $(DROPBEAR_BUILD_DIR)/dbclient $(TARGET_DIR)/bin/
	mkdir -p $(TARGET_DIR)/usr/doc
	cp -v doc/dropbear.txt $(TARGET_DIR)/usr/doc

	touch $(PKG_BUILD_DIR)/.built

all: dropbear

dirclean:
	rm -rf $(DROPBEAR_BUILD_DIR)


#---------------------------------------------------------------------------
#                              CREATING PACKAGE
#---------------------------------------------------------------------------

define Package/dropbear
  SECTION:=net
  CATEGORY:=Network
  TITLE:=DROPBEAR
  DESCRIPTION:=\
        Dropbear, a smallish SSH 2 server and client \\\
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
dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key
cp /etc/inetd.conf /etc/inetd.conf.orig
echo "ssh     stream tcp nowait root /bin/dropbear -i 2 > /dev/null" >> /etc/inetd.conf
kill -HUP `pidof inetd`
endef

# pre-remove - remove sym link

define Package/dropbear/prerm
#!/bin/sh
rm -rf /bin/dropbear
rm -rf /bin/dropbearkey
rm -rf /bin/dropbearmulti
cat /etc/inetd.conf | sed '/dropbear/ d' > /etc/inetd.conf.tmp
cp /etc/inetd.conf.tmp /etc/inetd.conf
rm -f /etc/inetd.conf.tmp
kill -HUP `pidof inetd`
endef

$(eval $(call BuildPackage,dropbear))

dropbear-package: dropbear $(PACKAGE_DIR)/dropbear_$(VERSION)_$(PKGARCH).ipk

