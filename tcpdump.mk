#########################################################
# tcpdump for uClinux and Asterisk, 
# Ming C. Li April 2008
#
# usage: make -f tcpdump.mk tcpdump-package 
#
# Run after "make -f libpcap.mk libpcap"
#########################################################

include rules.mk

TCPDUMP_SITE=http://www.tcpdump.org/release
TCPDUMP_VERSION=3.9.8
TCPDUMP_SOURCE=tcpdump-3.9.8.tar.gz
TCPDUMP_UNZIP=zcat
TCPDUMP_DIR=$(BUILD_DIR)/tcpdump-$(TCPDUMP_VERSION)
		   
TARGET_DIR=$(BUILD_DIR)/tmp/tcpdump/ipkg/tcpdump
PKG_NAME:=tcpdump
PKG_VERSION:=$(TCPDUMP_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/tmp/tcpdump

STAGING_INC=$(STAGING_DIR)/usr/include
STAGING_LIB=$(STAGING_DIR)/usr/lib


TCPDUMP_CONFIGURE_OPTS=--host=bfin-linux-uclibc \
		       --prefix=$(TARGET_DIR) 

$(DL_DIR)/$(TCPDUMP_SOURCE):
	$(WGET) -P $(DL_DIR) $(TCPDUMP_SITE)/$(TCPDUMP_SOURCE)

tcpdump-source: $(DL_DIR)/$(TCPDUMP_SOURCE)

$(TCPDUMP_DIR)/.unpacked: $(DL_DIR)/$(TCPDUMP_SOURCE)
	$(TCPDUMP_UNZIP) $(DL_DIR)/$(TCPDUMP_SOURCE) | \
        tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	$(PATCH_KERNEL) $(TCPDUMP_DIR) patch tcpdump.patch

	touch $(TCPDUMP_DIR)/.unpacked

$(TCPDUMP_DIR)/.configured: $(TCPDUMP_DIR)/.unpacked
	cd $(TCPDUMP_DIR); CPPFLAGS=-I$(UCLINUX_DIST)/staging/usr/include ./configure $(TCPDUMP_CONFIGURE_OPTS); sed -e 's; -I/usr/include ; ;' -i Makefile
	touch $(TCPDUMP_DIR)/.configured

tcpdump: $(TCPDUMP_DIR)/.configured
	make -C $(TCPDUMP_DIR) 

	rm -Rf $(TARGET_DIR)
	mkdir -p $(TARGET_DIR)
	mkdir -p $(TARGET_DIR)/bin
	cp -v $(TCPDUMP_DIR)/tcpdump $(TARGET_DIR)/bin/

	touch $(PKG_BUILD_DIR)/.built



all: tcpdump

dirclean:
	rm -rf $(TCPDUMP_DIR)


#---------------------------------------------------------------------------
#                              CREATING PACKAGE
#---------------------------------------------------------------------------

define Package/tcpdump
  SECTION:=network
  CATEGORY:=Applications
  TITLE:=TCPDUMP
  DESCRIPTION:=\
        TCPDUMP is a common computer network debugging tool to capture TCP/IP packets 
  URL:=http://www.tcpdump.org/
  ARCHITECTURE:=bfin-uclinux

endef

# post installation - add the sym link for auto start

define Package/tcpdump/postinst
#!/bin/sh
endef

# pre-remove - remove sym link

define Package/tcpdump/prerm
#!/bin/sh
rm -rf /bin/tcpdump
endef

$(eval $(call BuildPackage,tcpdump))

tcpdump-package: tcpdump $(PACKAGE_DIR)/tcpdump_$(VERSION)_$(PKGARCH).ipk

