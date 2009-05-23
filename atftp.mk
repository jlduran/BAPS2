#########################################################
# atftp  for uClinux  
# Jeff Knighton Feb 2008
#
# usage: make -f atftp.mk atftp-package 
#
#########################################################

include rules.mk

TFTPD_SITE=http://downloads.openwrt.org/sources
TFTPD_VERSION=0.7
TFTPD_SOURCE=atftp-0.7.tar.gz
TFTPD_UNZIP=zcat
TFTPD_DIR=$(BUILD_DIR)/atftp-$(TFTPD_VERSION)
TFTPD_CONFIGURE_OPTS=--host=bfin-linux-uclibc 

TARGET_DIR=$(BUILD_DIR)/tmp/atftp/ipkg/atftp
PKG_NAME:=atftp
PKG_VERSION:=$(TFTPD_VERSION)
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/tmp/atftp


$(DL_DIR)/$(TFTPD_SOURCE):
	$(WGET) -P $(DL_DIR) $(TFTPD_SITE)/$(TFTPD_SOURCE)

atftp-source: $(DL_DIR)/$(TFTPD_SOURCE)

$(TFTPD_DIR)/.unpacked: $(DL_DIR)/$(TFTPD_SOURCE)
	tar -xzvf $(DL_DIR)/$(TFTPD_SOURCE)
	touch $(TFTPD_DIR)/.unpacked

$(TFTPD_DIR)/.configured: $(TFTPD_DIR)/.unpacked
	chmod a+x $(TFTPD_DIR)/configure
	cp  -v -f $(BUILD_DIR)/patch/config.sub-atftp $(TFTPD_DIR)/config.sub
	$(PATCH_KERNEL) $(TFTPD_DIR) patch atftp.patch
	cd $(TFTPD_DIR); ./configure $(TFTPD_CONFIGURE_OPTS)
	touch $(TFTPD_DIR)/.configured

	# setup directories for package
	rm -Rf $(TARGET_DIR)
	mkdir -p $(TARGET_DIR)/bin
	mkdir -p $(TARGET_DIR)/tftpboot


atftp: $(TFTPD_DIR)/.configured
	make -C $(TFTPD_DIR)/ STAGEDIR=$(STAGING_DIR)
	#copy to the package location
	cp -f $(TFTPD_DIR)/atftpd $(TARGET_DIR)/bin/atftpd
	touch $(PKG_BUILD_DIR)/.built

all: atftp

dirclean:
	rm -rf $(TFTPD_DIR)

define Package/$(PKG_NAME)
  SECTION:=net
  CATEGORY:=Network
  TITLE:=atftp
  DESCRIPTION:=\
	tftp (trivial file transfer protocol) server	
  URL:=http://unknown/
endef

#post installation - 
define Package/$(PKG_NAME)/postinst
#!/bin/sh
cp -f /etc/inetd.conf /etc/inetd.conf.pre-atftp
echo "tftp    dgram  udp wait   root /bin/atftpd" >> /etc/inetd.conf
kill -HUP `pidof inetd`
endef

#pre-remove 
define Package/$(PKG_NAME)/prerm
#!/bin/sh
cat /etc/inetd.conf | sed '/tftp/ d' > /etc/inetd.conf.tmp
cp -f /etc/inetd.conf.tmp /etc/inetd.conf
rm /etc/inetd.conf.pre-atftp /etc/inetd.conf.tmp
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

atftp-package: atftp $(PACKAGE_DIR)/$(PKG_NAME)_$(VERSION)_$(PKGARCH).ipk


#---------------------------------------------------------------------------
#                              CREATING PATCHES     
#---------------------------------------------------------------------------

# Generate patches between vanilla tar ball and our 
# version.  Run this target after you have made any changes to
# to capture.

AO = atftp-$(TFTPD_VERSION)-orig
A = atftp-$(TFTPD_VERSION)

atftp-make-patch:

        # untar original, to save time we check if the orig is already there

	if [ ! -d $(TFTPD_DIR)-orig ] ; then \
		cd $(DL_DIR); tar xzf $(TFTPD_SOURCE); \
		mv $(A) $(TFTPD_DIR)-orig; \
	fi

        # get rid of reference to daemon 

	-cd $(BUILD_DIR); diff -uN \
	$(AO)/tftpd.c \
	$(A)/tftpd.c \
	> $(PWD)/patch/atftp.patch

	# fix CFLAGS to include __BLACKFIN__
	diff -uN \
	$(AO)/configure \
	$(A)/configure \
	>> $(PWD)/patch/atftp.patch


