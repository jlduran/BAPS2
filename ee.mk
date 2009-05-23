#  ee.mk
#  Ming Ching Tiew - April 10 2008 
#  mctiew at yahoo dot com 
#

include rules.mk

EE_VERSION=1.4.2
EE_VERSION_ORIG=$(EE_VERSION).orig
EE_NAME=ee
EE_DIR=$(BUILD_DIR)/$(EE_NAME)-$(EE_VERSION_ORIG)
EE_SOURCE=$(EE_NAME)_$(EE_VERSION_ORIG).tar.gz
EE_SITE=http://archive.ubuntu.com/ubuntu/pool/universe/e/ee/
EE_UNZIP=zcat
TARGET_DIR=$(TOPDIR)/tmp/ee/ipkg/ee
TERMCAP_FILE=files/termcap

PKG_NAME:=ee
PKG_VERSION:=$(EE_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(TOPDIR)/tmp/ee

DEFINES=-DCAP -DSYS5 -DBSD_SELECT -DNO_CATGETS -DNCURSE
CFLAGS=-DHAS_UNISTD -DHAS_STDLIB -DHAS_CTYPE -DHAS_SYS_IOCTL -DHAS_SYS_WAIT -DSLCT_HDR
STAGING_INC=$(STAGING_DIR)/usr/include
STAGING_LIB=$(STAGING_DIR)/usr/lib
EE_CFLAGS=$(CFLAGS) -O2 -D__uClinux__  -DEMBED -I$(UCLINUX_DIST) -isystem $(STAGING_INC) -fno-builtin -mfdpic # -Wall
CC=bfin-linux-uclibc-gcc
STRIP=bfin-linux-uclibc-strip

$(DL_DIR)/$(EE_SOURCE):
	mkdir -p $(DL_DIR)
	$(WGET) -P $(DL_DIR) $(EE_SITE)/$(EE_SOURCE)

$(EE_DIR)/.unpacked: $(DL_DIR)/$(EE_SOURCE)
	$(EE_UNZIP) $(DL_DIR)/$(EE_SOURCE) | \
	tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	touch $(EE_DIR)/.unpacked

$(EE_DIR)/.configured: $(EE_DIR)/.unpacked
	touch $(EE_DIR)/.configured

$(EE_DIR)/new_curse.o: $(EE_DIR)/.configured
	cd  $(EE_DIR); $(CC) new_curse.c -c $(DEFINES) $(EE_CFLAGS)
 
$(EE_DIR)/ee.o: $(EE_DIR)/.configured
	cd $(EE_DIR); $(CC) ee.c -c $(DEFINES) $(EE_CFLAGS)
 
ee-build: $(EE_DIR)/new_curse.o $(EE_DIR)/ee.o
	cd $(EE_DIR); $(CC) ee.o new_curse.o -o ee
	$(STRIP) $(EE_DIR)/ee

ee: ee-build
	-mkdir -p $(TARGET_DIR)/bin
	-mkdir -p $(TARGET_DIR)/etc
	cp $(EE_DIR)/ee $(TARGET_DIR)/bin/
	cp $(TERMCAP_FILE) $(TARGET_DIR)/etc/
	touch $(PKG_BUILD_DIR)/.built
 
all: ee

dirclean:
	rm -rf $(EE_DIR)
	rm -rf $(TARGET_DIR)


#---------------------------------------------------------------------------
#                              CREATING PACKAGE
#---------------------------------------------------------------------------

define Package/ee
  SECTION:=editor
  CATEGORY:=EDITOR
  TITLE:=EE
  DESCRIPTION:=\
        easyeditor ee, a smallish editor
  URL:=http://archive.ubuntu.com/ubuntu/pool/universe/e/ee/ee_1.4.2.orig.tar.gz
  ARCHITECTURE:=bfin-uclinux

endef

# post installation - 

define Package/ee/postinst
#!/bin/sh
true
endef

# pre-remove - 

define Package/ee/prerm
#!/bin/sh
true
endef

$(eval $(call BuildPackage,ee))

ee-package: ee $(PACKAGE_DIR)/ee_$(VERSION)_$(PKGARCH).ipk

